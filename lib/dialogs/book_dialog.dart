/// 書籍の追加・編集ダイアログ.
library;

import 'package:flutter/material.dart';

import '../models/book.dart';

/// BookDialog の入力結果.
class BookDialogResult {
  /// BookDialogResultを作成する.
  const BookDialogResult({
    required this.title,
    required this.category,
    required this.why,
    required this.description,
    this.deleteRequested = false,
  });

  /// 書籍名.
  final String title;

  /// カテゴリ.
  final BookCategory category;

  /// なぜ読むのか.
  final String why;

  /// 内容メモ.
  final String description;

  /// 削除リクエスト.
  final bool deleteRequested;
}

/// 書籍ダイアログを表示する.
///
/// [book]が指定された場合は編集モード、nullの場合は新規作成モード.
Future<BookDialogResult?> showBookDialog(
  BuildContext context, {
  Book? book,
}) {
  return showDialog<BookDialogResult>(
    context: context,
    builder: (_) => _BookDialogContent(book: book),
  );
}

class _BookDialogContent extends StatefulWidget {
  const _BookDialogContent({this.book});

  final Book? book;

  @override
  State<_BookDialogContent> createState() => _BookDialogContentState();
}

class _BookDialogContentState extends State<_BookDialogContent> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _whyController;
  late final TextEditingController _descriptionController;
  late BookCategory _selectedCategory;

  bool get _isEdit => widget.book != null;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.book?.title ?? '');
    _whyController =
        TextEditingController(text: widget.book?.why ?? '');
    _descriptionController =
        TextEditingController(text: widget.book?.description ?? '');
    _selectedCategory = widget.book?.category ?? BookCategory.other;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _whyController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.menu_book_outlined, size: 24),
          const SizedBox(width: 8),
          Text(_isEdit ? '書籍を編集' : '書籍を追加'),
        ],
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: '書籍名 *',
                    hintText: '書籍のタイトルを入力',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? '書籍名は必須です' : null,
                  autofocus: !_isEdit,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<BookCategory>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'カテゴリ',
                  ),
                  items: BookCategory.values
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c.label),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedCategory = v);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _whyController,
                  decoration: const InputDecoration(
                    labelText: 'なぜ読むのか',
                    hintText: 'この本を読む理由や目的',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: '内容メモ',
                    hintText: '気になるポイントや期待する学びなど',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (_isEdit)
          TextButton(
            onPressed: _requestDelete,
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('削除'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(_isEdit ? '保存' : '追加'),
        ),
      ],
    );
  }

  Future<void> _requestDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('書籍を削除'),
        content: Text('「${widget.book!.title}」を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      Navigator.pop(
        context,
        const BookDialogResult(
          title: '',
          category: BookCategory.other,
          why: '',
          description: '',
          deleteRequested: true,
        ),
      );
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      BookDialogResult(
        title: _titleController.text.trim(),
        category: _selectedCategory,
        why: _whyController.text.trim(),
        description: _descriptionController.text.trim(),
      ),
    );
  }
}
