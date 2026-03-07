import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:yume_log/database/app_database.dart';
import 'package:yume_log/database/daos/goal_dao.dart';

import 'test_database.dart';

void main() {
  late AppDatabase db;
  late GoalDao dao;

  setUp(() {
    db = createTestDatabase();
    dao = GoalDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  GoalsCompanion createGoal({
    String id = 'goal-1',
    String dreamId = 'dream-1',
    String why = 'テスト理由',
    String whenTarget = '2026-12-31',
    String whenType = 'date',
    String what = 'テスト学習',
    String how = 'テスト方法',
    String color = '#4A9EFF',
  }) {
    return GoalsCompanion(
      id: Value(id),
      dreamId: Value(dreamId),
      why: Value(why),
      whenTarget: Value(whenTarget),
      whenType: Value(whenType),
      what: Value(what),
      how: Value(how),
      color: Value(color),
      createdAt: Value(DateTime(2026, 1, 1)),
      updatedAt: Value(DateTime(2026, 1, 1)),
    );
  }

  group('GoalDao', () {
    test('insert and getAll', () async {
      await dao.insertGoal(createGoal());
      final goals = await dao.getAll();
      expect(goals.length, 1);
      expect(goals[0].what, 'テスト学習');
    });

    test('getAll returns empty list initially', () async {
      final goals = await dao.getAll();
      expect(goals, isEmpty);
    });

    test('insert multiple and getAll', () async {
      await dao.insertGoal(createGoal(id: 'goal-1', what: 'A'));
      await dao.insertGoal(createGoal(id: 'goal-2', what: 'B'));
      await dao.insertGoal(createGoal(id: 'goal-3', what: 'C'));
      final goals = await dao.getAll();
      expect(goals.length, 3);
    });

    test('getById returns goal', () async {
      await dao.insertGoal(createGoal(id: 'goal-1'));
      final goal = await dao.getById('goal-1');
      expect(goal, isNotNull);
      expect(goal!.id, 'goal-1');
      expect(goal.what, 'テスト学習');
    });

    test('getById returns null when not found', () async {
      final goal = await dao.getById('nonexistent');
      expect(goal, isNull);
    });

    test('updateGoal updates fields', () async {
      await dao.insertGoal(createGoal(id: 'goal-1'));
      final updated = await dao.updateGoal(
        GoalsCompanion(
          id: const Value('goal-1'),
          what: const Value('更新された学習'),
          updatedAt: Value(DateTime(2026, 6, 1)),
        ),
      );
      expect(updated, isTrue);
      final goal = await dao.getById('goal-1');
      expect(goal!.what, '更新された学習');
    });

    test('updateGoal returns false when not found', () async {
      final updated = await dao.updateGoal(
        const GoalsCompanion(
          id: Value('nonexistent'),
          what: Value('test'),
        ),
      );
      expect(updated, isFalse);
    });

    test('deleteById removes goal', () async {
      await dao.insertGoal(createGoal(id: 'goal-1'));
      final deleted = await dao.deleteById('goal-1');
      expect(deleted, isTrue);
      final goals = await dao.getAll();
      expect(goals, isEmpty);
    });

    test('deleteById returns false when not found', () async {
      final deleted = await dao.deleteById('nonexistent');
      expect(deleted, isFalse);
    });
  });
}
