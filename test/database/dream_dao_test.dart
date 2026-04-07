import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:yume_hashi/database/app_database.dart';
import 'package:yume_hashi/database/daos/dream_dao.dart';

import 'test_database.dart';

void main() {
  late AppDatabase db;
  late DreamDao dao;

  setUp(() {
    db = createTestDatabase();
    dao = DreamDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  DreamsCompanion createDream({
    String id = 'dream-1',
    String title = 'テスト夢',
    String description = '説明',
  }) {
    return DreamsCompanion(
      id: Value(id),
      title: Value(title),
      description: Value(description),
      createdAt: Value(DateTime(2026, 1, 1)),
      updatedAt: Value(DateTime(2026, 1, 1)),
    );
  }

  group('DreamDao', () {
    test('insert and getAll', () async {
      await dao.insertDream(createDream());
      final dreams = await dao.getAll();
      expect(dreams.length, 1);
      expect(dreams[0].title, 'テスト夢');
    });

    test('getAll returns empty list initially', () async {
      final dreams = await dao.getAll();
      expect(dreams, isEmpty);
    });

    test('insert multiple and getAll', () async {
      await dao.insertDream(createDream(id: 'dream-1', title: 'A'));
      await dao.insertDream(createDream(id: 'dream-2', title: 'B'));
      final dreams = await dao.getAll();
      expect(dreams.length, 2);
    });

    test('getById returns existing dream', () async {
      await dao.insertDream(createDream());
      final dream = await dao.getById('dream-1');
      expect(dream, isNotNull);
      expect(dream!.title, 'テスト夢');
    });

    test('getById returns null for nonexistent', () async {
      final dream = await dao.getById('nonexistent');
      expect(dream, isNull);
    });

    test('updateDream updates fields', () async {
      await dao.insertDream(createDream());
      final updated = await dao.updateDream(
        DreamsCompanion(
          id: const Value('dream-1'),
          title: const Value('更新後'),
          description: const Value('更新説明'),
          createdAt: Value(DateTime(2026, 1, 1)),
          updatedAt: Value(DateTime(2026, 1, 2)),
        ),
      );
      expect(updated, isTrue);
      final dream = await dao.getById('dream-1');
      expect(dream!.title, '更新後');
    });

    test('updateDream returns false for nonexistent', () async {
      final updated = await dao.updateDream(
        DreamsCompanion(
          id: const Value('nonexistent'),
          title: const Value('X'),
          updatedAt: Value(DateTime(2026)),
        ),
      );
      expect(updated, isFalse);
    });

    test('deleteById removes dream', () async {
      await dao.insertDream(createDream());
      final deleted = await dao.deleteById('dream-1');
      expect(deleted, isTrue);
      final dreams = await dao.getAll();
      expect(dreams, isEmpty);
    });

    test('deleteById returns false for nonexistent', () async {
      final deleted = await dao.deleteById('nonexistent');
      expect(deleted, isFalse);
    });
  });
}
