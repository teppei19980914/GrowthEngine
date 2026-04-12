/// タスクの追加・編集ダイアログ.
///
/// タスク名、開始日、終了日、進捗、メモ、関連書籍を入力させる.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_labels.dart';
import '../models/book.dart';
import '../models/goal.dart';
import '../models/task.dart';

/// TaskDialog の入力結果.
class TaskDialogResult {
  /// TaskDialogResultを作成する.
  const TaskDialogResult({
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.progress,
    required this.memo,
    this.goalId,
    this.bookId = '',
    this.deleteRequested = false,
    this.closeRequested = false,
  });

  /// タスク名.
  final String title;

  /// 開始日.
  final DateTime startDate;

  /// 終了日.
  final DateTime endDate;

  /// 進捗率（0-100）.
  final int progress;

  /// メモ.
  final String memo;

  /// 紐づける目標ID（nullの場合は変更なし）.
  final String? goalId;

  /// 関連書籍ID.
  final String bookId;

  /// 削除がリクエストされたか.
  final bool deleteRequested;

  /// ダイアログを完全に閉じるリクエスト（選択肢画面に戻らない）.
  final bool closeRequested;
}

/// タスクダイアログを表示する.
///
/// [task]が指定された場合は編集モード、nullの場合は新規作成モード.
/// [books]が指定された場合、関連書籍ドロップダウンを表示する.
Future<TaskDialogResult?> showTaskDialog(
  BuildContext context, {
  Task? task,
  List<Book>? books,
  List<Goal>? goals,
}) {
  return showDialog<TaskDialogResult>(
    context: context,
    builder: (_) => _TaskDialogContent(
      task: task,
      books: books ?? const [],
      goals: goals ?? const [],
    ),
  );
}

class _TaskDialogContent extends StatefulWidget {
  const _TaskDialogContent({
    this.task,
    this.books = const [],
    this.goals = const [],
  });

  final Task? task;
  final List<Book> books;
  final List<Goal> goals;

  @override
  State<_TaskDialogContent> createState() => _TaskDialogContentState();
}

class _TaskDialogContentState extends State<_TaskDialogContent> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _startDateController;
  late final TextEditingController _endDateController;
  late final TextEditingController _memoController;
  late DateTime _startDate;
  late DateTime _endDate;
  late double _progress;
  String _selectedBookId = '';
  String _selectedGoalId = '';

  bool get _isEdit => widget.task != null;
  final _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    _titleController = TextEditingController(text: task?.title ?? '');
    _memoController = TextEditingController(text: task?.memo ?? '');
    _startDate = task?.startDate ?? today;
    _endDate = task?.endDate ?? today.add(const Duration(days: 14));
    _progress = (task?.progress ?? 0).toDouble();
    _selectedBookId = task?.bookId ?? '';
    _selectedGoalId = task?.goalId ?? '';
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
    _memoController.dispose();
    super.dispose();
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

  String _statusLabel(int progress) {
    if (progress == 0) return AppLabels.taskStatusNotStarted;
    if (progress >= 100) return AppLabels.taskStatusCompleted;
    return AppLabels.taskStatusInProgress;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      TaskDialogResult(
        title: _titleController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        progress: _progress.round(),
        memo: _memoController.text.trim(),
        goalId: _isEdit ? _selectedGoalId : null,
        bookId: _selectedBookId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      title: Text(_isEdit ? AppLabels.taskDialogEdit : AppLabels.taskDialogAdd),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 目標（編集時のみ表示、一番上に配置）
                if (_isEdit && widget.goals.isNotEmpty) ...[
                  Text(AppLabels.taskGoal, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedGoalId,
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(
                        value: '',
                        child: Text(AppLabels.taskIndependent),
                      ),
                      ...widget.goals.map(
                        (g) => DropdownMenuItem(
                          value: g.id,
                          child: Text(g.what),
                        ),
                      ),
                    ],
                    onChanged: (v) =>
                        setState(() => _selectedGoalId = v ?? ''),
                  ),
                  const SizedBox(height: 16),
                ],

                // タスク名
                Text(AppLabels.taskName, style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: AppLabels.taskHintName,
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? AppLabels.validRequired : null,
                ),
                const SizedBox(height: 16),

                // 日付
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppLabels.taskStartDate, style: theme.textTheme.titleSmall),
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
                          Text(AppLabels.taskEndDate, style: theme.textTheme.titleSmall),
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

                // 進捗
                if (_isEdit) ...[
                  Row(
                    children: [
                      Text(AppLabels.taskProgress, style: theme.textTheme.titleSmall),
                      const Spacer(),
                      Text(
                        '${_progress.round()}% (${_statusLabel(_progress.round())})',
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
                  const SizedBox(height: 8),
                ],

                // メモ
                Text(AppLabels.taskMemo, style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _memoController,
                  decoration: const InputDecoration(
                    hintText: AppLabels.taskMemoHint,
                  ),
                  maxLines: 5,
                  minLines: 2,
                ),

                // 関連書籍
                if (widget.books.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(AppLabels.taskRelatedBook, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedBookId,
                    items: [
                      const DropdownMenuItem(
                        value: '',
                        child: Text(AppLabels.taskNone),
                      ),
                      ...widget.books.map(
                        (b) => DropdownMenuItem(
                          value: b.id,
                          child: Text(b.title),
                        ),
                      ),
                    ],
                    onChanged: (v) =>
                        setState(() => _selectedBookId = v ?? ''),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        // 左側: 戻る + 削除
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(AppLabels.btnBack),
            ),
            if (_isEdit)
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () {
                  Navigator.of(context).pop(
                    TaskDialogResult(
                      title: _titleController.text.trim(),
                      startDate: _startDate,
                      endDate: _endDate,
                      progress: _progress.round(),
                      memo: _memoController.text.trim(),
                      goalId: _isEdit ? _selectedGoalId : null,
                      bookId: _selectedBookId,
                      deleteRequested: true,
                    ),
                  );
                },
                child: const Text(AppLabels.btnDelete),
              ),
          ],
        ),
        // 右側: 閉じる + 保存
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(
                TaskDialogResult(
                  title: '',
                  startDate: _startDate,
                  endDate: _endDate,
                  progress: 0,
                  memo: '',
                  closeRequested: true,
                ),
              ),
              child: const Text(AppLabels.btnClose),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _submit,
              child: Text(_isEdit ? AppLabels.btnUpdate : AppLabels.btnAdd),
            ),
          ],
        ),
      ],
    );
  }
}
