/// 書籍ページ.
///
/// 書籍一覧の表示、追加、ステータス変更、読了レビュー、削除を提供する.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../dialogs/book_review_dialog.dart';
import '../dialogs/book_schedule_dialog.dart';
import '../dialogs/trial_limit_dialog.dart';
import '../models/book.dart';
import '../providers/book_providers.dart';
import '../providers/service_providers.dart';
import '../services/trial_limit_service.dart';
import '../theme/app_theme.dart';


/// 書籍ページ.
class BookPage extends ConsumerStatefulWidget {
  /// BookPageを作成する.
  const BookPage({super.key});

  @override
  ConsumerState<BookPage> createState() => _BookPageState();
}

class _BookPageState extends ConsumerState<BookPage> {
  final _titleController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _addBook() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final books = await ref.read(bookListProvider.future);
    final currentCount = books.length;
    final level = ref.read(unlockLevelProvider);
    if (!canAddBook(currentCount: currentCount, unlockLevel: level)) {
      if (!mounted) return;
      await showTrialLimitDialog(
        context,
        itemName: '書籍',
        currentCount: currentCount,
        maxCount: maxBooks(level),
        feedbackService: ref.read(feedbackServiceProvider),
      );
      ref.invalidate(feedbackServiceProvider);
      return;
    }

    await ref.read(bookListProvider.notifier).createBook(title);
    _titleController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(bookListProvider);
    final theme = Theme.of(context);
    final colors = theme.appColors;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 書籍追加フォーム
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: '書籍名を入力...',
                    prefixIcon: Icon(Icons.menu_book_outlined, size: 20),
                  ),
                  onSubmitted: (_) => _addBook(),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _addBook,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('追加'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 書籍リスト
          Expanded(
            child: booksAsync.when(
              data: (books) => books.isEmpty
                  ? _buildEmptyState(theme, colors)
                  : ListView.separated(
                      itemCount: books.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, index) =>
                          _BookListItem(book: books[index]),
                    ),
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text('エラーが発生しました: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, AppColors colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.menu_book_outlined, size: 64, color: colors.textMuted),
          const SizedBox(height: 16),
          Text(
            '書籍がまだありません',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '上のフォームから書籍を追加しましょう',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// 書籍リストアイテム.
class _BookListItem extends ConsumerWidget {
  const _BookListItem({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.appColors;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // ステータスバッジ
            _StatusBadge(status: book.status),
            const SizedBox(width: 12),

            // 書籍情報
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(book.title, style: theme.textTheme.titleMedium),
                  if (book.status == BookStatus.completed &&
                      book.completedDate != null)
                    Text(
                      '読了: ${DateFormat('yyyy/MM/dd').format(book.completedDate!)}',
                      style: theme.textTheme.labelSmall,
                    ),
                  if (book.summary.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        book.summary,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),

            // アクションボタン
            ..._buildActions(context, ref, book, colors),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActions(
    BuildContext context,
    WidgetRef ref,
    Book book,
    AppColors colors,
  ) {
    final actions = <Widget>[];

    if (book.status == BookStatus.unread) {
      actions.add(
        IconButton(
          icon: const Icon(Icons.play_arrow_outlined, size: 20),
          onPressed: () => ref
              .read(bookListProvider.notifier)
              .updateStatus(book.id, BookStatus.reading),
          tooltip: '読書開始',
        ),
      );
    }

    if (book.status == BookStatus.reading) {
      actions.add(
        IconButton(
          icon: Icon(Icons.check_circle_outline, size: 20, color: colors.success),
          onPressed: () => _completeBook(context, ref, book),
          tooltip: '読了',
        ),
      );
    }

    actions.add(
      IconButton(
        icon: const Icon(Icons.calendar_month_outlined, size: 20),
        onPressed: () => _openSchedule(context, ref, book),
        tooltip: 'スケジュール',
      ),
    );

    actions.add(
      IconButton(
        icon: Icon(Icons.delete_outline, size: 20, color: colors.error),
        onPressed: () => _deleteBook(context, ref, book),
        tooltip: '削除',
      ),
    );

    return actions;
  }

  Future<void> _completeBook(
    BuildContext context,
    WidgetRef ref,
    Book book,
  ) async {
    final result = await showBookReviewDialog(
      context,
      bookTitle: book.title,
    );
    if (result == null) return;

    await ref.read(bookListProvider.notifier).completeBook(
          bookId: book.id,
          summary: result.summary,
          impressions: result.impressions,
          completedDate: result.completedDate,
        );
  }

  Future<void> _openSchedule(
    BuildContext context,
    WidgetRef ref,
    Book book,
  ) async {
    final result = await showBookScheduleDialog(context, book: book);
    if (result == null) return;

    final ganttService = ref.read(bookGanttServiceProvider);
    if (result.deleteRequested) {
      await ganttService.clearBookSchedule(book.id);
    } else {
      if (book.hasSchedule) {
        await ganttService.updateBookSchedule(
          bookId: book.id,
          title: result.title,
          startDate: result.startDate,
          endDate: result.endDate,
          progress: result.progress,
        );
      } else {
        await ganttService.setBookSchedule(
          bookId: book.id,
          startDate: result.startDate,
          endDate: result.endDate,
        );
      }
    }
    ref.invalidate(bookListProvider);
  }

  Future<void> _deleteBook(
    BuildContext context,
    WidgetRef ref,
    Book book,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('書籍を削除'),
        content: Text('「${book.title}」を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(bookListProvider.notifier).deleteBook(book.id);
  }
}

/// ステータスバッジ.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final BookStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;

    final (label, color) = switch (status) {
      BookStatus.unread => ('未読', colors.textMuted),
      BookStatus.reading => ('読書中', colors.accent),
      BookStatus.completed => ('読了', colors.success),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
