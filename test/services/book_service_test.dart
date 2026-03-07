import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yume_log/database/app_database.dart' hide Book;
import 'package:yume_log/models/book.dart';
import 'package:yume_log/models/task.dart' show bookGanttGoalId;
import 'package:yume_log/services/book_service.dart';

AppDatabase _createDb() => AppDatabase(NativeDatabase.memory());

void main() {
  late AppDatabase db;
  late BookService service;

  setUp(() async {
    db = _createDb();
    service = BookService(bookDao: db.bookDao, taskDao: db.taskDao);
  });

  tearDown(() => db.close());

  group('BookService', () {
    group('createBook', () {
      test('書籍を作成する', () async {
        final book = await service.createBook('テスト書籍');
        expect(book.title, 'テスト書籍');
        expect(book.status, BookStatus.unread);
      });

      test('タイトルの前後空白をトリムする', () async {
        final book = await service.createBook('  テスト書籍  ');
        expect(book.title, 'テスト書籍');
      });

      test('空タイトルでArgumentError', () async {
        expect(
          () => service.createBook(''),
          throwsArgumentError,
        );
      });

      test('空白のみでArgumentError', () async {
        expect(
          () => service.createBook('   '),
          throwsArgumentError,
        );
      });
    });

    group('getAllBooks', () {
      test('全書籍を取得する', () async {
        await service.createBook('Book 1');
        await service.createBook('Book 2');
        final books = await service.getAllBooks();
        expect(books.length, 2);
      });
    });

    group('getBook', () {
      test('IDで取得', () async {
        final created = await service.createBook('Test');
        final found = await service.getBook(created.id);
        expect(found, isNotNull);
        expect(found!.title, 'Test');
      });

      test('存在しないIDでnull', () async {
        final found = await service.getBook('nonexistent');
        expect(found, isNull);
      });
    });

    group('updateStatus', () {
      test('ステータスを更新する', () async {
        final book = await service.createBook('Test');
        final updated = await service.updateStatus(
          book.id,
          BookStatus.reading,
        );
        expect(updated!.status, BookStatus.reading);
      });

      test('存在しないIDでnull', () async {
        final result = await service.updateStatus(
          'nonexistent',
          BookStatus.reading,
        );
        expect(result, isNull);
      });
    });

    group('completeBook', () {
      test('書籍を読了にする', () async {
        final book = await service.createBook('Test');
        final completed = await service.completeBook(
          bookId: book.id,
          summary: 'テスト要約',
          impressions: 'テスト感想',
        );
        expect(completed!.status, BookStatus.completed);
        expect(completed.summary, 'テスト要約');
        expect(completed.impressions, 'テスト感想');
        expect(completed.progress, 100);
        expect(completed.completedDate, isNotNull);
      });

      test('カスタム読了日', () async {
        final book = await service.createBook('Test');
        final date = DateTime(2025, 3, 1);
        final completed = await service.completeBook(
          bookId: book.id,
          summary: '要約',
          impressions: '感想',
          completedDate: date,
        );
        expect(completed!.completedDate, date);
      });

      test('存在しないIDでnull', () async {
        final result = await service.completeBook(
          bookId: 'nonexistent',
          summary: '要約',
          impressions: '感想',
        );
        expect(result, isNull);
      });
    });

    group('deleteBook', () {
      test('書籍を削除する', () async {
        final book = await service.createBook('Test');
        final deleted = await service.deleteBook(book.id);
        expect(deleted, isTrue);
        final remaining = await service.getAllBooks();
        expect(remaining, isEmpty);
      });

      test('書籍ガントタスクはカスケード削除', () async {
        final book = await service.createBook('Test');
        // 書籍ガント用タスクを作成
        await db.goalDao.insertGoal(
          GoalsCompanion(
            id: Value(bookGanttGoalId),
            dreamId: const Value('dream-1'),
            why: const Value('book gantt'),
            whenTarget: const Value(''),
            whenType: const Value('period'),
            what: const Value('book gantt'),
            how: const Value('book gantt'),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ),
        );
        await db.taskDao.insertTask(
          TasksCompanion(
            id: const Value('book-task-1'),
            goalId: Value(bookGanttGoalId),
            title: const Value('Book Task'),
            startDate: Value(DateTime(2025, 3, 1)),
            endDate: Value(DateTime(2025, 3, 31)),
            bookId: Value(book.id),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ),
        );
        await service.deleteBook(book.id);
        final task = await db.taskDao.getById('book-task-1');
        expect(task, isNull);
      });
    });

    group('getBookshelfData', () {
      test('本棚データを取得する', () async {
        await service.createBook('Book 1');
        final book2 = await service.createBook('Book 2');
        await service.completeBook(
          bookId: book2.id,
          summary: '要約',
          impressions: '感想',
        );
        final data = await service.getBookshelfData();
        expect(data.totalCount, 2);
        expect(data.completedCount, 1);
        expect(data.recentCompleted.length, 1);
      });
    });

    group('updateBook', () {
      test('書籍を更新する', () async {
        final book = await service.createBook('テスト書籍');
        final updated = book.copyWith(title: '更新後タイトル');
        final result = await service.updateBook(updated);
        expect(result, isNotNull);
        expect(result!.title, '更新後タイトル');
        // Verify persistence
        final fetched = await service.getBook(book.id);
        expect(fetched!.title, '更新後タイトル');
      });

      test('存在しないIDでnull', () async {
        final book = Book(id: 'nonexistent', title: 'テスト');
        final result = await service.updateBook(book);
        expect(result, isNull);
      });
    });
  });
}
