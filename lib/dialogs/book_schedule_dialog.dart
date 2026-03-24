/// 書籍スケジュールの登録/編集ダイアログ.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/book.dart';

const _newBookKey = '__new__';

/// BookScheduleDialog の入力結果.
class BookScheduleDialogResult {
  /// BookScheduleDialogResultを作成する.
  const BookScheduleDialogResult({
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.progress,
    this.bookSource,
    this.deleteRequested = false,
  });

  /// 書籍名.
  final String title;

  /// 開始日.
  final DateTime startDate;

  /// 終了日.
  final DateTime endDate;

  /// 進捗率（0-100）.
  final int progress;

  /// 書籍ソース（追加モード: '__new__' or 既存書籍ID）.
  final String? bookSource;

  /// スケジュール削除がリクエストされたか.
  final bool deleteRequested;
}

/// 書籍スケジュールダイアログを表示する.
///
/// [book]が指定された場合は編集モード、nullの場合は追加モード.
/// [unscheduledBooks]は追加モードで未スケジュール書籍を選択するためのリスト.
Future<BookScheduleDialogResult?> showBookScheduleDialog(
  BuildContext context, {
  Book? book,
  List<Book> unscheduledBooks = const [],
}) {
  return showDialog<BookScheduleDialogResult>(
    context: context,
    builder: (_) => _BookScheduleDialogContent(
      book: book,
      unscheduledBooks: unscheduledBooks,
    ),
  );
}

class _BookScheduleDialogContent extends StatefulWidget {
  const _BookScheduleDialogContent({
    this.book,
    this.unscheduledBooks = const [],
  });

  final Book? book;
  final List<Book> unscheduledBooks;

  @override
  State<_BookScheduleDialogContent> createState() =>
      _BookScheduleDialogContentState();
}

class _BookScheduleDialogContentState
    extends State<_BookScheduleDialogContent> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _startDateController;
  late final TextEditingController _endDateController;
  late DateTime _startDate;
  late DateTime _endDate;
  late double _progress;
  String _selectedBookSource = _newBookKey;
  bool _titleEditable = true;

  bool get _isEdit => widget.book != null;
  final _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    final book = widget.book;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    _titleController = TextEditingController(text: book?.title ?? '');
    _startDate = book?.startDate ?? today;
    _endDate = book?.endDate ?? today.add(const Duration(days: 30));
    _progress = (book?.progress ?? 0).toDouble();
    _startDateController = TextEditingController(
      text: _dateFormat.format(_startDate),
    );
    _endDateController = TextEditingController(
      text: _dateFormat.format(_endDate),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  String _statusLabel(int progress) {
    if (progress == 0) return '未読';
    if (progress >= 100) return '読了';
    return '読書中';
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2050),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        _startDateController.text = _dateFormat.format(picked);
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate;
          _endDateController.text = _dateFormat.format(_startDate);
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime(2050),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
        _endDateController.text = _dateFormat.format(picked);
      });
    }
  }

  void _onSourceChanged(String? value) {
    if (value == null) return;
    setState(() {
      _selectedBookSource = value;
      if (value == _newBookKey) {
        _titleEditable = true;
        _titleController.clear();
      } else {
        _titleEditable = false;
        final book = widget.unscheduledBooks.firstWhere((b) => b.id == value);
        _titleController.text = book.title;
      }
    });
  }

  void _onDelete() {
    Navigator.of(context).pop(
      BookScheduleDialogResult(
        title: _titleController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        progress: _progress.round(),
        deleteRequested: true,
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      BookScheduleDialogResult(
        title: _titleController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        progress: _progress.round(),
        bookSource: _isEdit ? null : _selectedBookSource,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(_isEdit ? '読書スケジュールを編集' : '読書スケジュールを追加'),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 書籍ソース選択（追加モードのみ）
                if (!_isEdit && widget.unscheduledBooks.isNotEmpty) ...[
                  Text('書籍', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedBookSource,
                    items: [
                      const DropdownMenuItem(
                        value: _newBookKey,
                        child: Text('\u{1F4DD} 新しい書籍を作成'),
                      ),
                      ...widget.unscheduledBooks.map(
                        (b) => DropdownMenuItem(
                          value: b.id,
                          child: Text('\u{1F4D6} ${b.title}'),
                        ),
                      ),
                    ],
                    onChanged: _onSourceChanged,
                  ),
                  const SizedBox(height: 16),
                ],

                // 書籍名
                Text('書籍名', style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _titleController,
                  enabled: _titleEditable,
                  decoration: const InputDecoration(
                    hintText: '例: Python入門',
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? '書籍名は必須です' : null,
                ),
                const SizedBox(height: 16),

                // 日付
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('開始日', style: theme.textTheme.titleSmall),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _startDateController,
                            decoration: const InputDecoration(
                              isDense: true,
                              suffixIcon: Icon(
                                Icons.calendar_month,
                                size: 18,
                              ),
                              suffixIconConstraints: BoxConstraints(
                                minWidth: 32,
                                minHeight: 0,
                              ),
                            ),
                            readOnly: true,
                            onTap: _pickStartDate,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('終了日', style: theme.textTheme.titleSmall),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _endDateController,
                            decoration: const InputDecoration(
                              isDense: true,
                              suffixIcon: Icon(
                                Icons.calendar_month,
                                size: 18,
                              ),
                              suffixIconConstraints: BoxConstraints(
                                minWidth: 32,
                                minHeight: 0,
                              ),
                            ),
                            readOnly: true,
                            onTap: _pickEndDate,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ステータス表示（読み取り専用）
                Row(
                  children: [
                    Text('ステータス', style: theme.textTheme.titleSmall),
                    const Spacer(),
                    Text(
                      _statusLabel(_progress.round()),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 進捗率
                Row(
                  children: [
                    Text('進捗率', style: theme.textTheme.titleSmall),
                    const Spacer(),
                    Text(
                      '${_progress.round()}%',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Slider(
                  value: _progress,
                  max: 100,
                  divisions: 20,
                  label: '${_progress.round()}%',
                  onChanged: (v) => setState(() => _progress = v),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (_isEdit)
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('確認'),
                  content: const Text(
                    'この書籍のスケジュールを削除しますか？\n（書籍自体は削除されません）',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('キャンセル'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.error,
                      ),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('削除'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) _onDelete();
            },
            child: const Text('スケジュール削除'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(_isEdit ? '保存' : '追加'),
        ),
      ],
    );
  }
}
