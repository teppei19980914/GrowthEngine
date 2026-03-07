import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yume_log/database/app_database.dart';
import 'package:yume_log/models/task.dart';
import 'package:yume_log/services/task_service.dart';

AppDatabase _createDb() => AppDatabase(NativeDatabase.memory());

void main() {
  late AppDatabase db;
  late TaskService service;
  const goalId = 'goal-1';

  setUp(() async {
    db = _createDb();
    service = TaskService(taskDao: db.taskDao);
    // テスト用のGoalを作成
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
  });

  tearDown(() => db.close());

  group('TaskService', () {
    group('createTask', () {
      test('タスクを作成する', () async {
        final task = await service.createTask(
          goalId: goalId,
          title: 'テストタスク',
          startDate: DateTime(2025, 3, 1),
          endDate: DateTime(2025, 3, 31),
        );
        expect(task.title, 'テストタスク');
        expect(task.goalId, goalId);
        expect(task.order, 0);
        expect(task.status, TaskStatus.notStarted);
      });

      test('空タイトルでArgumentError', () async {
        expect(
          () => service.createTask(
            goalId: goalId,
            title: '',
            startDate: DateTime(2025, 3, 1),
            endDate: DateTime(2025, 3, 31),
          ),
          throwsArgumentError,
        );
      });

      test('空白のみのタイトルでArgumentError', () async {
        expect(
          () => service.createTask(
            goalId: goalId,
            title: '   ',
            startDate: DateTime(2025, 3, 1),
            endDate: DateTime(2025, 3, 31),
          ),
          throwsArgumentError,
        );
      });

      test('order自動割り当て', () async {
        await service.createTask(
          goalId: goalId,
          title: 'Task 1',
          startDate: DateTime(2025, 3, 1),
          endDate: DateTime(2025, 3, 31),
        );
        final task2 = await service.createTask(
          goalId: goalId,
          title: 'Task 2',
          startDate: DateTime(2025, 4, 1),
          endDate: DateTime(2025, 4, 30),
        );
        expect(task2.order, 1);
      });
    });

    group('getTasksForGoal', () {
      test('Goal IDで取得', () async {
        await service.createTask(
          goalId: goalId,
          title: 'Task 1',
          startDate: DateTime(2025, 3, 1),
          endDate: DateTime(2025, 3, 31),
        );
        final tasks = await service.getTasksForGoal(goalId);
        expect(tasks.length, 1);
      });
    });

    group('updateTask', () {
      test('タスクを更新する', () async {
        final created = await service.createTask(
          goalId: goalId,
          title: 'Original',
          startDate: DateTime(2025, 3, 1),
          endDate: DateTime(2025, 3, 31),
        );
        final updated = await service.updateTask(
          taskId: created.id,
          title: 'Updated',
          startDate: DateTime(2025, 3, 1),
          endDate: DateTime(2025, 3, 31),
          progress: 50,
        );
        expect(updated, isNotNull);
        expect(updated!.title, 'Updated');
        expect(updated.progress, 50);
        expect(updated.status, TaskStatus.inProgress);
      });

      test('進捗100%でcompleted', () async {
        final created = await service.createTask(
          goalId: goalId,
          title: 'Task',
          startDate: DateTime(2025, 3, 1),
          endDate: DateTime(2025, 3, 31),
        );
        final updated = await service.updateTask(
          taskId: created.id,
          title: 'Task',
          startDate: DateTime(2025, 3, 1),
          endDate: DateTime(2025, 3, 31),
          progress: 100,
        );
        expect(updated!.status, TaskStatus.completed);
      });

      test('空タイトルでArgumentError', () async {
        final created = await service.createTask(
          goalId: goalId,
          title: 'Task',
          startDate: DateTime(2025, 3, 1),
          endDate: DateTime(2025, 3, 31),
        );
        expect(
          () => service.updateTask(
            taskId: created.id,
            title: '',
            startDate: DateTime(2025, 3, 1),
            endDate: DateTime(2025, 3, 31),
            progress: 0,
          ),
          throwsArgumentError,
        );
      });

      test('進捗範囲外でArgumentError', () async {
        final created = await service.createTask(
          goalId: goalId,
          title: 'Task',
          startDate: DateTime(2025, 3, 1),
          endDate: DateTime(2025, 3, 31),
        );
        expect(
          () => service.updateTask(
            taskId: created.id,
            title: 'Task',
            startDate: DateTime(2025, 3, 1),
            endDate: DateTime(2025, 3, 31),
            progress: 101,
          ),
          throwsArgumentError,
        );
      });

      test('終了日<開始日でArgumentError', () async {
        final created = await service.createTask(
          goalId: goalId,
          title: 'Task',
          startDate: DateTime(2025, 3, 1),
          endDate: DateTime(2025, 3, 31),
        );
        expect(
          () => service.updateTask(
            taskId: created.id,
            title: 'Task',
            startDate: DateTime(2025, 4, 1),
            endDate: DateTime(2025, 3, 1),
            progress: 0,
          ),
          throwsArgumentError,
        );
      });

      test('存在しないIDでnull', () async {
        final result = await service.updateTask(
          taskId: 'nonexistent',
          title: 'Task',
          startDate: DateTime(2025, 3, 1),
          endDate: DateTime(2025, 3, 31),
          progress: 0,
        );
        expect(result, isNull);
      });
    });

    group('updateProgress', () {
      test('進捗を更新する', () async {
        final created = await service.createTask(
          goalId: goalId,
          title: 'Task',
          startDate: DateTime(2025, 3, 1),
          endDate: DateTime(2025, 3, 31),
        );
        final updated = await service.updateProgress(created.id, 75);
        expect(updated!.progress, 75);
        expect(updated.status, TaskStatus.inProgress);
      });

      test('無効な進捗でArgumentError', () async {
        expect(
          () => service.updateProgress('task-1', -1),
          throwsArgumentError,
        );
      });

      test('存在しないIDでnull', () async {
        final result = await service.updateProgress('nonexistent', 50);
        expect(result, isNull);
      });
    });

    group('deleteTask', () {
      test('タスクを削除する', () async {
        final task = await service.createTask(
          goalId: goalId,
          title: 'Task',
          startDate: DateTime(2025, 3, 1),
          endDate: DateTime(2025, 3, 31),
        );
        final deleted = await service.deleteTask(task.id);
        expect(deleted, isTrue);
        final tasks = await service.getTasksForGoal(goalId);
        expect(tasks, isEmpty);
      });
    });
  });
}
