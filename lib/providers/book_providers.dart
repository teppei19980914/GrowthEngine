/// 書籍関連のProvider定義.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_labels.dart';
import '../models/book.dart';
import '../services/sync_manager.dart';
import 'service_providers.dart';

/// 書籍のソート基準.
enum BookSortOrder {
  /// 登録日順（降順: 新しい順）.
  created(AppLabels.bookSortCreated),

  /// 更新日順（降順: 新しい順）.
  updated(AppLabels.bookSortUpdated),

  /// 50音順（昇順）.
  title(AppLabels.bookSortTitle);

  const BookSortOrder(this.label);

  /// 表示ラベル.
  final String label;
}

/// 書籍のソート基準を管理するProvider.
final bookSortOrderProvider =
    StateProvider<BookSortOrder>((_) => BookSortOrder.created);

/// ソート済みBook一覧を提供するProvider.
final sortedBookListProvider = FutureProvider<List<Book>>((ref) async {
  final books = await ref.watch(bookListProvider.future);
  final sortOrder = ref.watch(bookSortOrderProvider);
  final sorted = [...books];
  switch (sortOrder) {
    case BookSortOrder.created:
      sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    case BookSortOrder.updated:
      sorted.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    case BookSortOrder.title:
      sorted.sort((a, b) => a.title.compareTo(b.title));
  }
  return sorted;
});

/// 全Book一覧を取得・管理するProvider.
final bookListProvider =
    AsyncNotifierProvider<BookListNotifier, List<Book>>(BookListNotifier.new);

/// BookListのNotifier.
class BookListNotifier extends AsyncNotifier<List<Book>> {
  @override
  Future<List<Book>> build() async {
    final service = ref.watch(bookServiceProvider);
    return service.getAllBooks();
  }

  /// Bookを作成する.
  Future<void> createBook(
    String title, {
    BookCategory category = BookCategory.other,
    String why = '',
    String description = '',
  }) async {
    final service = ref.read(bookServiceProvider);
    await service.createBook(
      title,
      category: category,
      why: why,
      description: description,
    );
    ref.invalidateSelf();
    SyncManager().requestSync();
  }

  /// Bookの基本情報を更新する.
  Future<void> updateBookInfo(
    String bookId, {
    required String title,
    required BookCategory category,
    required String why,
    required String description,
  }) async {
    final service = ref.read(bookServiceProvider);
    await service.updateBookInfo(
      bookId,
      title: title,
      category: category,
      why: why,
      description: description,
    );
    ref.invalidateSelf();
    SyncManager().requestSync();
  }

  /// Bookの基本情報とステータスを一括更新する.
  Future<void> updateBookInfoAndStatus(
    String bookId, {
    required String title,
    required BookCategory category,
    required String why,
    required String description,
    BookStatus? status,
  }) async {
    final service = ref.read(bookServiceProvider);
    await service.updateBookInfoAndStatus(
      bookId,
      title: title,
      category: category,
      why: why,
      description: description,
      status: status,
    );
    ref.invalidateSelf();
    SyncManager().requestSync();
  }

  /// Bookのステータスを更新する.
  Future<void> updateStatus(String bookId, BookStatus status) async {
    final service = ref.read(bookServiceProvider);
    await service.updateStatus(bookId, status);
    ref.invalidateSelf();
    SyncManager().requestSync();
  }

  /// Bookを読了にする.
  Future<void> completeBook({
    required String bookId,
    required String summary,
    required String impressions,
    DateTime? completedDate,
  }) async {
    final service = ref.read(bookServiceProvider);
    await service.completeBook(
      bookId: bookId,
      summary: summary,
      impressions: impressions,
      completedDate: completedDate,
    );
    ref.invalidateSelf();
    SyncManager().requestSync();
  }

  /// Bookを削除する.
  Future<void> deleteBook(String bookId) async {
    final service = ref.read(bookServiceProvider);
    await service.deleteBook(bookId);
    ref.invalidateSelf();
    SyncManager().requestSync();
  }
}
