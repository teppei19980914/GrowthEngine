import 'package:flutter_test/flutter_test.dart';
import 'package:yume_log/models/task.dart';

void main() {
  group('TaskStatus', () {
    test('values have correct string values', () {
      expect(TaskStatus.notStarted.value, 'not_started');
      expect(TaskStatus.inProgress.value, 'in_progress');
      expect(TaskStatus.completed.value, 'completed');
    });

    test('fromValue returns correct enum', () {
      expect(TaskStatus.fromValue('not_started'), TaskStatus.notStarted);
      expect(TaskStatus.fromValue('in_progress'), TaskStatus.inProgress);
      expect(TaskStatus.fromValue('completed'), TaskStatus.completed);
    });

    test('fromValue throws on invalid value', () {
      expect(
        () => TaskStatus.fromValue('invalid'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('bookGanttGoalId', () {
    test('has correct value', () {
      expect(bookGanttGoalId, '__books__');
    });
  });

  group('Task', () {
    late Task task;
    final startDate = DateTime(2026, 1, 1);
    final endDate = DateTime(2026, 1, 31);

    setUp(() {
      task = Task(
        goalId: 'goal-1',
        title: 'Dart基礎学習',
        startDate: startDate,
        endDate: endDate,
      );
    });

    test('creates with default values', () {
      expect(task.id, isNotEmpty);
      expect(task.goalId, 'goal-1');
      expect(task.title, 'Dart基礎学習');
      expect(task.startDate, startDate);
      expect(task.endDate, endDate);
      expect(task.status, TaskStatus.notStarted);
      expect(task.progress, 0);
      expect(task.memo, '');
      expect(task.bookId, '');
      expect(task.order, 0);
    });

    test('creates with all custom values', () {
      final customTask = Task(
        id: 'custom-id',
        goalId: 'goal-2',
        title: 'テスト',
        startDate: DateTime(2026, 3, 1),
        endDate: DateTime(2026, 3, 31),
        status: TaskStatus.inProgress,
        progress: 50,
        memo: 'メモ',
        bookId: 'book-1',
        order: 3,
      );
      expect(customTask.id, 'custom-id');
      expect(customTask.status, TaskStatus.inProgress);
      expect(customTask.progress, 50);
      expect(customTask.memo, 'メモ');
      expect(customTask.bookId, 'book-1');
      expect(customTask.order, 3);
    });

    group('validation', () {
      test('throws on negative progress', () {
        expect(
          () => Task(
            goalId: 'g1',
            title: 'test',
            startDate: startDate,
            endDate: endDate,
            progress: -1,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws on progress over 100', () {
        expect(
          () => Task(
            goalId: 'g1',
            title: 'test',
            startDate: startDate,
            endDate: endDate,
            progress: 101,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('allows progress of 0', () {
        final t = Task(
          goalId: 'g1',
          title: 'test',
          startDate: startDate,
          endDate: endDate,
          progress: 0,
        );
        expect(t.progress, 0);
      });

      test('allows progress of 100', () {
        final t = Task(
          goalId: 'g1',
          title: 'test',
          startDate: startDate,
          endDate: endDate,
          progress: 100,
        );
        expect(t.progress, 100);
      });

      test('throws when endDate is before startDate', () {
        expect(
          () => Task(
            goalId: 'g1',
            title: 'test',
            startDate: DateTime(2026, 2, 1),
            endDate: DateTime(2026, 1, 1),
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('allows same start and end date', () {
        final t = Task(
          goalId: 'g1',
          title: 'test',
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 1, 1),
        );
        expect(t.durationDays, 1);
      });
    });

    group('durationDays', () {
      test('calculates correct duration', () {
        expect(task.durationDays, 31);
      });

      test('single day task has duration 1', () {
        final singleDay = Task(
          goalId: 'g1',
          title: 'test',
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 1, 1),
        );
        expect(singleDay.durationDays, 1);
      });
    });

    group('copyWith', () {
      test('copies with changed fields', () {
        final copied = task.copyWith(
          title: '新タイトル',
          progress: 75,
          status: TaskStatus.completed,
        );
        expect(copied.title, '新タイトル');
        expect(copied.progress, 75);
        expect(copied.status, TaskStatus.completed);
        expect(copied.id, task.id);
        expect(copied.goalId, task.goalId);
      });
    });

    group('toMap / fromMap', () {
      test('round-trip serialization', () {
        final fullTask = Task(
          id: 'test-id',
          goalId: 'goal-1',
          title: 'テスト',
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 1, 31),
          status: TaskStatus.inProgress,
          progress: 50,
          memo: 'メモ',
          bookId: 'book-1',
          order: 2,
          createdAt: DateTime(2026, 1, 1, 10, 0),
          updatedAt: DateTime(2026, 1, 15, 12, 30),
        );
        final map = fullTask.toMap();
        final restored = Task.fromMap(map);
        expect(restored.id, fullTask.id);
        expect(restored.goalId, fullTask.goalId);
        expect(restored.title, fullTask.title);
        expect(restored.status, fullTask.status);
        expect(restored.progress, fullTask.progress);
        expect(restored.memo, fullTask.memo);
        expect(restored.bookId, fullTask.bookId);
        expect(restored.order, fullTask.order);
      });

      test('toMap stores status as string', () {
        final map = task.toMap();
        expect(map['status'], 'not_started');
      });

      test('fromMap handles missing optional fields', () {
        final map = {
          'id': 'test-id',
          'goal_id': 'g1',
          'title': 'test',
          'start_date': '2026-01-01T00:00:00.000',
          'end_date': '2026-01-31T00:00:00.000',
          'status': 'not_started',
          'progress': 0,
          'created_at': '2026-01-01T00:00:00.000',
          'updated_at': '2026-01-01T00:00:00.000',
        };
        final restored = Task.fromMap(map);
        expect(restored.memo, '');
        expect(restored.bookId, '');
        expect(restored.order, 0);
      });
    });

    group('equality', () {
      test('equal when same id', () {
        final task1 = Task(
          id: 'same-id',
          goalId: 'g1',
          title: 'A',
          startDate: startDate,
          endDate: endDate,
        );
        final task2 = Task(
          id: 'same-id',
          goalId: 'g2',
          title: 'B',
          startDate: startDate,
          endDate: endDate,
        );
        expect(task1, equals(task2));
      });

      test('not equal when different id', () {
        final task1 = Task(
          id: 'id-1',
          goalId: 'g1',
          title: 'A',
          startDate: startDate,
          endDate: endDate,
        );
        final task2 = Task(
          id: 'id-2',
          goalId: 'g1',
          title: 'A',
          startDate: startDate,
          endDate: endDate,
        );
        expect(task1, isNot(equals(task2)));
      });
    });

    test('toString contains id and title', () {
      final str = task.toString();
      expect(str, contains(task.id));
      expect(str, contains(task.title));
    });
  });
}
