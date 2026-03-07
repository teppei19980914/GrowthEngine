import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yume_log/database/app_database.dart' hide Book;
import 'package:yume_log/models/book.dart';
import 'package:yume_log/models/task.dart';
import 'package:yume_log/services/book_gantt_service.dart';
import 'package:yume_log/services/book_service.dart';
import 'package:yume_log/services/task_service.dart';

AppDatabase _createDb() => AppDatabase(NativeDatabase.memory());

void main() {
  late AppDatabase db;
  late BookService bookService;
  late TaskService taskService;
  late BookGanttService service;

  setUp(() async {
    db = _createDb();
    bookService = BookService(bookDao: db.bookDao, taskDao: db.taskDao);
    taskService = TaskService(taskDao: db.taskDao);
    service = BookGanttService(bookService: bookService, taskService: taskService);

    // Create the __books__ goal for task creation
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
  });

  tearDown(() => db.close());

  group('BookGanttService', () {
    group('getScheduledBooks', () {
      test('スケジュール付き書籍のみ返す', () async {
        final book1 = await bookService.createBook('Book 1');
        await bookService.createBook('Book 2'); // no schedule

        // book1にスケジュールを設定
        final updated = book1.copyWith(
          startDate: DateTime(2025, 3, 1),
          endDate: DateTime(2025, 3, 31),
        );
        await db.bookDao.updateBook(BooksCompanion(
              id: Value(updated.id),
              startDate: Value(updated.startDate),
              endDate: Value(updated.endDate),
            ));

        final scheduled = await service.getScheduledBooks();
        expect(scheduled.length, 1);
        expect(scheduled.first.title, 'Book 1');
      });
    });

    group('getUnscheduledBooks', () {
      test('スケジュールなし書籍のみ返す', () async {
        await bookService.createBook('Book 1'); // no schedule
        final book2 = await bookService.createBook('Book 2');
        final updated = book2.copyWith(
          startDate: DateTime(2025, 3, 1),
          endDate: DateTime(2025, 3, 31),
        );
        await db.bookDao.updateBook(BooksCompanion(
              id: Value(updated.id),
              startDate: Value(updated.startDate),
              endDate: Value(updated.endDate),
            ));

        final unscheduled = await service.getUnscheduledBooks();
        expect(unscheduled.length, 1);
        expect(unscheduled.first.title, 'Book 1');
      });
    });

    group('booksToTasks', () {
      test('スケジュール付き書籍をTaskに変換する', () {
        final books = [
          Book(
            title: 'Test Book',
            status: BookStatus.reading,
            startDate: DateTime(2025, 3, 1),
            endDate: DateTime(2025, 3, 31),
            progress: 50,
          ),
        ];
        final tasks = service.booksToTasks(books);
        expect(tasks.length, 1);
        expect(tasks.first.goalId, bookGanttGoalId);
        expect(tasks.first.status, TaskStatus.inProgress);
        expect(tasks.first.progress, 50);
      });

      test('スケジュールなし書籍は除外する', () {
        final books = [
          Book(title: 'No Schedule'),
        ];
        final tasks = service.booksToTasks(books);
        expect(tasks, isEmpty);
      });
    });

    group('ステータス変換', () {
      test('BookStatus→TaskStatus', () {
        expect(
          BookGanttService.bookStatusToTaskStatus(BookStatus.unread),
          TaskStatus.notStarted,
        );
        expect(
          BookGanttService.bookStatusToTaskStatus(BookStatus.reading),
          TaskStatus.inProgress,
        );
        expect(
          BookGanttService.bookStatusToTaskStatus(BookStatus.completed),
          TaskStatus.completed,
        );
      });

      test('TaskStatus→BookStatus', () {
        expect(
          BookGanttService.taskStatusToBookStatus(TaskStatus.notStarted),
          BookStatus.unread,
        );
        expect(
          BookGanttService.taskStatusToBookStatus(TaskStatus.inProgress),
          BookStatus.reading,
        );
        expect(
          BookGanttService.taskStatusToBookStatus(TaskStatus.completed),
          BookStatus.completed,
        );
      });
    });

    group('createBookWithSchedule', () {
      test('スケジュール付き書籍を作成する', () async {
        final book = await service.createBookWithSchedule(
          title: 'New Book',
          startDate: DateTime(2025, 3, 1),
          endDate: DateTime(2025, 3, 31),
        );
        expect(book.title, 'New Book');
        expect(book.startDate, DateTime(2025, 3, 1));
        expect(book.endDate, DateTime(2025, 3, 31));
        expect(book.status, BookStatus.reading);
      });

      test('終了日<開始日でArgumentError', () async {
        expect(
          () => service.createBookWithSchedule(
            title: 'Book',
            startDate: DateTime(2025, 4, 1),
            endDate: DateTime(2025, 3, 1),
          ),
          throwsArgumentError,
        );
      });
    });

    group('updateBookSchedule', () {
      test('スケジュールを更新する', () async {
        final book = await bookService.createBook('Test');
        final updated = await service.updateBookSchedule(
          bookId: book.id,
          title: 'Updated',
          startDate: DateTime(2025, 3, 1),
          endDate: DateTime(2025, 3, 31),
          progress: 50,
        );
        expect(updated, isNotNull);
        expect(updated!.title, 'Updated');
        expect(updated.progress, 50);
        expect(updated.status, BookStatus.reading);
      });

      test('進捗100%で読了', () async {
        final book = await bookService.createBook('Test');
        final updated = await service.updateBookSchedule(
          bookId: book.id,
          title: 'Test',
          startDate: DateTime(2025, 3, 1),
          endDate: DateTime(2025, 3, 31),
          progress: 100,
        );
        expect(updated!.status, BookStatus.completed);
      });

      test('進捗0%で未読', () async {
        final book = await bookService.createBook('Test');
        final updated = await service.updateBookSchedule(
          bookId: book.id,
          title: 'Test',
          startDate: DateTime(2025, 3, 1),
          endDate: DateTime(2025, 3, 31),
          progress: 0,
        );
        expect(updated!.status, BookStatus.unread);
      });

      test('空タイトルでArgumentError', () async {
        final book = await bookService.createBook('Test');
        expect(
          () => service.updateBookSchedule(
            bookId: book.id,
            title: '',
            startDate: DateTime(2025, 3, 1),
            endDate: DateTime(2025, 3, 31),
            progress: 0,
          ),
          throwsArgumentError,
        );
      });

      test('無効な進捗でArgumentError', () async {
        final book = await bookService.createBook('Test');
        expect(
          () => service.updateBookSchedule(
            bookId: book.id,
            title: 'Test',
            startDate: DateTime(2025, 3, 1),
            endDate: DateTime(2025, 3, 31),
            progress: 101,
          ),
          throwsArgumentError,
        );
      });

      test('存在しないIDでnull', () async {
        final result = await service.updateBookSchedule(
          bookId: 'nonexistent',
          title: 'Test',
          startDate: DateTime(2025, 3, 1),
          endDate: DateTime(2025, 3, 31),
          progress: 0,
        );
        expect(result, isNull);
      });
    });

    group('setBookSchedule', () {
      test('既存書籍にスケジュールを設定する', () async {
        final book = await bookService.createBook('テスト書籍');
        final result = await service.setBookSchedule(
          bookId: book.id,
          startDate: DateTime(2025, 4, 1),
          endDate: DateTime(2025, 4, 30),
        );
        expect(result, isNotNull);
        expect(result!.startDate, DateTime(2025, 4, 1));
        expect(result.endDate, DateTime(2025, 4, 30));
        // Verify persistence
        final fetched = await bookService.getBook(book.id);
        expect(fetched!.startDate, DateTime(2025, 4, 1));
      });

      test('存在しないIDでnull', () async {
        final result = await service.setBookSchedule(
          bookId: 'nonexistent',
          startDate: DateTime(2025, 4, 1),
          endDate: DateTime(2025, 4, 30),
        );
        expect(result, isNull);
      });

      test('終了日<開始日でArgumentError', () async {
        expect(
          () => service.setBookSchedule(
            bookId: 'any',
            startDate: DateTime(2025, 5, 1),
            endDate: DateTime(2025, 4, 1),
          ),
          throwsArgumentError,
        );
      });
    });

    group('clearBookSchedule', () {
      test('スケジュールをクリアする', () async {
        final book = await service.createBookWithSchedule(
          title: 'テスト',
          startDate: DateTime(2025, 4, 1),
          endDate: DateTime(2025, 4, 30),
        );
        final cleared = await service.clearBookSchedule(book.id);
        expect(cleared, isNotNull);
        expect(cleared!.startDate, isNull);
        expect(cleared.endDate, isNull);
        expect(cleared.progress, 0);
        // Verify persistence
        final fetched = await bookService.getBook(book.id);
        expect(fetched!.startDate, isNull);
      });

      test('存在しないIDでnull', () async {
        final result = await service.clearBookSchedule('nonexistent');
        expect(result, isNull);
      });
    });

    group('syncBookProgress', () {
      test('タスクの進捗平均を書籍に同期する', () async {
        final book = await service.createBookWithSchedule(
          title: 'テスト',
          startDate: DateTime(2025, 4, 1),
          endDate: DateTime(2025, 4, 30),
        );
        // Create tasks linked to this book
        await taskService.createTask(
          goalId: '__books__',
          title: 'Task1',
          startDate: DateTime(2025, 4, 1),
          endDate: DateTime(2025, 4, 15),
          bookId: book.id,
        );
        final t2 = await taskService.createTask(
          goalId: '__books__',
          title: 'Task2',
          startDate: DateTime(2025, 4, 10),
          endDate: DateTime(2025, 4, 30),
          bookId: book.id,
        );
        // Update progress
        await taskService.updateProgress(t2.id, 80);

        await service.syncBookProgress(book.id);
        final synced = await bookService.getBook(book.id);
        expect(synced!.progress, 40); // avg of 0 and 80
      });

      test('タスク0件でprogress=0・日付null', () async {
        final book = await service.createBookWithSchedule(
          title: 'テスト',
          startDate: DateTime(2025, 4, 1),
          endDate: DateTime(2025, 4, 30),
        );
        await service.syncBookProgress(book.id);
        final synced = await bookService.getBook(book.id);
        expect(synced!.progress, 0);
        expect(synced.startDate, isNull);
      });

      test('taskService未設定で何もしない', () async {
        final noTaskService = BookGanttService(bookService: bookService);
        final book = await bookService.createBook('テスト');
        // Should not throw
        await noTaskService.syncBookProgress(book.id);
      });
    });

    group('getAllBookTasks', () {
      test('bookGanttGoalIdのタスクを返す', () async {
        await taskService.createTask(
          goalId: '__books__',
          title: 'Book Task',
          startDate: DateTime(2025, 4, 1),
          endDate: DateTime(2025, 4, 30),
        );
        final tasks = await service.getAllBookTasks();
        expect(tasks.length, greaterThanOrEqualTo(1));
        expect(tasks.first.goalId, '__books__');
      });

      test('taskService未設定で空リスト', () async {
        final noTaskService = BookGanttService(bookService: bookService);
        final tasks = await noTaskService.getAllBookTasks();
        expect(tasks, isEmpty);
      });
    });

    group('createBookWithSchedule (persistence)', () {
      test('DBに永続化される', () async {
        final created = await service.createBookWithSchedule(
          title: '永続化テスト',
          startDate: DateTime(2025, 5, 1),
          endDate: DateTime(2025, 5, 31),
        );
        final fetched = await bookService.getBook(created.id);
        expect(fetched, isNotNull);
        expect(fetched!.startDate, DateTime(2025, 5, 1));
        expect(fetched.endDate, DateTime(2025, 5, 31));
        expect(fetched.status, BookStatus.reading);
      });
    });

    group('updateBookSchedule (persistence)', () {
      test('DBに永続化される', () async {
        final book = await service.createBookWithSchedule(
          title: 'テスト',
          startDate: DateTime(2025, 5, 1),
          endDate: DateTime(2025, 5, 31),
        );
        await service.updateBookSchedule(
          bookId: book.id,
          title: '更新後',
          startDate: DateTime(2025, 6, 1),
          endDate: DateTime(2025, 6, 30),
          progress: 50,
        );
        final fetched = await bookService.getBook(book.id);
        expect(fetched!.title, '更新後');
        expect(fetched.startDate, DateTime(2025, 6, 1));
        expect(fetched.progress, 50);
        expect(fetched.status, BookStatus.reading);
      });
    });
  });
}
