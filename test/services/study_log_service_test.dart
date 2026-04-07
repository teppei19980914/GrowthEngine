import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yume_hashi/database/app_database.dart';
import 'package:yume_hashi/services/study_log_service.dart';

AppDatabase _createDb() => AppDatabase(NativeDatabase.memory());

void main() {
  late AppDatabase db;
  late StudyLogService service;

  setUp(() async {
    db = _createDb();
    service = StudyLogService(studyLogDao: db.studyLogDao);
    // テスト用Goal + Task
    await db.goalDao.insertGoal(
      GoalsCompanion(
        id: const Value('goal-1'),
        dreamId: const Value('dream-1'),
        why: const Value('test'),
        whenTarget: const Value(''),
        whenType: const Value('none'),
        what: const Value('test'),
        how: const Value('test'),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
    await db.taskDao.insertTask(
      TasksCompanion(
        id: const Value('task-1'),
        goalId: const Value('goal-1'),
        title: const Value('Task 1'),
        startDate: Value(DateTime(2025, 3, 1)),
        endDate: Value(DateTime(2025, 3, 31)),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
    await db.taskDao.insertTask(
      TasksCompanion(
        id: const Value('task-2'),
        goalId: const Value('goal-1'),
        title: const Value('Task 2'),
        startDate: Value(DateTime(2025, 3, 1)),
        endDate: Value(DateTime(2025, 3, 31)),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  });

  tearDown(() => db.close());

  group('StudyLogService', () {
    group('addStudyLog', () {
      test('活動ログを追加する', () async {
        final log = await service.addStudyLog(
          taskId: 'task-1',
          studyDate: DateTime(2025, 3, 1),
          durationMinutes: 60,
          taskName: 'Task 1',
        );
        expect(log.taskId, 'task-1');
        expect(log.durationMinutes, 60);
        expect(log.taskName, 'Task 1');
      });
    });

    group('getLogsForTask', () {
      test('タスク別ログ取得', () async {
        await service.addStudyLog(
          taskId: 'task-1',
          studyDate: DateTime(2025, 3, 1),
          durationMinutes: 60,
        );
        await service.addStudyLog(
          taskId: 'task-2',
          studyDate: DateTime(2025, 3, 1),
          durationMinutes: 30,
        );
        final logs = await service.getLogsForTask('task-1');
        expect(logs.length, 1);
        expect(logs.first.durationMinutes, 60);
      });
    });

    group('getAllLogs', () {
      test('全ログ取得', () async {
        await service.addStudyLog(
          taskId: 'task-1',
          studyDate: DateTime(2025, 3, 1),
          durationMinutes: 60,
        );
        await service.addStudyLog(
          taskId: 'task-2',
          studyDate: DateTime(2025, 3, 2),
          durationMinutes: 30,
        );
        final logs = await service.getAllLogs();
        expect(logs.length, 2);
      });
    });

    group('deleteLog', () {
      test('ログを削除する', () async {
        final log = await service.addStudyLog(
          taskId: 'task-1',
          studyDate: DateTime(2025, 3, 1),
          durationMinutes: 60,
        );
        final deleted = await service.deleteLog(log.id);
        expect(deleted, isTrue);
        final remaining = await service.getAllLogs();
        expect(remaining, isEmpty);
      });
    });

    group('getTaskStats', () {
      test('タスク別統計を計算する', () async {
        await service.addStudyLog(
          taskId: 'task-1',
          studyDate: DateTime(2025, 3, 1),
          durationMinutes: 60,
        );
        await service.addStudyLog(
          taskId: 'task-1',
          studyDate: DateTime(2025, 3, 1),
          durationMinutes: 30,
        );
        await service.addStudyLog(
          taskId: 'task-1',
          studyDate: DateTime(2025, 3, 2),
          durationMinutes: 45,
        );
        final stats = await service.getTaskStats('task-1');
        expect(stats.totalMinutes, 135);
        expect(stats.studyDays, 2);
        expect(stats.logCount, 3);
      });
    });

    group('getGoalStats', () {
      test('目標別統計を計算する', () async {
        await service.addStudyLog(
          taskId: 'task-1',
          studyDate: DateTime(2025, 3, 1),
          durationMinutes: 60,
        );
        await service.addStudyLog(
          taskId: 'task-2',
          studyDate: DateTime(2025, 3, 1),
          durationMinutes: 30,
        );
        await service.addStudyLog(
          taskId: 'task-2',
          studyDate: DateTime(2025, 3, 2),
          durationMinutes: 45,
        );
        final stats = await service.getGoalStats(
          'goal-1',
          ['task-1', 'task-2'],
        );
        expect(stats.totalMinutes, 135);
        expect(stats.totalStudyDays, 2); // 重複排除
        expect(stats.taskStats.length, 2);
      });
    });

    group('backfillTaskNames', () {
      test('空のtaskNameを埋める', () async {
        await service.addStudyLog(
          taskId: 'task-1',
          studyDate: DateTime(2025, 3, 1),
          durationMinutes: 60,
          taskName: '', // 空
        );
        final count = await service.backfillTaskNames({
          'task-1': 'Task 1 Name',
        });
        expect(count, 1);
        final logs = await service.getLogsForTask('task-1');
        expect(logs.first.taskName, 'Task 1 Name');
      });

      test('既にtaskNameがある場合は更新しない', () async {
        await service.addStudyLog(
          taskId: 'task-1',
          studyDate: DateTime(2025, 3, 1),
          durationMinutes: 60,
          taskName: 'Existing',
        );
        final count = await service.backfillTaskNames({
          'task-1': 'New Name',
        });
        expect(count, 0);
      });
    });
  });
}
