import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yume_hashi/database/app_database.dart';
import 'package:yume_hashi/models/goal.dart';
import 'package:yume_hashi/services/goal_service.dart';

AppDatabase _createDb() => AppDatabase(NativeDatabase.memory());

void main() {
  late AppDatabase db;
  late GoalService service;

  setUp(() {
    db = _createDb();
    service = GoalService(goalDao: db.goalDao, taskDao: db.taskDao);
  });

  tearDown(() => db.close());

  group('GoalService', () {
    group('createGoal', () {
      test('Goalを作成する', () async {
        final goal = await service.createGoal(
          dreamId: 'dream-1',
          whenTarget: '2025年末',
          whenType: WhenType.date,
          what: 'テスト内容',
          how: 'テスト方法',
        );
        expect(goal.what, 'テスト内容');
        expect(goal.how, 'テスト方法');
        expect(goal.color, isNotEmpty);
      });

      test('空のwhatでArgumentError', () async {
        expect(
          () => service.createGoal(
            dreamId: 'dream-1',
            whenTarget: '2025年末',
            whenType: WhenType.date,
            what: '',
            how: 'テスト',
          ),
          throwsArgumentError,
        );
      });

      test('空のhowでArgumentError', () async {
        expect(
          () => service.createGoal(
            dreamId: 'dream-1',

            whenTarget: '2025年末',
            whenType: WhenType.date,
            what: 'テスト',
            how: '  ',
          ),
          throwsArgumentError,
        );
      });

      test('空のwhenTargetでArgumentError', () async {
        expect(
          () => service.createGoal(
            dreamId: 'dream-1',

            whenTarget: '',
            whenType: WhenType.date,
            what: 'テスト',
            how: 'テスト',
          ),
          throwsArgumentError,
        );
      });

      test('空白のみのwhenTargetでArgumentError', () async {
        expect(
          () => service.createGoal(
            dreamId: 'dream-1',

            whenTarget: '   ',
            whenType: WhenType.date,
            what: 'テスト',
            how: 'テスト',
          ),
          throwsArgumentError,
        );
      });

      test('色が自動割り当てされる', () async {
        final g1 = await service.createGoal(
          dreamId: 'dream-1',
          whenTarget: '2025年末',
          whenType: WhenType.period,
          what: 'X1',
          how: 'H1',
        );
        final g2 = await service.createGoal(
          dreamId: 'dream-1',
          whenTarget: '2026年末',
          whenType: WhenType.period,
          what: 'X2',
          how: 'H2',
        );
        expect(g1.color, isNot(g2.color));
      });

      test('dreamIdなしで独立した目標を作成できる', () async {
        final goal = await service.createGoal(
          whenTarget: '2026年末',
          whenType: WhenType.date,
          what: '独立した目標',
          how: '自由に進める',
        );
        expect(goal.dreamId, isEmpty);
        expect(goal.what, '独立した目標');
      });
    });

    group('getStandaloneGoals', () {
      test('独立した目標のみ取得する', () async {
        await service.createGoal(
          dreamId: 'dream-1',
          whenTarget: '随時',
          whenType: WhenType.period,
          what: '夢に紐づく目標',
          how: 'H',
        );
        await service.createGoal(
          whenTarget: '随時',
          whenType: WhenType.period,
          what: '独立目標',
          how: 'H',
        );
        final standalone = await service.getStandaloneGoals();
        expect(standalone.length, 1);
        expect(standalone.first.what, '独立目標');
        expect(standalone.first.dreamId, isEmpty);
      });
    });

    group('getAllGoals', () {
      test('全Goal取得', () async {
        await service.createGoal(
          dreamId: 'dream-1',
          whenTarget: '随時',
          whenType: WhenType.period,
          what: 'X1',
          how: 'H1',
        );
        await service.createGoal(
          dreamId: 'dream-1',
          whenTarget: '随時',
          whenType: WhenType.period,
          what: 'X2',
          how: 'H2',
        );
        final goals = await service.getAllGoals();
        expect(goals.length, 2);
      });
    });

    group('getGoal', () {
      test('IDで取得', () async {
        final created = await service.createGoal(
          dreamId: 'dream-1',
          whenTarget: '随時',
          whenType: WhenType.period,
          what: 'X',
          how: 'H',
        );
        final found = await service.getGoal(created.id);
        expect(found, isNotNull);
        expect(found!.id, created.id);
      });

      test('存在しないIDでnull', () async {
        final found = await service.getGoal('nonexistent');
        expect(found, isNull);
      });
    });

    group('updateGoal', () {
      test('Goalを更新する', () async {
        final created = await service.createGoal(
          dreamId: 'dream-1',
          whenTarget: '随時',
          whenType: WhenType.period,
          what: 'X',
          how: 'H',
        );
        final updated = await service.updateGoal(
          goalId: created.id,
          dreamId: 'dream-1',
          whenTarget: '2025年',
          whenType: WhenType.date,
          what: 'X2',
          how: 'H2',
        );
        expect(updated, isNotNull);
        expect(updated!.what, 'X2');
      });

      test('存在しないIDでnull', () async {
        final result = await service.updateGoal(
          goalId: 'nonexistent',
          dreamId: 'dream-1',
          whenTarget: '随時',
          whenType: WhenType.period,
          what: 'X',
          how: 'H',
        );
        expect(result, isNull);
      });
    });

    group('deleteGoal', () {
      test('Goalとタスクをカスケード削除する', () async {
        final goal = await service.createGoal(
          dreamId: 'dream-1',
          whenTarget: '随時',
          whenType: WhenType.period,
          what: 'X',
          how: 'H',
        );
        // タスクを追加
        await db.taskDao.insertTask(
          TasksCompanion(
            id: const Value('task-1'),
            goalId: Value(goal.id),
            title: const Value('Task 1'),
            startDate: Value(DateTime(2025, 3, 1)),
            endDate: Value(DateTime(2025, 3, 31)),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ),
        );
        final deleted = await service.deleteGoal(goal.id);
        expect(deleted, isTrue);
        final remaining = await service.getAllGoals();
        expect(remaining, isEmpty);
        final tasks = await db.taskDao.getByGoalId(goal.id);
        expect(tasks, isEmpty);
      });
    });
  });
}
