import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:yume_log/database/app_database.dart';
import 'package:yume_log/database/daos/book_dao.dart';

import 'test_database.dart';

void main() {
  late AppDatabase db;
  late BookDao dao;

  setUp(() {
    db = createTestDatabase();
    dao = BookDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  BooksCompanion createBook({
    String id = 'book-1',
    String title = 'テスト書籍',
    String status = 'unread',
    String summary = '',
    String impressions = '',
    int progress = 0,
  }) {
    return BooksCompanion(
      id: Value(id),
      title: Value(title),
      status: Value(status),
      summary: Value(summary),
      impressions: Value(impressions),
      progress: Value(progress),
      createdAt: Value(DateTime(2026, 1, 1)),
      updatedAt: Value(DateTime(2026, 1, 1)),
    );
  }

  group('BookDao', () {
    test('insert and getAll', () async {
      await dao.insertBook(createBook());
      final books = await dao.getAll();
      expect(books.length, 1);
      expect(books[0].title, 'テスト書籍');
    });

    test('getAll returns empty list initially', () async {
      final books = await dao.getAll();
      expect(books, isEmpty);
    });

    test('getById returns book', () async {
      await dao.insertBook(createBook(id: 'book-1'));
      final book = await dao.getById('book-1');
      expect(book, isNotNull);
      expect(book!.id, 'book-1');
    });

    test('getById returns null when not found', () async {
      final book = await dao.getById('nonexistent');
      expect(book, isNull);
    });

    test('insert with nullable dates', () async {
      await dao.insertBook(createBook(id: 'book-1'));
      final book = await dao.getById('book-1');
      expect(book!.completedDate, isNull);
      expect(book.startDate, isNull);
      expect(book.endDate, isNull);
    });

    test('insert with dates', () async {
      await dao.insertBook(
        BooksCompanion(
          id: const Value('book-1'),
          title: const Value('テスト'),
          status: const Value('reading'),
          summary: const Value(''),
          impressions: const Value(''),
          startDate: Value(DateTime(2026, 1, 1)),
          endDate: Value(DateTime(2026, 3, 31)),
          progress: const Value(50),
          createdAt: Value(DateTime(2026, 1, 1)),
          updatedAt: Value(DateTime(2026, 1, 1)),
        ),
      );
      final book = await dao.getById('book-1');
      expect(book!.startDate, isNotNull);
      expect(book.endDate, isNotNull);
      expect(book.progress, 50);
    });

    test('updateBook updates fields', () async {
      await dao.insertBook(createBook(id: 'book-1'));
      final updated = await dao.updateBook(
        BooksCompanion(
          id: const Value('book-1'),
          title: const Value('更新書籍'),
          status: const Value('completed'),
          progress: const Value(100),
          completedDate: Value(DateTime(2026, 3, 1)),
          updatedAt: Value(DateTime(2026, 3, 1)),
        ),
      );
      expect(updated, isTrue);
      final book = await dao.getById('book-1');
      expect(book!.title, '更新書籍');
      expect(book.status, 'completed');
      expect(book.progress, 100);
      expect(book.completedDate, isNotNull);
    });

    test('updateBook returns false when not found', () async {
      final updated = await dao.updateBook(
        const BooksCompanion(
          id: Value('nonexistent'),
          title: Value('test'),
        ),
      );
      expect(updated, isFalse);
    });

    test('deleteById removes book', () async {
      await dao.insertBook(createBook(id: 'book-1'));
      final deleted = await dao.deleteById('book-1');
      expect(deleted, isTrue);
      final books = await dao.getAll();
      expect(books, isEmpty);
    });

    test('deleteById returns false when not found', () async {
      final deleted = await dao.deleteById('nonexistent');
      expect(deleted, isFalse);
    });
  });
}
