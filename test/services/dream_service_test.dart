import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yume_log/database/app_database.dart' hide Dream;
import 'package:yume_log/services/dream_service.dart';

AppDatabase _createDb() => AppDatabase(NativeDatabase.memory());

void main() {
  late AppDatabase db;
  late DreamService service;

  setUp(() async {
    db = _createDb();
    service = DreamService(
      dreamDao: db.dreamDao,
      goalDao: db.goalDao,
      taskDao: db.taskDao,
    );
  });

  tearDown(() => db.close());

  group('DreamService', () {
    group('createDream', () {
      test('夢を作成する', () async {
        final dream = await service.createDream(title: '医者になる');
        expect(dream.title, '医者になる');
        expect(dream.description, '');
      });

      test('説明付きで夢を作成する', () async {
        final dream = await service.createDream(
          title: '医者になる',
          description: '人の役に立ちたい',
        );
        expect(dream.description, '人の役に立ちたい');
      });

      test('タイトルの前後空白をトリムする', () async {
        final dream = await service.createDream(title: '  テスト  ');
        expect(dream.title, 'テスト');
      });

      test('空タイトルでArgumentError', () async {
        expect(
          () => service.createDream(title: ''),
          throwsArgumentError,
        );
      });

      test('空白のみでArgumentError', () async {
        expect(
          () => service.createDream(title: '   '),
          throwsArgumentError,
        );
      });
    });

    group('getAllDreams', () {
      test('全夢を取得する', () async {
        await service.createDream(title: 'Dream 1');
        await service.createDream(title: 'Dream 2');
        final dreams = await service.getAllDreams();
        expect(dreams.length, 2);
      });
    });

    group('getDream', () {
      test('IDで取得', () async {
        final created = await service.createDream(title: 'Test');
        final found = await service.getDream(created.id);
        expect(found, isNotNull);
        expect(found!.title, 'Test');
      });

      test('存在しないIDでnull', () async {
        final found = await service.getDream('nonexistent');
        expect(found, isNull);
      });
    });

    group('updateDream', () {
      test('夢を更新する', () async {
        final dream = await service.createDream(title: 'テスト');
        final updated = await service.updateDream(
          dreamId: dream.id,
          title: '更新後',
          description: '新しい説明',
        );
        expect(updated, isNotNull);
        expect(updated!.title, '更新後');
        expect(updated.description, '新しい説明');
      });

      test('空タイトルでArgumentError', () async {
        final dream = await service.createDream(title: 'テスト');
        expect(
          () => service.updateDream(dreamId: dream.id, title: ''),
          throwsArgumentError,
        );
      });

      test('存在しないIDでnull', () async {
        final result = await service.updateDream(
          dreamId: 'nonexistent',
          title: 'テスト',
        );
        expect(result, isNull);
      });
    });

    group('deleteDream', () {
      test('夢を削除する', () async {
        final dream = await service.createDream(title: 'Test');
        final deleted = await service.deleteDream(dream.id);
        expect(deleted, isTrue);
        final remaining = await service.getAllDreams();
        expect(remaining, isEmpty);
      });

      test('紐づくGoalとTaskがカスケード削除される', () async {
        final dream = await service.createDream(title: 'Test');
        // Goal を作成
        final now = DateTime.now();
        await db.goalDao.insertGoal(
          GoalsCompanion(
            id: const Value('goal-1'),
            dreamId: Value(dream.id),
            why: const Value('テスト理由'),
            whenTarget: const Value('2026年末'),
            whenType: const Value('date'),
            what: const Value('テスト内容'),
            how: const Value('テスト方法'),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
        // Task を作成
        await db.taskDao.insertTask(
          TasksCompanion(
            id: const Value('task-1'),
            goalId: const Value('goal-1'),
            title: const Value('テストタスク'),
            startDate: Value(DateTime(2026, 3, 1)),
            endDate: Value(DateTime(2026, 3, 31)),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

        await service.deleteDream(dream.id);

        expect(await db.goalDao.getAll(), isEmpty);
        expect(await db.taskDao.getAll(), isEmpty);
      });
    });
  });
}
