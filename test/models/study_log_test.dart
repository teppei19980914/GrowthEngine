import 'package:flutter_test/flutter_test.dart';
import 'package:yume_log/models/study_log.dart';

void main() {
  group('StudyLog', () {
    late StudyLog log;

    setUp(() {
      log = StudyLog(
        taskId: 'task-1',
        studyDate: DateTime(2026, 3, 1),
        durationMinutes: 60,
      );
    });

    test('creates with default values', () {
      expect(log.id, isNotEmpty);
      expect(log.taskId, 'task-1');
      expect(log.studyDate, DateTime(2026, 3, 1));
      expect(log.durationMinutes, 60);
      expect(log.memo, '');
      expect(log.taskName, '');
      expect(log.createdAt, isNotNull);
    });

    test('creates with all custom values', () {
      final customLog = StudyLog(
        id: 'custom-id',
        taskId: 'task-2',
        studyDate: DateTime(2026, 3, 2),
        durationMinutes: 90,
        memo: '集中できた',
        taskName: 'Flutter基礎',
        createdAt: DateTime(2026, 3, 2, 21, 0),
      );
      expect(customLog.id, 'custom-id');
      expect(customLog.memo, '集中できた');
      expect(customLog.taskName, 'Flutter基礎');
    });

    group('validation', () {
      test('throws on zero duration', () {
        expect(
          () => StudyLog(
            taskId: 'task-1',
            studyDate: DateTime(2026, 1, 1),
            durationMinutes: 0,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws on negative duration', () {
        expect(
          () => StudyLog(
            taskId: 'task-1',
            studyDate: DateTime(2026, 1, 1),
            durationMinutes: -10,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('allows duration of 1', () {
        final minLog = StudyLog(
          taskId: 'task-1',
          studyDate: DateTime(2026, 1, 1),
          durationMinutes: 1,
        );
        expect(minLog.durationMinutes, 1);
      });
    });

    group('durationHours', () {
      test('converts 60 minutes to 1 hour', () {
        expect(log.durationHours, 1.0);
      });

      test('converts 90 minutes to 1.5 hours', () {
        final log90 = StudyLog(
          taskId: 'task-1',
          studyDate: DateTime(2026, 1, 1),
          durationMinutes: 90,
        );
        expect(log90.durationHours, 1.5);
      });

      test('converts 30 minutes to 0.5 hours', () {
        final log30 = StudyLog(
          taskId: 'task-1',
          studyDate: DateTime(2026, 1, 1),
          durationMinutes: 30,
        );
        expect(log30.durationHours, 0.5);
      });
    });

    group('copyWith', () {
      test('copies with changed fields', () {
        final copied = log.copyWith(
          durationMinutes: 120,
          memo: '更新メモ',
        );
        expect(copied.durationMinutes, 120);
        expect(copied.memo, '更新メモ');
        expect(copied.id, log.id);
        expect(copied.taskId, log.taskId);
      });
    });

    group('toMap / fromMap', () {
      test('round-trip serialization', () {
        final fullLog = StudyLog(
          id: 'test-id',
          taskId: 'task-1',
          studyDate: DateTime(2026, 3, 1),
          durationMinutes: 45,
          memo: 'テストメモ',
          taskName: 'テストタスク',
          createdAt: DateTime(2026, 3, 1, 22, 0),
        );
        final map = fullLog.toMap();
        final restored = StudyLog.fromMap(map);
        expect(restored.id, fullLog.id);
        expect(restored.taskId, fullLog.taskId);
        expect(restored.durationMinutes, fullLog.durationMinutes);
        expect(restored.memo, fullLog.memo);
        expect(restored.taskName, fullLog.taskName);
      });

      test('toMap contains correct keys', () {
        final map = log.toMap();
        expect(map.containsKey('id'), isTrue);
        expect(map.containsKey('task_id'), isTrue);
        expect(map.containsKey('task_name'), isTrue);
        expect(map.containsKey('study_date'), isTrue);
        expect(map.containsKey('duration_minutes'), isTrue);
        expect(map.containsKey('memo'), isTrue);
        expect(map.containsKey('created_at'), isTrue);
      });

      test('fromMap handles missing optional fields', () {
        final map = {
          'id': 'test-id',
          'task_id': 'task-1',
          'study_date': '2026-03-01T00:00:00.000',
          'duration_minutes': 60,
          'created_at': '2026-03-01T00:00:00.000',
        };
        final restored = StudyLog.fromMap(map);
        expect(restored.memo, '');
        expect(restored.taskName, '');
      });
    });

    group('equality', () {
      test('equal when same id', () {
        final log1 = StudyLog(
          id: 'same-id',
          taskId: 'task-1',
          studyDate: DateTime(2026, 1, 1),
          durationMinutes: 30,
        );
        final log2 = StudyLog(
          id: 'same-id',
          taskId: 'task-2',
          studyDate: DateTime(2026, 2, 1),
          durationMinutes: 60,
        );
        expect(log1, equals(log2));
        expect(log1.hashCode, log2.hashCode);
      });

      test('not equal when different id', () {
        final log1 = StudyLog(
          id: 'id-1',
          taskId: 'task-1',
          studyDate: DateTime(2026, 1, 1),
          durationMinutes: 30,
        );
        final log2 = StudyLog(
          id: 'id-2',
          taskId: 'task-1',
          studyDate: DateTime(2026, 1, 1),
          durationMinutes: 30,
        );
        expect(log1, isNot(equals(log2)));
      });
    });

    test('toString contains id and taskId', () {
      final str = log.toString();
      expect(str, contains(log.id));
      expect(str, contains(log.taskId));
    });
  });
}
