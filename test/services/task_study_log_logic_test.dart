import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yume_hashi/database/app_database.dart';
import 'package:yume_hashi/services/study_log_service.dart';
import 'package:yume_hashi/services/task_study_log_logic.dart';

AppDatabase _createDb() => AppDatabase(NativeDatabase.memory());

void main() {
  late AppDatabase db;
  late StudyLogService studyLogService;
  late TaskStudyLogLogic logic;
  const taskId = 'task-1';
  const taskName = 'テストタスク';
  const goalId = 'goal-1';

  setUp(() async {
    db = _createDb();
    studyLogService = StudyLogService(studyLogDao: db.studyLogDao);
    // テスト用のGoalとTaskを作成
    await db.goalDao.insertGoal(
      GoalsCompanion(
        id: const Value('goal-1'),
        dreamId: const Value('dream-1'),
        why: const Value('test'),
        whenTarget: const Value('随時'),
        whenType: const Value('none'),
        what: const Value('test'),
        how: const Value('test'),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
    await db.taskDao.insertTask(
      TasksCompanion(
        id: const Value(taskId),
        goalId: const Value(goalId),
        title: const Value(taskName),
        startDate: Value(DateTime(2025, 3, 1)),
        endDate: Value(DateTime(2025, 3, 31)),
        status: const Value('not_started'),
        progress: const Value(0),
        memo: const Value(''),
        bookId: const Value(''),
        order: const Value(0),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
    logic = TaskStudyLogLogic(
      studyLogService: studyLogService,
      taskId: taskId,
      taskName: taskName,
    );
  });

  tearDown(() => db.close());

  group('TaskStudyLogLogic', () {
    group('getLogs', () {
      test('空の場合は空リストを返す', () async {
        final logs = await logic.getLogs();
        expect(logs, isEmpty);
      });

      test('追加したログを日付降順で取得する', () async {
        await logic.addLog(
          studyDate: DateTime(2025, 3, 1),
          durationMinutes: 30,
          memo: 'メモ1',
        );
        await logic.addLog(
          studyDate: DateTime(2025, 3, 5),
          durationMinutes: 60,
          memo: 'メモ2',
        );
        final logs = await logic.getLogs();
        expect(logs.length, 2);
        expect(logs[0].studyDate.day, 5); // 降順
        expect(logs[1].studyDate.day, 1);
      });
    });

    group('getStats', () {
      test('統計を正しく計算する', () async {
        await logic.addLog(
          studyDate: DateTime(2025, 3, 1),
          durationMinutes: 30,
        );
        await logic.addLog(
          studyDate: DateTime(2025, 3, 2),
          durationMinutes: 60,
        );
        final stats = await logic.getStats();
        expect(stats.totalMinutes, 90);
        expect(stats.studyDays, 2);
        expect(stats.logCount, 2);
      });
    });

    group('addLog', () {
      test('ログを追加する', () async {
        final log = await logic.addLog(
          studyDate: DateTime(2025, 3, 1),
          durationMinutes: 45,
          memo: 'テストメモ',
        );
        expect(log.taskId, taskId);
        expect(log.durationMinutes, 45);
        expect(log.memo, 'テストメモ');
      });
    });

    group('deleteLog', () {
      test('ログを削除する', () async {
        final log = await logic.addLog(
          studyDate: DateTime(2025, 3, 1),
          durationMinutes: 30,
        );
        final result = await logic.deleteLog(log.id);
        expect(result, isTrue);
        final logs = await logic.getLogs();
        expect(logs, isEmpty);
      });
    });

    group('validateDuration', () {
      test('正常な時間を検証する', () {
        expect(TaskStudyLogLogic.validateDuration(1, 30), 90);
        expect(TaskStudyLogLogic.validateDuration(0, 1), 1);
      });

      test('0時間0分でArgumentError', () {
        expect(
          () => TaskStudyLogLogic.validateDuration(0, 0),
          throwsArgumentError,
        );
      });
    });

    group('formatDuration', () {
      test('60分未満', () {
        expect(TaskStudyLogLogic.formatDuration(30), '30min');
        expect(TaskStudyLogLogic.formatDuration(1), '1min');
      });

      test('60分以上', () {
        expect(TaskStudyLogLogic.formatDuration(60), '1h 00min');
        expect(TaskStudyLogLogic.formatDuration(90), '1h 30min');
        expect(TaskStudyLogLogic.formatDuration(125), '2h 05min');
      });
    });

    group('timer', () {
      test('初期状態ではタイマーは実行中でない', () {
        expect(logic.isTimerRunning, isFalse);
        expect(logic.elapsedSeconds, 0);
      });

      test('タイマーを開始・停止する', () {
        logic.startTimer();
        expect(logic.isTimerRunning, isTrue);
        final minutes = logic.stopTimer();
        expect(minutes, greaterThanOrEqualTo(1)); // 最小1分
        expect(logic.isTimerRunning, isFalse);
      });

      test('タイマー未開始での停止は0を返す', () {
        final minutes = logic.stopTimer();
        expect(minutes, 0);
      });
    });
  });
}
