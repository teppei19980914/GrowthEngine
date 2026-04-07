/// データ件数ストレステスト.
///
/// 大量データ投入時のDB操作・計算ロジック・統計算出の
/// 所要時間を計測し、閾値を超えた場合にテスト失敗とする.
///
/// 実行方法:
///   flutter test test/stress/data_volume_stress_test.dart
// ignore_for_file: invalid_use_of_visible_for_testing_member
library;

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yume_hashi/database/app_database.dart' hide Book, StudyLog;
import 'package:yume_hashi/models/book.dart';
import 'package:yume_hashi/models/goal.dart' show WhenType;
import 'package:yume_hashi/models/study_log.dart';
import 'package:yume_hashi/services/book_service.dart';
import 'package:yume_hashi/services/data_export_service.dart';
import 'package:yume_hashi/services/dream_service.dart';
import 'package:yume_hashi/services/goal_service.dart';
import 'package:yume_hashi/services/motivation_calculator.dart';
import 'package:yume_hashi/services/notification_service.dart';
import 'package:yume_hashi/services/study_log_service.dart';
import 'package:yume_hashi/services/study_stats_calculator.dart';
import 'package:yume_hashi/services/study_stats_types.dart';
import 'package:yume_hashi/services/task_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── テストデータ件数 ──────────────────────────────
// 実際のヘビーユーザーを想定した件数
const _dreamCount = 10;
const _goalsPerDream = 10; // 合計100目標
const _tasksPerGoal = 10; // 合計1,000タスク
const _studyLogCount = 10000; // 1万件の活動ログ
const _bookCount = 100;
const _notificationCount = 500;

// ── 許容時間（ミリ秒） ──────────────────────────────
// インメモリSQLiteでの閾値。実環境（WebWASM）ではこの3〜5倍を見込む
const _thresholdBulkInsertMs = 30000; // 大量INSERT
const _thresholdExportMs = 5000; // エクスポート
const _thresholdImportMs = 30000; // インポート
const _thresholdClearAllMs = 15000; // 全削除
const _thresholdStatsCalcMs = 2000; // 統計計算
const _thresholdNotificationMs = 5000; // 通知チェック
const _thresholdQueryMs = 2000; // 大量データクエリ

AppDatabase _createDb() => AppDatabase(NativeDatabase.memory());

/// 計測結果を収集するリスト.
final _results = <Map<String, dynamic>>[];

/// 計測結果を記録する.
void _record(String label, int ms, int threshold) {
  _results.add({
    'label': label,
    'ms': ms,
    'threshold_ms': threshold,
    'passed': ms <= threshold,
  });
}

/// Stopwatch で計測し、結果を出力・記録するヘルパー.
Duration measure(String label, void Function() action,
    {int threshold = _thresholdStatsCalcMs}) {
  final sw = Stopwatch()..start();
  action();
  sw.stop();
  // ignore: avoid_print
  print('  [$label] ${sw.elapsedMilliseconds}ms');
  _record(label, sw.elapsedMilliseconds, threshold);
  return sw.elapsed;
}

/// 非同期版.
Future<Duration> measureAsync(
    String label, Future<void> Function() action,
    {int threshold = _thresholdBulkInsertMs}) async {
  final sw = Stopwatch()..start();
  await action();
  sw.stop();
  // ignore: avoid_print
  print('  [$label] ${sw.elapsedMilliseconds}ms');
  _record(label, sw.elapsedMilliseconds, threshold);
  return sw.elapsed;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDownAll(() {
    // 全テスト完了後にJSON結果を出力
    final failedCount = _results.where((r) => r['passed'] == false).length;
    final report = {
      'timestamp': DateTime.now().toIso8601String(),
      'threshold_ms': _thresholdStatsCalcMs,
      'total_measurements': _results.length,
      'passed_count': _results.where((r) => r['passed'] == true).length,
      'failed_count': failedCount,
      'all_passed': failedCount == 0,
      'measurements': _results,
      'bottlenecks': _results
          .where((r) => r['passed'] == false)
          .map((r) => '${r['label']}: ${r['ms']}ms (threshold: ${r['threshold_ms']}ms)')
          .toList(),
    };

    final dir = Directory('test_stress/results');
    if (!dir.existsSync()) dir.createSync(recursive: true);

    final json = const JsonEncoder.withIndent('  ').convert(report);
    File('test_stress/results/latest.json').writeAsStringSync(json);

    final dateStr = DateTime.now().toIso8601String().substring(0, 10);
    File('test_stress/results/$dateStr.json').writeAsStringSync(json);

    // ignore: avoid_print
    print('\n=== Result: ${report['all_passed'] == true ? 'ALL PASSED' : 'FAILED'} ===');
    // ignore: avoid_print
    print('Output: test_stress/results/latest.json');
  });

  late AppDatabase db;
  late DreamService dreamService;
  late GoalService goalService;
  late TaskService taskService;
  late BookService bookService;
  late StudyLogService studyLogService;
  late NotificationService notificationService;
  late DataExportService exportService;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = _createDb();
    dreamService = DreamService(
      dreamDao: db.dreamDao,
      goalDao: db.goalDao,
      taskDao: db.taskDao,
    );
    goalService = GoalService(goalDao: db.goalDao, taskDao: db.taskDao);
    taskService = TaskService(taskDao: db.taskDao);
    bookService = BookService(bookDao: db.bookDao, taskDao: db.taskDao);
    studyLogService = StudyLogService(studyLogDao: db.studyLogDao);
    notificationService =
        NotificationService(notificationDao: db.notificationDao);
    exportService = DataExportService(
      dreamDao: db.dreamDao,
      goalDao: db.goalDao,
      taskDao: db.taskDao,
      bookDao: db.bookDao,
      studyLogDao: db.studyLogDao,
      notificationDao: db.notificationDao,
    );
  });

  tearDown(() => db.close());

  // ══════════════════════════════════════════════════════════
  // 1. 大量データINSERT
  // ══════════════════════════════════════════════════════════
  group('大量データINSERT', () {
    test('夢$_dreamCount件 → 目標${_dreamCount * _goalsPerDream}件 → '
        'タスク${_dreamCount * _goalsPerDream * _tasksPerGoal}件を投入',
        () async {
      // ignore: avoid_print
      print('\n=== 大量データINSERT ===');

      // 夢
      final dreamIds = <String>[];
      final d1 = await measureAsync('夢 $_dreamCount件', () async {
        for (var i = 0; i < _dreamCount; i++) {
          final dream = await dreamService.createDream(
            title: 'ストレステスト夢 $i',
            category: 'career',
          );
          dreamIds.add(dream.id);
        }
      });
      expect(d1.inMilliseconds, lessThan(_thresholdBulkInsertMs));

      // 目標
      final goalIds = <String>[];
      final totalGoals = _dreamCount * _goalsPerDream;
      final d2 = await measureAsync('目標 $totalGoals件', () async {
        for (var di = 0; di < dreamIds.length; di++) {
          for (var gi = 0; gi < _goalsPerDream; gi++) {
            final goal = await goalService.createGoal(
              dreamId: dreamIds[di],
              what: 'ストレステスト目標 $di-$gi',
              how: 'テスト方法',
              whenTarget: '2027-12-31',
              whenType: WhenType.date,
            );
            goalIds.add(goal.id);
          }
        }
      });
      expect(d2.inMilliseconds, lessThan(_thresholdBulkInsertMs));

      // タスク
      final taskIds = <String>[];
      final totalTasks = totalGoals * _tasksPerGoal;
      final d3 = await measureAsync('タスク $totalTasks件', () async {
        final baseDate = DateTime(2026, 1, 1);
        for (var gi = 0; gi < goalIds.length; gi++) {
          for (var ti = 0; ti < _tasksPerGoal; ti++) {
            final task = await taskService.createTask(
              goalId: goalIds[gi],
              title: 'ストレステストタスク $gi-$ti',
              startDate: baseDate.add(Duration(days: ti * 7)),
              endDate: baseDate.add(Duration(days: ti * 7 + 6)),
            );
            taskIds.add(task.id);
          }
        }
      });
      expect(d3.inMilliseconds, lessThan(_thresholdBulkInsertMs));

      // 検証: 件数が正しいか
      final allDreams = await dreamService.getAllDreams();
      final allGoals = await goalService.getAllGoals();
      final allTasks = await taskService.getAllTasks();
      expect(allDreams.length, _dreamCount);
      expect(allGoals.length, totalGoals);
      expect(allTasks.length, totalTasks);
    });

    test('活動ログ $_studyLogCount件を投入', () async {
      // ignore: avoid_print
      print('\n=== 活動ログINSERT ===');

      // 前提: タスクを1つ作成
      final dream = await dreamService.createDream(title: 'ログ用夢');
      final goal = await goalService.createGoal(
        dreamId: dream.id,
        what: 'ログ用目標',
        how: 'テスト',
        whenTarget: '2027-12-31',
        whenType: WhenType.date,
      );
      final task = await taskService.createTask(
        goalId: goal.id,
        title: 'ログ用タスク',
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2027, 12, 31),
      );

      final d = await measureAsync('活動ログ $_studyLogCount件', () async {
        final baseDate = DateTime(2025, 1, 1);
        for (var i = 0; i < _studyLogCount; i++) {
          await studyLogService.addStudyLog(
            taskId: task.id,
            studyDate: baseDate.add(Duration(days: i ~/ 3)),
            durationMinutes: 30 + (i % 120),
            taskName: 'ログ用タスク',
          );
        }
      });
      expect(d.inMilliseconds, lessThan(_thresholdBulkInsertMs));

      final allLogs = await studyLogService.getAllLogs();
      expect(allLogs.length, _studyLogCount);
    });

    test('書籍 $_bookCount件を投入', () async {
      // ignore: avoid_print
      print('\n=== 書籍INSERT ===');

      final d = await measureAsync('書籍 $_bookCount件', () async {
        for (var i = 0; i < _bookCount; i++) {
          await bookService.createBook(
            '書籍 $i',
            category: BookCategory.values[i % BookCategory.values.length],
            why: 'テスト理由 $i',
            description: 'テスト説明 $i',
          );
        }
      });
      expect(d.inMilliseconds, lessThan(_thresholdBulkInsertMs));

      final allBooks = await bookService.getAllBooks();
      expect(allBooks.length, _bookCount);
    });

    test('通知 $_notificationCount件を投入', () async {
      // ignore: avoid_print
      print('\n=== 通知INSERT ===');

      final d = await measureAsync('通知 $_notificationCount件', () async {
        for (var i = 0; i < _notificationCount; i++) {
          await db.notificationDao.insertNotification(
            NotificationsCompanion(
              id: Value('notif-$i'),
              notificationType: Value(i % 3 == 0
                  ? 'system'
                  : i % 3 == 1
                      ? 'reminder'
                      : 'achievement'),
              title: Value('通知 $i'),
              message: Value('テストメッセージ $i'),
              isRead: Value(i % 2 == 0),
              createdAt: Value(DateTime.now().subtract(Duration(hours: i))),
              dedupKey: Value('stress:$i'),
            ),
          );
        }
      });
      expect(d.inMilliseconds, lessThan(_thresholdBulkInsertMs));
    });
  });

  // ══════════════════════════════════════════════════════════
  // 2. 大量データでの統計計算
  // ══════════════════════════════════════════════════════════
  group('大量データでの統計計算', () {
    late List<StudyLog> logs;

    setUp(() {
      // 1万件の活動ログをメモリ上で生成（DB不要）
      final baseDate = DateTime(2024, 1, 1);
      logs = List.generate(_studyLogCount, (i) {
        return StudyLog(
          id: 'log-$i',
          taskId: 'task-${i % 100}',
          studyDate: baseDate.add(Duration(days: i ~/ 3)),
          durationMinutes: 30 + (i % 120),
          taskName: 'タスク ${i % 100}',
        );
      });
    });

    test('ストリーク計算（$_studyLogCount件）', () {
      // ignore: avoid_print
      print('\n=== 統計計算 ===');

      final d = measure('ストリーク計算', () {
        MotivationCalculator.calculateStreak(
          logs,
          today: DateTime(2033, 3, 1),
        );
      });
      expect(d.inMilliseconds, lessThan(_thresholdStatsCalcMs));
    });

    test('自己ベスト計算（$_studyLogCount件）', () {
      final d = measure('自己ベスト計算', () {
        MotivationCalculator.calculatePersonalRecords(logs);
      });
      expect(d.inMilliseconds, lessThan(_thresholdStatsCalcMs));
    });

    test('日別アクティビティ計算（$_studyLogCount件）', () {
      final d = measure('日別アクティビティ', () {
        StudyStatsCalculator.calculateDailyActivity(logs);
      });
      expect(d.inMilliseconds, lessThan(_thresholdStatsCalcMs));
    });

    test('月別アクティビティ計算（$_studyLogCount件）', () {
      final d = measure('月別アクティビティ', () {
        StudyStatsCalculator.calculateActivity(
          logs,
          ActivityPeriodType.monthly,
        );
      });
      expect(d.inMilliseconds, lessThan(_thresholdStatsCalcMs));
    });

    test('年別アクティビティ計算（$_studyLogCount件）', () {
      final d = measure('年別アクティビティ', () {
        StudyStatsCalculator.calculateActivity(
          logs,
          ActivityPeriodType.yearly,
        );
      });
      expect(d.inMilliseconds, lessThan(_thresholdStatsCalcMs));
    });

    test('実績通知判定（$_studyLogCount件）', () {
      final d = measure('実績判定', () {
        MotivationCalculator.calculateMilestones(logs);
      });
      expect(d.inMilliseconds, lessThan(_thresholdStatsCalcMs));
    });
  });

  // ══════════════════════════════════════════════════════════
  // 3. エクスポート / インポート
  // ══════════════════════════════════════════════════════════
  group('エクスポート / インポート', () {
    test('大量データのエクスポート → インポート往復', () async {
      // ignore: avoid_print
      print('\n=== エクスポート/インポート ===');

      // データ投入
      final dream = await dreamService.createDream(title: 'エクスポート用夢');
      final goal = await goalService.createGoal(
        dreamId: dream.id,
        what: 'エクスポート用目標',
        how: 'テスト',
        whenTarget: '2027-12-31',
        whenType: WhenType.date,
      );
      final task = await taskService.createTask(
        goalId: goal.id,
        title: 'エクスポート用タスク',
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2027, 12, 31),
      );
      for (var i = 0; i < 1000; i++) {
        await studyLogService.addStudyLog(
          taskId: task.id,
          studyDate: DateTime(2025, 1, 1).add(Duration(days: i ~/ 3)),
          durationMinutes: 60,
          taskName: 'エクスポート用タスク',
        );
      }
      for (var i = 0; i < 50; i++) {
        await bookService.createBook('エクスポート用書籍 $i');
      }

      // エクスポート
      late String json;
      final d1 = await measureAsync('エクスポート（1000ログ+50書籍）', () async {
        json = await exportService.exportData();
      });
      expect(d1.inMilliseconds, lessThan(_thresholdExportMs));
      // ignore: avoid_print
      print('    JSON size: ${(json.length / 1024).toStringAsFixed(1)} KB');

      // インポート（既存データをクリアして再投入）
      final d2 = await measureAsync('インポート（同データ）', () async {
        await exportService.importData(json);
      });
      expect(d2.inMilliseconds, lessThan(_thresholdImportMs));

      // 検証
      final logs = await studyLogService.getAllLogs();
      expect(logs.length, 1000);
      final books = await bookService.getAllBooks();
      expect(books.length, 50);
    });

    test('全削除（大量データ）', () async {
      // ignore: avoid_print
      print('\n=== 全削除 ===');

      // データ投入
      for (var i = 0; i < 500; i++) {
        await db.studyLogDao.insertStudyLog(StudyLogsCompanion(
          id: Value('del-log-$i'),
          taskId: const Value('task-1'),
          studyDate: Value(DateTime(2025, 1, 1).add(Duration(days: i))),
          durationMinutes: Value(60),
          createdAt: Value(DateTime.now()),
        ));
      }
      for (var i = 0; i < 200; i++) {
        await db.notificationDao.insertNotification(NotificationsCompanion(
          id: Value('del-notif-$i'),
          notificationType: const Value('system'),
          title: Value('通知 $i'),
          message: Value('メッセージ $i'),
          isRead: const Value(false),
          createdAt: Value(DateTime.now()),
          dedupKey: Value('del:$i'),
        ));
      }

      final d = await measureAsync('全削除（500ログ+200通知）', () async {
        await exportService.clearAllData();
      });
      expect(d.inMilliseconds, lessThan(_thresholdClearAllMs));

      // 検証
      final logs = await db.studyLogDao.getAll();
      expect(logs, isEmpty);
    });
  });

  // ══════════════════════════════════════════════════════════
  // 4. 大量データでのクエリ性能
  // ══════════════════════════════════════════════════════════
  group('大量データでのクエリ性能', () {
    test('通知の重複チェック（$_notificationCount件）', () async {
      // ignore: avoid_print
      print('\n=== クエリ性能 ===');

      for (var i = 0; i < _notificationCount; i++) {
        await db.notificationDao.insertNotification(NotificationsCompanion(
          id: Value('q-notif-$i'),
          notificationType: const Value('reminder'),
          title: Value('通知 $i'),
          message: Value('メッセージ $i'),
          isRead: const Value(false),
          createdAt: Value(DateTime.now()),
          dedupKey: Value('q:$i'),
        ));
      }

      final d = await measureAsync(
          'existsByDedupKey × $_notificationCount回', () async {
        for (var i = 0; i < _notificationCount; i++) {
          await db.notificationDao.existsByDedupKey('q:$i');
        }
      });
      expect(d.inMilliseconds, lessThan(_thresholdQueryMs));
    });

    test('リマインダーチェック（500タスク分の期限）', () async {
      // 通知DBをセットアップ（既存リマインダーなし）
      final deadlines =
          <({String id, String title, DateTime deadline, bool isGoal})>[];
      for (var i = 0; i < 500; i++) {
        deadlines.add((
          id: 'task-$i',
          title: 'タスク $i',
          deadline: DateTime.now().add(Duration(days: i % 14 - 7)),
          isGoal: false,
        ));
      }

      final d = await measureAsync('リマインダーチェック（500件）', () async {
        await notificationService.checkAndCreateReminders(
            deadlines: deadlines);
      });
      expect(d.inMilliseconds, lessThan(_thresholdNotificationMs));
    });

    test('未読通知数カウント（$_notificationCount件中）', () async {
      for (var i = 0; i < _notificationCount; i++) {
        await db.notificationDao.insertNotification(NotificationsCompanion(
          id: Value('cnt-$i'),
          notificationType: const Value('reminder'),
          title: Value('通知 $i'),
          message: Value('メッセージ $i'),
          isRead: Value(i % 2 == 0),
          createdAt: Value(DateTime.now()),
          dedupKey: Value('cnt:$i'),
        ));
      }

      final d = await measureAsync(
          '未読カウント（$_notificationCount件中）', () async {
        final count = await db.notificationDao.getUnreadCount();
        expect(count, _notificationCount ~/ 2);
      });
      expect(d.inMilliseconds, lessThan(500));
    });

    test('活動ログの合計時間（SQL SUM、$_studyLogCount件）', () async {
      for (var i = 0; i < _studyLogCount; i++) {
        await db.studyLogDao.insertStudyLog(StudyLogsCompanion(
          id: Value('sum-$i'),
          taskId: const Value('task-1'),
          studyDate: Value(DateTime(2025, 1, 1).add(Duration(days: i ~/ 3))),
          durationMinutes: Value(60),
          createdAt: Value(DateTime.now()),
        ));
      }

      final d =
          await measureAsync('SQL SUM（$_studyLogCount件）', () async {
        final total = await db.studyLogDao.getTotalMinutes();
        expect(total, _studyLogCount * 60);
      });
      expect(d.inMilliseconds, lessThan(500));
    });
  });
}
