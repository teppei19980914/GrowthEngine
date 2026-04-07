import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:yume_hashi/database/app_database.dart';
import 'package:yume_hashi/database/daos/study_log_dao.dart';

import 'test_database.dart';

void main() {
  late AppDatabase db;
  late StudyLogDao dao;

  setUp(() {
    db = createTestDatabase();
    dao = StudyLogDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  StudyLogsCompanion createLog({
    String id = 'log-1',
    String taskId = 'task-1',
    int durationMinutes = 60,
    String memo = '',
    String taskName = 'テストタスク',
    DateTime? studyDate,
  }) {
    return StudyLogsCompanion(
      id: Value(id),
      taskId: Value(taskId),
      studyDate: Value(studyDate ?? DateTime(2026, 3, 1)),
      durationMinutes: Value(durationMinutes),
      memo: Value(memo),
      taskName: Value(taskName),
      createdAt: Value(DateTime(2026, 3, 1)),
    );
  }

  group('StudyLogDao', () {
    test('insert and getAll', () async {
      await dao.insertStudyLog(createLog());
      final logs = await dao.getAll();
      expect(logs.length, 1);
      expect(logs[0].durationMinutes, 60);
    });

    test('getAll returns empty list initially', () async {
      final logs = await dao.getAll();
      expect(logs, isEmpty);
    });

    test('getByTaskId returns filtered logs sorted by date', () async {
      await dao.insertStudyLog(
        createLog(
          id: 'log-1',
          taskId: 'task-1',
          studyDate: DateTime(2026, 3, 3),
        ),
      );
      await dao.insertStudyLog(
        createLog(
          id: 'log-2',
          taskId: 'task-1',
          studyDate: DateTime(2026, 3, 1),
        ),
      );
      await dao.insertStudyLog(
        createLog(
          id: 'log-3',
          taskId: 'task-2',
          studyDate: DateTime(2026, 3, 2),
        ),
      );

      final logs = await dao.getByTaskId('task-1');
      expect(logs.length, 2);
      expect(logs[0].studyDate.day, 1);
      expect(logs[1].studyDate.day, 3);
    });

    test('getByTaskId returns empty list when no match', () async {
      await dao.insertStudyLog(createLog(taskId: 'task-1'));
      final logs = await dao.getByTaskId('task-2');
      expect(logs, isEmpty);
    });

    test('getByTaskIds returns logs for multiple tasks sorted by date',
        () async {
      await dao.insertStudyLog(
        createLog(
          id: 'log-1',
          taskId: 'task-1',
          studyDate: DateTime(2026, 3, 3),
        ),
      );
      await dao.insertStudyLog(
        createLog(
          id: 'log-2',
          taskId: 'task-2',
          studyDate: DateTime(2026, 3, 1),
        ),
      );
      await dao.insertStudyLog(
        createLog(
          id: 'log-3',
          taskId: 'task-3',
          studyDate: DateTime(2026, 3, 2),
        ),
      );

      final logs = await dao.getByTaskIds(['task-1', 'task-2']);
      expect(logs.length, 2);
      expect(logs[0].taskId, 'task-2');
      expect(logs[1].taskId, 'task-1');
    });

    test('getByTaskIds with empty list returns empty', () async {
      await dao.insertStudyLog(createLog());
      final logs = await dao.getByTaskIds([]);
      expect(logs, isEmpty);
    });

    test('updateStudyLog updates fields', () async {
      await dao.insertStudyLog(createLog(id: 'log-1'));
      final updated = await dao.updateStudyLog(
        const StudyLogsCompanion(
          id: Value('log-1'),
          durationMinutes: Value(120),
          memo: Value('更新メモ'),
        ),
      );
      expect(updated, isTrue);
      final logs = await dao.getByTaskId('task-1');
      expect(logs[0].durationMinutes, 120);
      expect(logs[0].memo, '更新メモ');
    });

    test('updateStudyLog returns false when not found', () async {
      final updated = await dao.updateStudyLog(
        const StudyLogsCompanion(
          id: Value('nonexistent'),
          durationMinutes: Value(30),
        ),
      );
      expect(updated, isFalse);
    });

    test('deleteById removes log', () async {
      await dao.insertStudyLog(createLog(id: 'log-1'));
      final deleted = await dao.deleteById('log-1');
      expect(deleted, isTrue);
      final logs = await dao.getAll();
      expect(logs, isEmpty);
    });

    test('deleteById returns false when not found', () async {
      final deleted = await dao.deleteById('nonexistent');
      expect(deleted, isFalse);
    });

    test('deleteByTaskId removes all logs for task', () async {
      await dao.insertStudyLog(createLog(id: 'log-1', taskId: 'task-1'));
      await dao.insertStudyLog(createLog(id: 'log-2', taskId: 'task-1'));
      await dao.insertStudyLog(createLog(id: 'log-3', taskId: 'task-2'));

      final count = await dao.deleteByTaskId('task-1');
      expect(count, 2);
      final all = await dao.getAll();
      expect(all.length, 1);
      expect(all[0].taskId, 'task-2');
    });

    test('deleteByTaskId returns 0 when no match', () async {
      final count = await dao.deleteByTaskId('nonexistent');
      expect(count, 0);
    });
  });
}
