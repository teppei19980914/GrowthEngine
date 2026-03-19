/// 書籍ページ.
///
/// 書籍一覧の表示、追加、ステータス変更、読了レビュー、削除を提供する.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../dialogs/book_review_dialog.dart';
import '../dialogs/book_schedule_dialog.dart';
import '../dialogs/reading_log_dialog.dart';
import '../dialogs/trial_limit_dialog.dart';
import '../models/book.dart';
import '../providers/book_providers.dart';
import '../providers/dashboard_providers.dart';
import '../providers/service_providers.dart';
import '../services/task_study_log_logic.dart';
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

          // 本棚
          Expanded(
            child: booksAsync.when(
              data: (books) => books.isEmpty
                  ? _buildEmptyState(theme, colors)
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        // 本の幅50 + 左右padding2 = 52px per book
                        final booksPerShelf =
                            ((constraints.maxWidth - 8) / 52)
                                .floor()
                                .clamp(2, 20);
                        return _Bookshelf(
                          books: books,
                          booksPerShelf: booksPerShelf,
                        );
                      },
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
            '最初の一冊を登録しよう',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '上のフォームから書籍を登録できます',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}


/// 本棚風の書籍カバーウィジェット.
/// 本棚全体（棚段ごとに本を配置）.
class _Bookshelf extends StatelessWidget {
  const _Bookshelf({required this.books, required this.booksPerShelf});

  final List<Book> books;
  final int booksPerShelf;

  @override
  Widget build(BuildContext context) {
    // 棚段に分割
    final shelves = <List<Book>>[];
    for (var i = 0; i < books.length; i += booksPerShelf) {
      final end = (i + booksPerShelf).clamp(0, books.length);
      shelves.add(books.sublist(i, end));
    }

    return ListView.builder(
      itemCount: shelves.length,
      itemBuilder: (_, index) => _ShelfRow(
        books: shelves[index],
        booksPerShelf: booksPerShelf,
      ),
    );
  }
}

/// 1段の棚（木目調の棚板 + 本）.
class _ShelfRow extends StatelessWidget {
  const _ShelfRow({required this.books, required this.booksPerShelf});

  final List<Book> books;
  final int booksPerShelf;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF2C1810), // 棚の奥の暗い背景
      child: Column(
      children: [
        // 本の列
        SizedBox(
          height: 150,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < books.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: SizedBox(
                      width: 50, // 本の幅を固定
                      height: 120 +
                          (books[i].title.length % 4) * 8.0,
                      child: _BookCover(book: books[i]),
                    ),
                  ),
                // 残りのスペースは背景色で埋める
                const Spacer(),
              ],
            ),
          ),
        ),
        // 木目調の棚板
        CustomPaint(
          size: const Size(double.infinity, 14),
          painter: _ShelfBoardPainter(),
        ),
      ],
      ),
    );
  }
}

/// 木目調の棚板を描画するCustomPainter.
class _ShelfBoardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 棚板本体（木目ベース色）
    final boardPaint = Paint()
      ..color = const Color(0xFF5D4037);
    final boardRect = Rect.fromLTWH(0, 0, size.width, size.height - 2);
    canvas.drawRect(boardRect, boardPaint);

    // 木目のライン
    final grainPaint = Paint()
      ..color = const Color(0xFF4E342E)
      ..strokeWidth = 0.8;
    for (var y = 2.0; y < size.height - 2; y += 3) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y + 0.5),
        grainPaint,
      );
    }

    // 明るいハイライト（上端）
    final highlightPaint = Paint()
      ..color = const Color(0xFF8D6E63)
      ..strokeWidth = 1.5;
    canvas.drawLine(
      const Offset(0, 0.5),
      Offset(size.width, 0.5),
      highlightPaint,
    );

    // 棚板の影（下端）
    final shadowPaint = Paint()
      ..color = const Color(0xFF3E2723);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - 2, size.width, 2),
      shadowPaint,
    );

    // 棚板の前面（厚み表現）
    final frontPaint = Paint()
      ..color = const Color(0xFF6D4C41);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - 4, size.width, 2),
      frontPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 背表紙が見える本のウィジェット.
class _BookCover extends ConsumerWidget {
  const _BookCover({required this.book});

  final Book book;

  /// 本ごとに固定の色を決定（タイトルのハッシュから算出）.
  Color _bookBaseColor() {
    // 落ち着いた書籍風カラーパレット
    const palette = [
      Color(0xFF1B5E20), // ダークグリーン
      Color(0xFF004D40), // ティール
      Color(0xFF0D47A1), // ダークブルー
      Color(0xFF311B92), // ダークパープル
      Color(0xFF880E4F), // ダークピンク
      Color(0xFFBF360C), // ダークオレンジ
      Color(0xFF4E342E), // ダークブラウン
      Color(0xFF263238), // ダークグレー
      Color(0xFF1A237E), // インディゴ
      Color(0xFF33691E), // ライトグリーン
    ];
    final index = book.title.hashCode.abs() % palette.length;
    return palette[index];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final baseColor = _bookBaseColor();
    final darkerColor = Color.lerp(baseColor, Colors.black, 0.3)!;
    final lighterColor = Color.lerp(baseColor, Colors.white, 0.15)!;

    // ステータスに応じた帯の色
    final bandColor = switch (book.status) {
      BookStatus.unread => Colors.transparent,
      BookStatus.reading => colors.accent,
      BookStatus.completed => colors.success,
    };

    return GestureDetector(
      onTap: () => _showBookActions(context, ref),
      child: Container(
        decoration: BoxDecoration(
          // 背表紙のグラデーション（左右に丸みを持たせた陰影）
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            stops: const [0.0, 0.05, 0.15, 0.85, 0.95, 1.0],
            colors: [
              darkerColor,
              baseColor,
              lighterColor,
              lighterColor,
              baseColor,
              darkerColor,
            ],
          ),
          borderRadius: BorderRadius.circular(2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(60),
              offset: const Offset(2, 1),
              blurRadius: 3,
            ),
          ],
        ),
        child: Stack(
          children: [
            // 上部の装飾ライン
            Positioned(
              top: 6,
              left: 4,
              right: 4,
              child: Container(
                height: 1,
                color: Colors.white.withAlpha(40),
              ),
            ),
            // 下部の装飾ライン
            Positioned(
              bottom: 6,
              left: 4,
              right: 4,
              child: Container(
                height: 1,
                color: Colors.white.withAlpha(40),
              ),
            ),
            // ステータス帯（読書中・読了のみ表示）
            if (bandColor != Colors.transparent)
              Positioned(
                top: 10,
                left: 2,
                right: 2,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: bandColor,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            // タイトル（縦書き風）
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 3, vertical: 16),
                child: Text(
                  book.title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withAlpha(220),
                    height: 1.4,
                    letterSpacing: 1,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookActions(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).appColors;
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  book.title,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              if (book.status == BookStatus.unread)
                ListTile(
                  leading: const Icon(Icons.play_arrow_outlined),
                  title: const Text('読書開始'),
                  onTap: () {
                    Navigator.pop(context);
                    ref
                        .read(bookListProvider.notifier)
                        .updateStatus(book.id, BookStatus.reading);
                  },
                ),
              if (book.status == BookStatus.reading)
                ListTile(
                  leading: Icon(Icons.check_circle_outline,
                      color: colors.success),
                  title: const Text('読了にする'),
                  onTap: () {
                    Navigator.pop(context);
                    _completeBook(context, ref);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.timer_outlined),
                title: const Text('読書時間を記録'),
                onTap: () {
                  Navigator.pop(context);
                  _openReadingLog(context, ref);
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month_outlined),
                title: const Text('スケジュールを編集'),
                onTap: () {
                  Navigator.pop(context);
                  _openSchedule(context, ref);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: colors.error),
                title: Text('削除', style: TextStyle(color: colors.error)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteBook(context, ref);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openReadingLog(BuildContext context, WidgetRef ref) async {
    final studyLogService = ref.read(studyLogServiceProvider);
    final logic = TaskStudyLogLogic(
      studyLogService: studyLogService,
      taskId: bookLogTaskId(book.id),
      taskName: '📖 ${book.title}',
    );
    if (!context.mounted) return;
    await showReadingLogDialog(
      context,
      logic: logic,
      bookTitle: book.title,
    );
    ref.invalidate(bookListProvider);
    ref.invalidate(allLogsProvider);
  }

  Future<void> _completeBook(BuildContext context, WidgetRef ref) async {
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

  Future<void> _openSchedule(BuildContext context, WidgetRef ref) async {
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

  Future<void> _deleteBook(BuildContext context, WidgetRef ref) async {
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
