/// 書籍管理のビジネスロジック.
library;

import 'package:drift/drift.dart';

import '../database/app_database.dart' as db;
import '../database/daos/book_dao.dart';
import '../database/daos/task_dao.dart';
import '../models/book.dart';
import '../models/task.dart' show bookGanttGoalId;
import 'study_stats_types.dart';

/// BookのCRUD操作とビジネスロジックを提供するサービス.
class BookService {
  /// BookServiceを作成する.
  BookService({required BookDao bookDao, required TaskDao taskDao})
      : _bookDao = bookDao,
        _taskDao = taskDao;

  final BookDao _bookDao;
  final TaskDao _taskDao;

  /// 全Bookを取得する.
  Future<List<Book>> getAllBooks() async {
    final rows = await _bookDao.getAll();
    return rows.map(_rowToBook).toList();
  }

  /// IDでBookを取得する.
  Future<Book?> getBook(String bookId) async {
    final row = await _bookDao.getById(bookId);
    return row != null ? _rowToBook(row) : null;
  }

  /// Bookを作成する.
  Future<Book> createBook(
    String title, {
    BookCategory category = BookCategory.other,
    String why = '',
    String description = '',
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) throw ArgumentError('書籍名は必須です');
    final book = Book(
      title: trimmed,
      category: category,
      why: why,
      description: description,
    );
    await _bookDao.insertBook(_bookToCompanion(book));
    return book;
  }

  /// 書籍の基本情報を更新する.
  Future<Book?> updateBookInfo(
    String bookId, {
    required String title,
    required BookCategory category,
    required String why,
    required String description,
  }) async {
    final existing = await _bookDao.getById(bookId);
    if (existing == null) return null;
    final updated = _rowToBook(existing).copyWith(
      title: title,
      category: category,
      why: why,
      description: description,
      updatedAt: DateTime.now(),
    );
    await _bookDao.updateBook(_bookToCompanion(updated));
    return updated;
  }

  /// 書籍のステータスを更新する.
  Future<Book?> updateStatus(String bookId, BookStatus status) async {
    final existing = await _bookDao.getById(bookId);
    if (existing == null) return null;
    final updated = _rowToBook(existing).copyWith(
      status: status,
      updatedAt: DateTime.now(),
    );
    await _bookDao.updateBook(_bookToCompanion(updated));
    return updated;
  }

  /// 書籍を読了にする.
  Future<Book?> completeBook({
    required String bookId,
    required String summary,
    required String impressions,
    DateTime? completedDate,
  }) async {
    final existing = await _bookDao.getById(bookId);
    if (existing == null) return null;
    final updated = _rowToBook(existing).copyWith(
      status: BookStatus.completed,
      summary: summary,
      impressions: impressions,
      completedDate: completedDate ?? DateTime.now(),
      progress: 100,
      updatedAt: DateTime.now(),
    );
    await _bookDao.updateBook(_bookToCompanion(updated));
    return updated;
  }

  /// 書籍を更新する（全フィールド）.
  Future<Book?> updateBook(Book book) async {
    final existing = await _bookDao.getById(book.id);
    if (existing == null) return null;
    await _bookDao.updateBook(_bookToCompanion(book));
    return book;
  }

  /// 書籍を削除する.
  ///
  /// 書籍ガント用タスク（goalId == bookGanttGoalId）は完全に削除し、
  /// 他のタスクからはbookIdをクリアする.
  Future<bool> deleteBook(String bookId) async {
    final allTasks = await _taskDao.getAll();
    for (final task in allTasks) {
      if (task.bookId == bookId) {
        if (task.goalId == bookGanttGoalId) {
          await _taskDao.deleteById(task.id);
        } else {
          await _taskDao.updateTask(
            db.TasksCompanion(
              id: Value(task.id),
              bookId: const Value(''),
              updatedAt: Value(DateTime.now()),
            ),
          );
        }
      }
    }
    return _bookDao.deleteById(bookId);
  }

  /// 本棚データを取得する.
  Future<BookshelfData> getBookshelfData() async {
    final books = await _bookDao.getAll();
    final completedBooks =
        books.where((b) => b.status == 'completed').toList();
    final readingCount = books.where((b) => b.status == 'reading').length;

    completedBooks.sort((a, b) {
      final aDate = a.completedDate ?? DateTime(1970);
      final bDate = b.completedDate ?? DateTime(1970);
      return bDate.compareTo(aDate);
    });

    final recentCompleted =
        completedBooks.take(5).map(_rowToBook).toList();

    return BookshelfData(
      totalCount: books.length,
      completedCount: completedBooks.length,
      readingCount: readingCount,
      recentCompleted: recentCompleted,
    );
  }

  Book _rowToBook(db.Book row) {
    return Book(
      id: row.id,
      title: row.title,
      status: BookStatus.fromValue(row.status),
      category: BookCategory.fromValue(row.category),
      why: row.why,
      description: row.description,
      summary: row.summary,
      impressions: row.impressions,
      completedDate: row.completedDate,
      startDate: row.startDate,
      endDate: row.endDate,
      progress: row.progress,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  db.BooksCompanion _bookToCompanion(Book book) {
    return db.BooksCompanion(
      id: Value(book.id),
      title: Value(book.title),
      status: Value(book.status.value),
      category: Value(book.category.name),
      why: Value(book.why),
      description: Value(book.description),
      summary: Value(book.summary),
      impressions: Value(book.impressions),
      completedDate: Value(book.completedDate),
      startDate: Value(book.startDate),
      endDate: Value(book.endDate),
      progress: Value(book.progress),
      createdAt: Value(book.createdAt),
      updatedAt: Value(book.updatedAt),
    );
  }
}
