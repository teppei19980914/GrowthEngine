import 'package:flutter_test/flutter_test.dart';
import 'package:yume_hashi/models/book.dart';

void main() {
  group('BookStatus', () {
    test('values have correct string values', () {
      expect(BookStatus.unread.value, 'unread');
      expect(BookStatus.reading.value, 'reading');
      expect(BookStatus.completed.value, 'completed');
    });

    test('fromValue returns correct enum', () {
      expect(BookStatus.fromValue('unread'), BookStatus.unread);
      expect(BookStatus.fromValue('reading'), BookStatus.reading);
      expect(BookStatus.fromValue('completed'), BookStatus.completed);
    });

    test('fromValue throws on invalid value', () {
      expect(
        () => BookStatus.fromValue('invalid'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('Book', () {
    late Book book;

    setUp(() {
      book = Book(title: 'Effective Dart');
    });

    test('creates with default values', () {
      expect(book.id, isNotEmpty);
      expect(book.title, 'Effective Dart');
      expect(book.status, BookStatus.unread);
      expect(book.summary, '');
      expect(book.impressions, '');
      expect(book.completedDate, isNull);
      expect(book.startDate, isNull);
      expect(book.endDate, isNull);
      expect(book.progress, 0);
      expect(book.createdAt, isNotNull);
      expect(book.updatedAt, isNotNull);
    });

    test('creates with all custom values', () {
      final customBook = Book(
        id: 'custom-id',
        title: 'Flutter実践入門',
        status: BookStatus.reading,
        summary: '要約',
        impressions: '感想',
        completedDate: DateTime(2026, 3, 1),
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 2, 28),
        progress: 75,
      );
      expect(customBook.id, 'custom-id');
      expect(customBook.status, BookStatus.reading);
      expect(customBook.summary, '要約');
      expect(customBook.impressions, '感想');
      expect(customBook.completedDate, DateTime(2026, 3, 1));
      expect(customBook.startDate, DateTime(2026, 1, 1));
      expect(customBook.endDate, DateTime(2026, 2, 28));
      expect(customBook.progress, 75);
    });

    group('validation', () {
      test('throws on empty title', () {
        expect(() => Book(title: ''), throwsA(isA<ArgumentError>()));
      });

      test('throws on whitespace-only title', () {
        expect(() => Book(title: '   '), throwsA(isA<ArgumentError>()));
      });

      test('throws on negative progress', () {
        expect(
          () => Book(title: 'test', progress: -1),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws on progress over 100', () {
        expect(
          () => Book(title: 'test', progress: 101),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('allows progress of 0 and 100', () {
        final book0 = Book(title: 'test', progress: 0);
        final book100 = Book(title: 'test', progress: 100);
        expect(book0.progress, 0);
        expect(book100.progress, 100);
      });

      test('throws when endDate is before startDate', () {
        expect(
          () => Book(
            title: 'test',
            startDate: DateTime(2026, 2, 1),
            endDate: DateTime(2026, 1, 1),
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('allows endDate equal to startDate', () {
        final b = Book(
          title: 'test',
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 1, 1),
        );
        expect(b.hasSchedule, isTrue);
      });

      test('allows startDate without endDate', () {
        final b = Book(title: 'test', startDate: DateTime(2026, 1, 1));
        expect(b.startDate, isNotNull);
        expect(b.endDate, isNull);
        expect(b.hasSchedule, isFalse);
      });

      test('allows endDate without startDate', () {
        final b = Book(title: 'test', endDate: DateTime(2026, 1, 31));
        expect(b.startDate, isNull);
        expect(b.endDate, isNotNull);
        expect(b.hasSchedule, isFalse);
      });
    });

    group('hasSchedule', () {
      test('returns false when no dates', () {
        expect(book.hasSchedule, isFalse);
      });

      test('returns true when both dates set', () {
        final scheduled = Book(
          title: 'test',
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 1, 31),
        );
        expect(scheduled.hasSchedule, isTrue);
      });
    });

    group('copyWith', () {
      test('copies with changed fields', () {
        final copied = book.copyWith(
          title: '新タイトル',
          status: BookStatus.completed,
          progress: 100,
        );
        expect(copied.title, '新タイトル');
        expect(copied.status, BookStatus.completed);
        expect(copied.progress, 100);
        expect(copied.id, book.id);
      });

      test('can clear nullable dates', () {
        final withDates = Book(
          title: 'test',
          completedDate: DateTime(2026, 1, 1),
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 1, 31),
        );
        final cleared = withDates.copyWith(
          clearCompletedDate: true,
          clearStartDate: true,
          clearEndDate: true,
        );
        expect(cleared.completedDate, isNull);
        expect(cleared.startDate, isNull);
        expect(cleared.endDate, isNull);
      });

      test('can set new dates via copyWith', () {
        final withDates = book.copyWith(
          startDate: DateTime(2026, 3, 1),
          endDate: DateTime(2026, 3, 31),
        );
        expect(withDates.startDate, DateTime(2026, 3, 1));
        expect(withDates.endDate, DateTime(2026, 3, 31));
      });
    });

    group('toMap / fromMap', () {
      test('round-trip serialization with all fields', () {
        final fullBook = Book(
          id: 'test-id',
          title: 'テスト書籍',
          status: BookStatus.completed,
          summary: '要約テスト',
          impressions: '感想テスト',
          completedDate: DateTime(2026, 3, 1),
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 2, 28),
          progress: 100,
          createdAt: DateTime(2026, 1, 1, 10, 0),
          updatedAt: DateTime(2026, 3, 1, 15, 30),
        );
        final map = fullBook.toMap();
        final restored = Book.fromMap(map);
        expect(restored.id, fullBook.id);
        expect(restored.title, fullBook.title);
        expect(restored.status, fullBook.status);
        expect(restored.summary, fullBook.summary);
        expect(restored.impressions, fullBook.impressions);
        expect(restored.progress, fullBook.progress);
      });

      test('round-trip with null dates', () {
        final map = book.toMap();
        expect(map['completed_date'], isNull);
        expect(map['start_date'], isNull);
        expect(map['end_date'], isNull);
        final restored = Book.fromMap(map);
        expect(restored.completedDate, isNull);
        expect(restored.startDate, isNull);
        expect(restored.endDate, isNull);
      });

      test('fromMap handles missing optional fields', () {
        final map = {
          'id': 'test-id',
          'title': 'test',
          'status': 'unread',
          'created_at': '2026-01-01T00:00:00.000',
          'updated_at': '2026-01-01T00:00:00.000',
        };
        final restored = Book.fromMap(map);
        expect(restored.summary, '');
        expect(restored.impressions, '');
        expect(restored.progress, 0);
      });
    });

    group('equality', () {
      test('equal when same id', () {
        final book1 = Book(id: 'same-id', title: 'Book A');
        final book2 = Book(id: 'same-id', title: 'Book B');
        expect(book1, equals(book2));
        expect(book1.hashCode, book2.hashCode);
      });

      test('not equal when different id', () {
        final book1 = Book(id: 'id-1', title: 'Same');
        final book2 = Book(id: 'id-2', title: 'Same');
        expect(book1, isNot(equals(book2)));
      });
    });

    test('toString contains id and title', () {
      final str = book.toString();
      expect(str, contains(book.id));
      expect(str, contains(book.title));
    });
  });
}
