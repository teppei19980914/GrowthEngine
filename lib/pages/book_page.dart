/// 書籍ページ.
///
/// 書籍一覧の表示、追加、ステータス変更、読了レビュー、削除を提供する.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../dialogs/book_dialog.dart';
import '../dialogs/trial_limit_dialog.dart';
import '../models/book.dart';
import '../providers/book_providers.dart';
import '../providers/service_providers.dart';
import '../services/trial_limit_service.dart';
import '../l10n/app_labels.dart';
import '../theme/app_theme.dart';


/// 書籍ページ.
class BookPage extends ConsumerStatefulWidget {
  /// BookPageを作成する.
  const BookPage({super.key});

  @override
  ConsumerState<BookPage> createState() => _BookPageState();
}

class _BookPageState extends ConsumerState<BookPage> {
  Future<void> _addBook() async {
    final books = await ref.read(bookListProvider.future);
    final currentCount = books.length;
    final level = ref.read(unlockLevelProvider);
    if (!canAddBook(currentCount: currentCount, unlockLevel: level)) {
      if (!mounted) return;
      await showTrialLimitDialog(
        context,
        itemName: AppLabels.pageBooks,
        currentCount: currentCount,
        maxCount: maxBooks(level),
        feedbackService: ref.read(feedbackServiceProvider),
      );
      ref.invalidate(feedbackServiceProvider);
      return;
    }

    if (!mounted) return;
    final result = await showBookDialog(context);
    if (result == null) return;

    await ref.read(bookListProvider.notifier).createBook(
          result.title,
          category: result.category,
          why: result.why,
          description: result.description,
        );
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(sortedBookListProvider);
    final sortOrder = ref.watch(bookSortOrderProvider);
    final theme = Theme.of(context);
    final colors = theme.appColors;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー行: ソート + 追加ボタン
          Row(
            children: [
              // ソートセレクタ
              DropdownButton<BookSortOrder>(
                value: sortOrder,
                underline: const SizedBox.shrink(),
                isDense: true,
                icon: const Icon(Icons.sort, size: 18),
                items: [
                  for (final order in BookSortOrder.values)
                    DropdownMenuItem(
                      value: order,
                      child: Text(order.label),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    ref
                        .read(bookSortOrderProvider.notifier)
                        .setSortOrder(value);
                  }
                },
              ),
              const Spacer(),
              FloatingActionButton.small(
                heroTag: 'book_add',
                onPressed: _addBook,
                child: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 本棚
          Expanded(
            child: booksAsync.when(
              data: (books) => books.isEmpty
                  ? _buildEmptyState(theme, colors)
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final availableWidth = constraints.maxWidth - 8;
                        // 最小幅40pxで収まる冊数を算出
                        final booksPerShelf =
                            (availableWidth / 42)
                                .floor()
                                .clamp(2, 50);
                        // 棚幅を冊数で完全等分（余白なし）
                        final bookWidth = availableWidth / booksPerShelf - 2;
                        return _Bookshelf(
                          books: books,
                          booksPerShelf: booksPerShelf,
                          bookWidth: bookWidth,
                        );
                      },
                    ),
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text(AppLabels.errorWithDetail('$error')),
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
            AppLabels.bookEmptyTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLabels.bookEmptySubtitle,
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
  const _Bookshelf({
    required this.books,
    required this.booksPerShelf,
    required this.bookWidth,
  });

  final List<Book> books;
  final int booksPerShelf;
  final double bookWidth;

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
        bookWidth: bookWidth,
      ),
    );
  }
}

/// 1段の棚（木目調の棚板 + 本）.
class _ShelfRow extends StatelessWidget {
  const _ShelfRow({
    required this.books,
    required this.booksPerShelf,
    required this.bookWidth,
  });

  final List<Book> books;
  final int booksPerShelf;
  final double bookWidth;

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
                      width: bookWidth,
                      height: 120 +
                          (books[i].title.length % 4) * 8.0,
                      child: _BookCover(book: books[i]),
                    ),
                  ),
                // 残りのスペースは背景色で埋める
                if (books.length < booksPerShelf) const Spacer(),
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
  static final _boardPaint = Paint()..color = const Color(0xFF5D4037);
  static final _grainPaint = Paint()
    ..color = const Color(0xFF4E342E)
    ..strokeWidth = 0.8;
  static final _highlightPaint = Paint()
    ..color = const Color(0xFF8D6E63)
    ..strokeWidth = 1.5;
  static final _shadowPaint = Paint()..color = const Color(0xFF3E2723);
  static final _frontPaint = Paint()..color = const Color(0xFF6D4C41);

  @override
  void paint(Canvas canvas, Size size) {
    // 棚板本体（木目ベース色）
    final boardRect = Rect.fromLTWH(0, 0, size.width, size.height - 2);
    canvas.drawRect(boardRect, _boardPaint);
    for (var y = 2.0; y < size.height - 2; y += 3) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y + 0.5),
        _grainPaint,
      );
    }

    // 明るいハイライト（上端）
    canvas.drawLine(
      const Offset(0, 0.5),
      Offset(size.width, 0.5),
      _highlightPaint,
    );
    // 棚板の影（下端）
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - 2, size.width, 2),
      _shadowPaint,
    );

    // 棚板の前面（厚み表現）
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - 4, size.width, 2),
      _frontPaint,
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
      onTap: () => _editBook(context, ref),
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

  Future<void> _editBook(BuildContext context, WidgetRef ref) async {
    final result = await showBookDialog(context, book: book);
    if (result == null) return;

    if (result.deleteRequested) {
      await ref.read(bookListProvider.notifier).deleteBook(book.id);
      return;
    }

    await ref.read(bookListProvider.notifier).updateBookInfoAndStatus(
          book.id,
          title: result.title,
          category: result.category,
          why: result.why,
          description: result.description,
          status: result.status,
        );
  }

}
