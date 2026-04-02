/// 同時アクセスストレステスト.
///
/// 複数ユーザーが同時にアプリを操作した場合の
/// 外部API・DB・同期処理の耐性を計測する.
///
/// このアプリはクライアントサイド完結型（ブラウザ内SQLite）のため、
/// 「同時アクセス」の影響は以下に限定される:
///   1. 外部API（Stripe / Remote Config / Feedback）への同時リクエスト
///   2. Firestore 同期の競合
///   3. DB への同時読み書き（同一ブラウザタブ内）
///
/// 実行方法:
///   flutter test test_stress/concurrent_access_stress_test.dart
// ignore_for_file: invalid_use_of_visible_for_testing_member
library;

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yume_log/database/app_database.dart' hide Book, StudyLog;
import 'package:yume_log/models/goal.dart' show WhenType;
import 'package:yume_log/services/data_export_service.dart';
import 'package:yume_log/services/dream_service.dart';
import 'package:yume_log/services/firestore_sync_service.dart'
    show CloudSyncClient;
import 'package:yume_log/services/goal_service.dart';
import 'package:yume_log/services/stripe_service.dart';
import 'package:yume_log/services/study_log_service.dart';
import 'package:yume_log/services/sync_manager.dart';
import 'package:yume_log/services/task_service.dart';

// ── テストパラメータ ──────────────────────────────
const _concurrentUsers = 50; // 同時アクセスユーザー数
const _concurrentDbOps = 100; // 同時DB操作数
const _apiLatencyMs = 200; // シミュレートするAPI遅延
const _apiTimeoutMs = 15000; // API タイムアウト

// ── 許容時間（ミリ秒） ──────────────────────────────
const _thresholdApiConcurrentMs = 5000; // 同時APIリクエスト
const _thresholdDbConcurrentMs = 3000; // 同時DB操作
const _thresholdSyncMs = 5000; // 同期処理

/// 計測結果を収集するリスト.
final _results = <Map<String, dynamic>>[];

void _record(String label, int ms, int threshold) {
  _results.add({
    'label': label,
    'ms': ms,
    'threshold_ms': threshold,
    'passed': ms <= threshold,
  });
}

AppDatabase _createDb() => AppDatabase(NativeDatabase.memory());

/// 遅延付きモックHTTPクライアントを生成.
/// [latencyMs] 分の遅延後にレスポンスを返す.
/// [concurrentCount] で同時リクエスト数をカウントする.
MockClient _createLatencyClient({
  required int latencyMs,
  required Map<String, dynamic> response,
}) {
  var currentConcurrent = 0;
  var peakConcurrent = 0;

  return MockClient((request) async {
    currentConcurrent++;
    if (currentConcurrent > peakConcurrent) {
      peakConcurrent = currentConcurrent;
    }

    // 同時接続数に応じて遅延を増加（実際のサーバー挙動をシミュレート）
    final adjustedLatency = latencyMs + (currentConcurrent * 10);
    await Future<void>.delayed(Duration(milliseconds: adjustedLatency));

    currentConcurrent--;
    return http.Response(
      jsonEncode({...response, 'peak_concurrent': peakConcurrent}),
      200,
    );
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDownAll(() {
    final failedCount = _results.where((r) => r['passed'] == false).length;
    final report = {
      'timestamp': DateTime.now().toIso8601String(),
      'test_type': 'concurrent_access',
      'total_measurements': _results.length,
      'passed_count': _results.where((r) => r['passed'] == true).length,
      'failed_count': failedCount,
      'all_passed': failedCount == 0,
      'measurements': _results,
      'bottlenecks': _results
          .where((r) => r['passed'] == false)
          .map((r) =>
              '${r['label']}: ${r['ms']}ms (threshold: ${r['threshold_ms']}ms)')
          .toList(),
    };

    final dir = Directory('test_stress/results');
    if (!dir.existsSync()) dir.createSync(recursive: true);

    final json = const JsonEncoder.withIndent('  ').convert(report);
    File('test_stress/results/latest_concurrent.json')
        .writeAsStringSync(json);

    // ignore: avoid_print
    print(
        '\n=== Concurrent: ${report['all_passed'] == true ? 'ALL PASSED' : 'FAILED'} ===');
    // ignore: avoid_print
    print('Output: test_stress/results/latest_concurrent.json');
  });

  // ══════════════════════════════════════════════════════════
  // 1. 外部APIへの同時リクエスト
  // ══════════════════════════════════════════════════════════
  group('外部APIへの同時リクエスト', () {
    test('Stripe verifySubscription × $_concurrentUsers 同時', () async {
      // ignore: avoid_print
      print('\n=== 外部API同時リクエスト ===');

      final mockClient = _createLatencyClient(
        latencyMs: _apiLatencyMs,
        response: {'active': true},
      );

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      // 単体リクエストのベースライン計測
      final baseSw = Stopwatch()..start();
      final service = StripeService(prefs, httpClient: mockClient);
      await service.verifySubscription(userKey: 'baseline');
      baseSw.stop();
      final baselineMs = baseSw.elapsedMilliseconds;
      // ignore: avoid_print
      print('  [ベースライン（単体）] ${baselineMs}ms');

      // 同時リクエスト
      final sw = Stopwatch()..start();
      final futures = List.generate(_concurrentUsers, (i) {
        final svc = StripeService(prefs, httpClient: mockClient);
        return svc.verifySubscription(userKey: 'user-$i');
      });
      await Future.wait(futures);
      sw.stop();

      final concurrentMs = sw.elapsedMilliseconds;
      final degradation = baselineMs > 0
          ? ((concurrentMs / baselineMs) * 100).round()
          : 0;

      // ignore: avoid_print
      print(
          '  [Stripe同時 $_concurrentUsers件] ${concurrentMs}ms（劣化率: $degradation%）');
      _record('Stripe同時 $_concurrentUsers件', concurrentMs,
          _thresholdApiConcurrentMs);
      expect(concurrentMs, lessThan(_thresholdApiConcurrentMs));
    });

    test('Stripe createCheckoutUrl × $_concurrentUsers 同時', () async {
      final mockClient = _createLatencyClient(
        latencyMs: _apiLatencyMs,
        response: {'url': 'https://checkout.stripe.com/test'},
      );

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final sw = Stopwatch()..start();
      final futures = List.generate(_concurrentUsers, (i) {
        final svc = StripeService(prefs, httpClient: mockClient);
        return svc.createCheckoutUrl(userKey: 'user-$i');
      });
      final results = await Future.wait(futures);
      sw.stop();

      final successCount = results.where((r) => r != null).length;
      // ignore: avoid_print
      print(
          '  [Checkout同時 $_concurrentUsers件] ${sw.elapsedMilliseconds}ms'
          '（成功: $successCount/$_concurrentUsers）');
      _record('Checkout同時 $_concurrentUsers件',
          sw.elapsedMilliseconds, _thresholdApiConcurrentMs);
      expect(successCount, _concurrentUsers);
      expect(sw.elapsedMilliseconds, lessThan(_thresholdApiConcurrentMs));
    });

    test('API遅延増加時の耐性（200ms → 1000ms）', () async {
      final slowClient = _createLatencyClient(
        latencyMs: 1000, // 5倍遅いAPI
        response: {'active': true},
      );

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final sw = Stopwatch()..start();
      final futures = List.generate(10, (i) {
        final svc = StripeService(prefs, httpClient: slowClient);
        return svc.verifySubscription(userKey: 'slow-$i');
      });
      final results = await Future.wait(futures);
      sw.stop();

      // 全リクエストがnull以外を返す（タイムアウトしない）
      final successCount = results.where((r) => r != null).length;
      // ignore: avoid_print
      print(
          '  [低速API 10件] ${sw.elapsedMilliseconds}ms（成功: $successCount/10）');
      _record(
          '低速API 10件', sw.elapsedMilliseconds, _apiTimeoutMs);
      expect(successCount, 10);
      expect(sw.elapsedMilliseconds, lessThan(_apiTimeoutMs));
    });
  });

  // ══════════════════════════════════════════════════════════
  // 2. DB への同時読み書き
  // ══════════════════════════════════════════════════════════
  group('DBへの同時読み書き', () {
    late AppDatabase db;
    late DreamService dreamService;
    late GoalService goalService;
    late TaskService taskService;
    late StudyLogService studyLogService;

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
      studyLogService = StudyLogService(studyLogDao: db.studyLogDao);
    });

    tearDown(() => db.close());

    test('同時INSERT × $_concurrentDbOps 件', () async {
      // ignore: avoid_print
      print('\n=== DB同時読み書き ===');

      final dream = await dreamService.createDream(title: '同時テスト夢');
      final goal = await goalService.createGoal(
        dreamId: dream.id,
        what: '同時テスト目標',
        how: 'テスト',
        whenTarget: '2027-12-31',
        whenType: WhenType.date,
      );
      final task = await taskService.createTask(
        goalId: goal.id,
        title: '同時テストタスク',
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2027, 12, 31),
      );

      final sw = Stopwatch()..start();
      final futures = List.generate(_concurrentDbOps, (i) {
        return studyLogService.addStudyLog(
          taskId: task.id,
          studyDate: DateTime(2025, 1, 1).add(Duration(days: i)),
          durationMinutes: 60,
          taskName: '同時テストタスク',
        );
      });
      await Future.wait(futures);
      sw.stop();

      // ignore: avoid_print
      print(
          '  [同時INSERT $_concurrentDbOps件] ${sw.elapsedMilliseconds}ms');
      _record('同時INSERT $_concurrentDbOps件', sw.elapsedMilliseconds,
          _thresholdDbConcurrentMs);

      // 全件正しく挿入されているか
      final logs = await studyLogService.getAllLogs();
      expect(logs.length, _concurrentDbOps);
      expect(sw.elapsedMilliseconds, lessThan(_thresholdDbConcurrentMs));
    });

    test('読み込みと書き込みの同時実行', () async {
      // 事前データ投入
      final dream = await dreamService.createDream(title: '読み書き夢');
      final goal = await goalService.createGoal(
        dreamId: dream.id,
        what: '読み書き目標',
        how: 'テスト',
        whenTarget: '2027-12-31',
        whenType: WhenType.date,
      );
      final task = await taskService.createTask(
        goalId: goal.id,
        title: '読み書きタスク',
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2027, 12, 31),
      );
      for (var i = 0; i < 100; i++) {
        await studyLogService.addStudyLog(
          taskId: task.id,
          studyDate: DateTime(2025, 1, 1).add(Duration(days: i)),
          durationMinutes: 60,
          taskName: '読み書きタスク',
        );
      }

      final sw = Stopwatch()..start();
      // 読み込みと書き込みを同時実行
      final futures = <Future<Object?>>[];
      // 50回の読み込み
      for (var i = 0; i < 50; i++) {
        futures.add(studyLogService.getAllLogs());
      }
      // 50回の書き込み
      for (var i = 0; i < 50; i++) {
        futures.add(studyLogService.addStudyLog(
          taskId: task.id,
          studyDate: DateTime(2026, 1, 1).add(Duration(days: i)),
          durationMinutes: 30,
          taskName: '読み書きタスク',
        ));
      }
      await Future.wait(futures);
      sw.stop();

      // ignore: avoid_print
      print(
          '  [読み書き同時 100件] ${sw.elapsedMilliseconds}ms');
      _record('読み書き同時 100件', sw.elapsedMilliseconds,
          _thresholdDbConcurrentMs);

      final allLogs = await studyLogService.getAllLogs();
      expect(allLogs.length, 150); // 100 + 50
      expect(sw.elapsedMilliseconds, lessThan(_thresholdDbConcurrentMs));
    });

    test('エクスポートとインポートの競合', () async {
      final exportService = DataExportService(
        dreamDao: db.dreamDao,
        goalDao: db.goalDao,
        taskDao: db.taskDao,
        bookDao: db.bookDao,
        studyLogDao: db.studyLogDao,
        notificationDao: db.notificationDao,
      );

      // データ投入
      await dreamService.createDream(title: '競合テスト夢');
      for (var i = 0; i < 50; i++) {
        await db.studyLogDao.insertStudyLog(StudyLogsCompanion(
          id: Value('conflict-$i'),
          taskId: const Value('task-1'),
          studyDate: Value(DateTime(2025, 1, 1).add(Duration(days: i))),
          durationMinutes: const Value(60),
          createdAt: Value(DateTime.now()),
        ));
      }

      // エクスポートを先に取得
      final json = await exportService.exportData();

      // エクスポートとインポートを同時に実行
      final sw = Stopwatch()..start();
      final futures = <Future<Object?>>[];
      // 5回のエクスポート
      for (var i = 0; i < 5; i++) {
        futures.add(exportService.exportData());
      }
      // 1回のインポート（同時実行中のエクスポートと競合する可能性）
      futures.add(exportService.importData(json));
      await Future.wait(futures);
      sw.stop();

      // ignore: avoid_print
      print(
          '  [エクスポート/インポート競合] ${sw.elapsedMilliseconds}ms');
      _record('エクスポート/インポート競合', sw.elapsedMilliseconds,
          _thresholdSyncMs);
      expect(sw.elapsedMilliseconds, lessThan(_thresholdSyncMs));
    });
  });

  // ══════════════════════════════════════════════════════════
  // 3. クラウド同期の同時実行
  // ══════════════════════════════════════════════════════════
  group('クラウド同期の同時実行', () {
    test('requestSync の大量デバウンス', () async {
      // ignore: avoid_print
      print('\n=== クラウド同期 ===');

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final db = _createDb();
      final exportService = DataExportService(
        dreamDao: db.dreamDao,
        goalDao: db.goalDao,
        taskDao: db.taskDao,
        bookDao: db.bookDao,
        studyLogDao: db.studyLogDao,
        notificationDao: db.notificationDao,
      );

      var uploadCount = 0;
      final mockSync = _MockCloudSyncClient(
        onUpload: (_) => uploadCount++,
      );

      final syncManager = SyncManager.forTest(webMode: true);
      syncManager.init(
        exportService,
        prefs: prefs,
        syncService: mockSync,
      );

      // 100回の requestSync を短時間に発行
      final sw = Stopwatch()..start();
      for (var i = 0; i < 100; i++) {
        syncManager.requestSync();
      }
      // デバウンス待ち（3秒 + マージン）
      await Future<void>.delayed(const Duration(seconds: 4));
      sw.stop();

      // デバウンスにより1回だけアップロードされるべき
      // ignore: avoid_print
      print(
          '  [requestSync ×100 デバウンス] ${sw.elapsedMilliseconds}ms（実行回数: $uploadCount）');
      _record('requestSync ×100 デバウンス', sw.elapsedMilliseconds,
          _thresholdSyncMs);
      expect(uploadCount, lessThanOrEqualTo(1));
      expect(sw.elapsedMilliseconds, lessThan(_thresholdSyncMs));

      syncManager.reset();
      await db.close();
    });

    test('syncOnExit の即時実行', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final db = _createDb();
      final exportService = DataExportService(
        dreamDao: db.dreamDao,
        goalDao: db.goalDao,
        taskDao: db.taskDao,
        bookDao: db.bookDao,
        studyLogDao: db.studyLogDao,
        notificationDao: db.notificationDao,
      );

      var uploadCount = 0;
      final mockSync = _MockCloudSyncClient(
        onUpload: (_) => uploadCount++,
      );

      final syncManager = SyncManager.forTest(webMode: true);
      syncManager.init(
        exportService,
        prefs: prefs,
        syncService: mockSync,
      );

      // requestSync + 即座に syncOnExit
      syncManager.requestSync();
      final sw = Stopwatch()..start();
      await syncManager.syncOnExit();
      sw.stop();

      // ignore: avoid_print
      print('  [syncOnExit 即時実行] ${sw.elapsedMilliseconds}ms');
      _record('syncOnExit 即時実行', sw.elapsedMilliseconds,
          _thresholdSyncMs);
      expect(uploadCount, 1);
      expect(sw.elapsedMilliseconds, lessThan(_thresholdSyncMs));

      syncManager.reset();
      await db.close();
    });
  });

  // ══════════════════════════════════════════════════════════
  // 4. APIエラー耐性
  // ══════════════════════════════════════════════════════════
  group('APIエラー耐性', () {
    test('全リクエスト失敗時にアプリがクラッシュしない', () async {
      // ignore: avoid_print
      print('\n=== APIエラー耐性 ===');

      final errorClient = MockClient((_) async {
        throw Exception('Network error');
      });

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final sw = Stopwatch()..start();
      final futures = List.generate(20, (i) {
        final svc = StripeService(prefs, httpClient: errorClient);
        return svc.verifySubscription(userKey: 'error-$i');
      });
      final results = await Future.wait(futures);
      sw.stop();

      // 全て null（エラー時はnull返却）でクラッシュしない
      expect(results.every((r) => r == null), isTrue);
      // ignore: avoid_print
      print(
          '  [全エラー 20件] ${sw.elapsedMilliseconds}ms（全件null返却、クラッシュなし）');
      _record('全エラー 20件', sw.elapsedMilliseconds,
          _thresholdApiConcurrentMs);
      expect(sw.elapsedMilliseconds, lessThan(_thresholdApiConcurrentMs));
    });

    test('タイムアウト混在時の耐性', () async {
      var requestCount = 0;
      final mixedClient = MockClient((request) async {
        requestCount++;
        if (requestCount % 3 == 0) {
          // 3回に1回はタイムアウト（16秒遅延 > 15秒タイムアウト）
          await Future<void>.delayed(const Duration(seconds: 16));
        }
        return http.Response(jsonEncode({'active': true}), 200);
      });

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final sw = Stopwatch()..start();
      final futures = List.generate(9, (i) {
        final svc = StripeService(prefs, httpClient: mixedClient);
        return svc.verifySubscription(userKey: 'mixed-$i');
      });
      final results = await Future.wait(futures);
      sw.stop();

      final successCount = results.where((r) => r != null).length;
      final failCount = results.where((r) => r == null).length;
      // ignore: avoid_print
      print(
          '  [タイムアウト混在 9件] ${sw.elapsedMilliseconds}ms'
          '（成功: $successCount, 失敗: $failCount）');
      _record('タイムアウト混在 9件', sw.elapsedMilliseconds,
          _apiTimeoutMs + 2000); // タイムアウト15秒 + マージン
      // タイムアウトするリクエストがあっても、残りは成功する
      expect(successCount, greaterThan(0));
    });
  });
}

/// テスト用のクラウド同期クライアント.
class _MockCloudSyncClient implements CloudSyncClient {
  _MockCloudSyncClient({this.onUpload});

  final void Function(String json)? onUpload;

  @override
  bool get isSignedIn => true;

  @override
  Future<void> uploadData(String json) async {
    onUpload?.call(json);
  }

  @override
  Future<String?> downloadData() async => null;

  @override
  Future<DateTime?> getLastSyncTime() async => null;
}
