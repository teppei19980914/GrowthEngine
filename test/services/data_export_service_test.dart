import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yume_hashi/database/app_database.dart';
import 'package:yume_hashi/services/data_export_service.dart';

AppDatabase _createDb() => AppDatabase(NativeDatabase.memory());

void main() {
  late AppDatabase db;
  late DataExportService service;

  setUp(() async {
    db = _createDb();
    service = DataExportService(
      dreamDao: db.dreamDao,
      goalDao: db.goalDao,
      taskDao: db.taskDao,
      bookDao: db.bookDao,
      studyLogDao: db.studyLogDao,
      notificationDao: db.notificationDao,
    );
  });

  tearDown(() => db.close());

  Future<void> insertSampleData() async {
    final now = DateTime.now();
    await db.dreamDao.insertDream(
      DreamsCompanion(
        id: const Value('dream-1'),
        title: const Value('テスト夢'),
        description: const Value('テスト説明'),
        why: const Value('テスト動機'),
        category: const Value('career'),
        sortOrder: const Value(5),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    await db.goalDao.insertGoal(
      GoalsCompanion(
        id: const Value('goal-1'),
        dreamId: const Value('dream-1'),
        why: const Value('テスト理由'),
        whenTarget: const Value('2025年末'),
        whenType: const Value('date'),
        what: const Value('テスト内容'),
        how: const Value('テスト方法'),
        sortOrder: const Value(3),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    await db.taskDao.insertTask(
      TasksCompanion(
        id: const Value('task-1'),
        goalId: const Value('goal-1'),
        title: const Value('テストタスク'),
        startDate: Value(DateTime(2025, 3, 1)),
        endDate: Value(DateTime(2025, 3, 31)),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    await db.bookDao.insertBook(
      BooksCompanion(
        id: const Value('book-1'),
        title: const Value('テスト書籍'),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    await db.studyLogDao.insertStudyLog(
      StudyLogsCompanion(
        id: const Value('log-1'),
        taskId: const Value('task-1'),
        studyDate: Value(DateTime(2025, 3, 1)),
        durationMinutes: const Value(60),
        createdAt: Value(now),
      ),
    );
    await db.notificationDao.insertNotification(
      NotificationsCompanion(
        id: const Value('notif-1'),
        notificationType: const Value('achievement'),
        title: const Value('テスト通知'),
        message: const Value('テストメッセージ'),
        createdAt: Value(now),
      ),
    );
  }

  group('DataExportService', () {
    group('exportData', () {
      test('全データをJSON文字列にエクスポートする', () async {
        await insertSampleData();
        final jsonStr = await service.exportData();
        final data = json.decode(jsonStr) as Map<String, dynamic>;
        expect(data['version'], 1);
        expect(data['exported_at'], isNotEmpty);
        expect((data['dreams'] as List).length, 1);
        expect((data['goals'] as List).length, 1);
        expect((data['tasks'] as List).length, 1);
        expect((data['books'] as List).length, 1);
        expect((data['study_logs'] as List).length, 1);
        expect((data['notifications'] as List).length, 1);
      });

      test('空データでもエクスポートできる', () async {
        final jsonStr = await service.exportData();
        final data = json.decode(jsonStr) as Map<String, dynamic>;
        expect((data['goals'] as List).length, 0);
      });
    });

    group('importData', () {
      test('エクスポートしたデータをインポートする', () async {
        await insertSampleData();
        final exported = await service.exportData();

        // 全削除してからインポート
        await service.clearAllData();
        final goals = await db.goalDao.getAll();
        expect(goals, isEmpty);

        final result = await service.importData(exported);
        expect(result.dreamCount, 1);
        expect(result.goalCount, 1);
        expect(result.taskCount, 1);
        expect(result.bookCount, 1);
        expect(result.studyLogCount, 1);
        expect(result.notificationCount, 1);
        expect(result.total, 6);

        // DBを確認
        final importedGoals = await db.goalDao.getAll();
        expect(importedGoals.length, 1);
        expect(importedGoals.first.why, 'テスト理由');
      });

      test('sortOrderがエクスポート/インポートで保持される', () async {
        await insertSampleData();
        final exported = await service.exportData();

        await service.clearAllData();
        await service.importData(exported);

        // Dream の sortOrder が保持される
        final dreams = await db.dreamDao.getAll();
        expect(dreams.length, 1);
        expect(dreams.first.sortOrder, 5);

        // Goal の sortOrder が保持される
        final goals = await db.goalDao.getAll();
        expect(goals.length, 1);
        expect(goals.first.sortOrder, 3);
      });

      test('不正なJSONでArgumentError', () async {
        expect(
          () => service.importData('not json'),
          throwsArgumentError,
        );
      });

      test('空のデータでもインポートできる', () async {
        final emptyJson = json.encode({
          'version': 1,
          'goals': <dynamic>[],
          'tasks': <dynamic>[],
          'books': <dynamic>[],
          'study_logs': <dynamic>[],
          'notifications': <dynamic>[],
        });
        final result = await service.importData(emptyJson);
        expect(result.total, 0);
      });
    });

    group('validateJson', () {
      test('有効なJSONを検証する', () async {
        await insertSampleData();
        final exported = await service.exportData();
        final result = service.validateJson(exported);
        expect(result.valid, isTrue);
        expect(result.counts['dreams'], 1);
        expect(result.counts['goals'], 1);
        expect(result.counts['tasks'], 1);
      });

      test('不正なJSONを検出する', () {
        final result = service.validateJson('not json');
        expect(result.valid, isFalse);
        expect(result.errorMessage, isNotNull);
      });

      test('不正な構造を検出する', () {
        final result = service.validateJson('"just a string"');
        expect(result.valid, isFalse);
      });
    });

    group('clearAllData', () {
      test('全データを削除する', () async {
        await insertSampleData();
        final deleted = await service.clearAllData();
        expect(deleted, 6); // dream + goal + task + book + log + notification

        expect(await db.dreamDao.getAll(), isEmpty);
        expect(await db.goalDao.getAll(), isEmpty);
        expect(await db.taskDao.getAll(), isEmpty);
        expect(await db.bookDao.getAll(), isEmpty);
        expect(await db.studyLogDao.getAll(), isEmpty);
        expect(await db.notificationDao.getAll(), isEmpty);
      });

      test('空DBでも正常に動作する', () async {
        final deleted = await service.clearAllData();
        expect(deleted, 0);
      });
    });

    group('buildBackupFileName', () {
      test('ユメハシのバックアップファイル名が生成される', () {
        final now = DateTime(2026, 4, 7, 12, 34, 56);
        final fileName = buildBackupFileName(now);
        expect(fileName, 'yumehashi_backup_2026-04-07T12-34-56.json');
      });

      test('旧アプリ名（yumelog）は含まれない', () {
        final now = DateTime(2026, 4, 7, 12, 34, 56);
        final fileName = buildBackupFileName(now);
        expect(fileName.contains('yumelog'), isFalse);
        expect(fileName.startsWith('yumehashi_backup_'), isTrue);
        expect(fileName.endsWith('.json'), isTrue);
      });
    });
  });
}
