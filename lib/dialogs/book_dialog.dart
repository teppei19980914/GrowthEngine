/// 書籍の追加・編集ダイアログ.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_labels.dart';
import '../models/book.dart';

/// BookDialog の入力結果.
class BookDialogResult {
  /// BookDialogResultを作成する.
  const BookDialogResult({
    required this.title,
    required this.category,
    required this.why,
    required this.description,
    this.status,
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

  /// ステータス（編集時のみ）.
  final BookStatus? status;

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
  late BookStatus _selectedStatus;

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
    _selectedStatus = widget.book?.status ?? BookStatus.unread;
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
    final screenHeight = MediaQuery.sizeOf(context).height;
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    // ダイアログの最大高さ: 画面高さからキーボード・タイトル・ボタン分を引く
    final maxContentHeight = screenHeight - keyboardHeight - 200;

    final dateFmt = DateFormat('yyyy/MM/dd HH:mm:ss');

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.menu_book_outlined, size: 24),
          const SizedBox(width: 8),
          Text(_isEdit ? AppLabels.bookDialogEdit : AppLabels.bookDialogAdd),
          if (_isEdit) ...[
            const Spacer(),
            Text(
              '${AppLabels.bookCreatedAt}: ${dateFmt.format(widget.book!.createdAt)}\n'
              '${AppLabels.bookUpdatedAt}: ${dateFmt.format(widget.book!.updatedAt)}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.right,
            ),
          ],
        ],
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      content: SizedBox(
        width: 400,
        height: maxContentHeight.clamp(200, 480).toDouble(),
        child: Form(
          key: _formKey,
          child: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: '${AppLabels.bookTitle} *',
                      hintText: AppLabels.bookHintTitle,
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? AppLabels.validBookTitle : null,
                    autofocus: !_isEdit,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<BookCategory>(
                    initialValue: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: AppLabels.bookCategory,
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
                  if (_isEdit) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<BookStatus>(
                      initialValue: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: AppLabels.scheduleStatus,
                      ),
                      items: BookStatus.values
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s.label),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedStatus = v);
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _whyController,
                    decoration: const InputDecoration(
                      labelText: AppLabels.bookWhy,
                      hintText: AppLabels.bookHintWhy,
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: AppLabels.bookMemo,
                      hintText: AppLabels.bookHintMemo,
                    ),
                    maxLines: 6,
                  ),
                ],
              ),
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
            child: const Text(AppLabels.btnDelete),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(AppLabels.btnCancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(_isEdit ? AppLabels.btnSave : AppLabels.btnAdd),
        ),
      ],
    );
  }

  Future<void> _requestDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppLabels.bookDialogDelete),
        content: Text(AppLabels.deleteConfirm(widget.book!.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppLabels.btnCancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppLabels.btnDelete),
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
        status: _isEdit ? _selectedStatus : null,
      ),
    );
  }
}

