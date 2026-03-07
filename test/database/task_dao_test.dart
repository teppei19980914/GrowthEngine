import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:yume_log/database/app_database.dart';
import 'package:yume_log/database/daos/task_dao.dart';

import 'test_database.dart';

void main() {
  late AppDatabase db;
  late TaskDao dao;

  setUp(() {
    db = createTestDatabase();
    dao = TaskDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  TasksCompanion createTask({
    String id = 'task-1',
    String goalId = 'goal-1',
    String title = 'テストタスク',
    String status = 'not_started',
    int progress = 0,
    String memo = '',
    String bookId = '',
    int order = 0,
  }) {
    return TasksCompanion(
      id: Value(id),
      goalId: Value(goalId),
      title: Value(title),
      startDate: Value(DateTime(2026, 1, 1)),
      endDate: Value(DateTime(2026, 1, 31)),
      status: Value(status),
      progress: Value(progress),
      memo: Value(memo),
      bookId: Value(bookId),
      order: Value(order),
      createdAt: Value(DateTime(2026, 1, 1)),
      updatedAt: Value(DateTime(2026, 1, 1)),
    );
  }

  group('TaskDao', () {
    test('insert and getAll', () async {
      await dao.insertTask(createTask());
      final tasks = await dao.getAll();
      expect(tasks.length, 1);
      expect(tasks[0].title, 'テストタスク');
    });

    test('getById returns task', () async {
      await dao.insertTask(createTask(id: 'task-1'));
      final task = await dao.getById('task-1');
      expect(task, isNotNull);
      expect(task!.id, 'task-1');
    });

    test('getById returns null when not found', () async {
      final task = await dao.getById('nonexistent');
      expect(task, isNull);
    });

    test('getByGoalId returns filtered tasks sorted by order', () async {
      await dao.insertTask(
        createTask(id: 'task-1', goalId: 'goal-1', order: 2, title: 'B'),
      );
      await dao.insertTask(
        createTask(id: 'task-2', goalId: 'goal-1', order: 1, title: 'A'),
      );
      await dao.insertTask(
        createTask(id: 'task-3', goalId: 'goal-2', order: 0, title: 'C'),
      );

      final tasks = await dao.getByGoalId('goal-1');
      expect(tasks.length, 2);
      expect(tasks[0].title, 'A');
      expect(tasks[1].title, 'B');
    });

    test('getByGoalId returns empty list when no match', () async {
      await dao.insertTask(createTask(goalId: 'goal-1'));
      final tasks = await dao.getByGoalId('goal-2');
      expect(tasks, isEmpty);
    });

    test('getByBookId returns filtered tasks sorted by order', () async {
      await dao.insertTask(
        createTask(id: 'task-1', bookId: 'book-1', order: 2, title: 'B'),
      );
      await dao.insertTask(
        createTask(id: 'task-2', bookId: 'book-1', order: 1, title: 'A'),
      );
      await dao.insertTask(
        createTask(id: 'task-3', bookId: 'book-2', order: 0, title: 'C'),
      );

      final tasks = await dao.getByBookId('book-1');
      expect(tasks.length, 2);
      expect(tasks[0].title, 'A');
      expect(tasks[1].title, 'B');
    });

    test('updateTask updates fields', () async {
      await dao.insertTask(createTask(id: 'task-1'));
      final updated = await dao.updateTask(
        TasksCompanion(
          id: const Value('task-1'),
          title: const Value('更新タスク'),
          progress: const Value(50),
          status: const Value('in_progress'),
          updatedAt: Value(DateTime(2026, 6, 1)),
        ),
      );
      expect(updated, isTrue);
      final task = await dao.getById('task-1');
      expect(task!.title, '更新タスク');
      expect(task.progress, 50);
      expect(task.status, 'in_progress');
    });

    test('updateTask returns false when not found', () async {
      final updated = await dao.updateTask(
        const TasksCompanion(
          id: Value('nonexistent'),
          title: Value('test'),
        ),
      );
      expect(updated, isFalse);
    });

    test('deleteById removes task', () async {
      await dao.insertTask(createTask(id: 'task-1'));
      final deleted = await dao.deleteById('task-1');
      expect(deleted, isTrue);
      final tasks = await dao.getAll();
      expect(tasks, isEmpty);
    });

    test('deleteById returns false when not found', () async {
      final deleted = await dao.deleteById('nonexistent');
      expect(deleted, isFalse);
    });

    test('deleteByGoalId removes all tasks for goal', () async {
      await dao.insertTask(createTask(id: 'task-1', goalId: 'goal-1'));
      await dao.insertTask(createTask(id: 'task-2', goalId: 'goal-1'));
      await dao.insertTask(createTask(id: 'task-3', goalId: 'goal-2'));

      final count = await dao.deleteByGoalId('goal-1');
      expect(count, 2);
      final all = await dao.getAll();
      expect(all.length, 1);
      expect(all[0].goalId, 'goal-2');
    });

    test('deleteByGoalId returns 0 when no match', () async {
      final count = await dao.deleteByGoalId('nonexistent');
      expect(count, 0);
    });
  });
}
