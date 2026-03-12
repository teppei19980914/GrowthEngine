/// タスクの追加・編集ダイアログ.
///
/// タスク名、開始日、終了日、進捗、メモ、関連書籍、活動ログを入力させる.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/book.dart';
import '../models/task.dart';
import '../services/study_log_service.dart';
import '../services/study_stats_types.dart';
import '../services/task_study_log_logic.dart';

/// TaskDialog の入力結果.
class TaskDialogResult {
  /// TaskDialogResultを作成する.
  const TaskDialogResult({
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.progress,
    required this.memo,
    this.bookId = '',
    this.studyLogsChanged = false,
    this.deleteRequested = false,
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

  /// 関連書籍ID.
  final String bookId;

  /// 活動ログが変更されたか.
  final bool studyLogsChanged;

  /// 削除がリクエストされたか.
  final bool deleteRequested;
}

/// タスクダイアログを表示する.
///
/// [task]が指定された場合は編集モード、nullの場合は新規作成モード.
/// [books]が指定された場合、関連書籍ドロップダウンを表示する.
/// [studyLogService]が指定された場合（編集モード時）、活動ログセクションを表示する.
Future<TaskDialogResult?> showTaskDialog(
  BuildContext context, {
  Task? task,
  List<Book>? books,
  StudyLogService? studyLogService,
}) {
  return showDialog<TaskDialogResult>(
    context: context,
    builder: (_) => _TaskDialogContent(
      task: task,
      books: books ?? const [],
      studyLogService: studyLogService,
    ),
  );
}

class _TaskDialogContent extends StatefulWidget {
  const _TaskDialogContent({
    this.task,
    this.books = const [],
    this.studyLogService,
  });

  final Task? task;
  final List<Book> books;
  final StudyLogService? studyLogService;

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
  bool _studyLogsChanged = false;

  // 活動ログ
  TaskStudyLogLogic? _studyLogLogic;
  List<StudyLogDisplayEntry> _studyLogs = [];
  TaskStudyStats? _studyStats;

  // 活動ログ入力
  late DateTime _logDate;
  int _logHours = 0;
  int _logMinutes = 30;
  final _logMemoController = TextEditingController();

  // タイマー
  Timer? _displayTimer;

  bool get _isEdit => widget.task != null;
  bool get _hasStudyLogSection =>
      _isEdit && widget.studyLogService != null;
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
    _logDate = today;
    _startDateController = TextEditingController(
      text: _dateFormat.format(_startDate),
    );
    _endDateController = TextEditingController(
      text: _dateFormat.format(_endDate),
    );

    if (_hasStudyLogSection) {
      _studyLogLogic = TaskStudyLogLogic(
        studyLogService: widget.studyLogService!,
        taskId: task!.id,
        taskName: task.title,
      );
      _refreshStudyLogs();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _memoController.dispose();
    _logMemoController.dispose();
    _displayTimer?.cancel();
    // タイマー実行中なら停止して記録
    if (_studyLogLogic != null && _studyLogLogic!.isTimerRunning) {
      _stopTimerAndRecord();
    }
    super.dispose();
  }

  Future<void> _refreshStudyLogs() async {
    if (_studyLogLogic == null) return;
    final logs = await _studyLogLogic!.getLogs();
    final stats = await _studyLogLogic!.getStats();
    if (mounted) {
      setState(() {
        _studyLogs = logs;
        _studyStats = stats;
      });
    }
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
    if (progress == 0) return '未着手';
    if (progress >= 100) return '完了';
    return '進行中';
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
        bookId: _selectedBookId,
        studyLogsChanged: _studyLogsChanged,
      ),
    );
  }

  // --- 活動ログ関連 ---

  Future<void> _addStudyLog() async {
    if (_studyLogLogic == null) return;

    try {
      final totalMinutes =
          TaskStudyLogLogic.validateDuration(_logHours, _logMinutes);
      await _studyLogLogic!.addLog(
        studyDate: _logDate,
        durationMinutes: totalMinutes,
        memo: _logMemoController.text.trim(),
      );
      _logMemoController.clear();
      setState(() {
        _logHours = 0;
        _logMinutes = 30;
      });
      _studyLogsChanged = true;
      await _refreshStudyLogs();
    } on ArgumentError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message as String)),
      );
    }
  }

  Future<void> _deleteStudyLog(String logId) async {
    if (_studyLogLogic == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認'),
        content: const Text('この活動記録を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _studyLogLogic!.deleteLog(logId);
    _studyLogsChanged = true;
    await _refreshStudyLogs();
  }

  // --- タイマー関連 ---

  void _startTimer() {
    if (_studyLogLogic == null) return;
    _studyLogLogic!.startTimer();
    _displayTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() {}),
    );
    setState(() {});
  }

  void _stopTimerAndRecord() {
    if (_studyLogLogic == null) return;
    _displayTimer?.cancel();
    _displayTimer = null;
    final minutes = _studyLogLogic!.stopTimer();
    if (minutes > 0) {
      _studyLogLogic!.addLog(
        studyDate: DateTime.now(),
        durationMinutes: minutes,
        memo: 'タイマー計測',
      );
      _studyLogsChanged = true;
      _refreshStudyLogs();
    }
    setState(() {});
  }

  String _formatTimerDisplay() {
    final seconds = _studyLogLogic?.elapsedSeconds ?? 0;
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(_isEdit ? 'タスクを編集' : '新しいタスクを追加')),
          if (_hasStudyLogSection) ...[
            Text(
              _formatTimerDisplay(),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(width: 4),
            if (_studyLogLogic?.isTimerRunning != true)
              IconButton(
                icon: const Icon(Icons.play_arrow, size: 20),
                onPressed: _startTimer,
                tooltip: '開始',
              )
            else
              IconButton(
                icon: const Icon(Icons.stop, size: 20),
                onPressed: _stopTimerAndRecord,
                tooltip: '停止',
              ),
          ],
        ],
      ),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // タスク名
                Text('タスク名', style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: '例: 第1章を読む',
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? '必須項目です' : null,
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
                            decoration: InputDecoration(
                              suffixIcon: IconButton(
                                icon: const Icon(
                                  Icons.calendar_month,
                                  size: 18,
                                ),
                                onPressed: _pickStartDate,
                              ),
                            ),
                            readOnly: true,
                            onTap: _pickStartDate,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('終了日', style: theme.textTheme.titleSmall),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _endDateController,
                            decoration: InputDecoration(
                              suffixIcon: IconButton(
                                icon: const Icon(
                                  Icons.calendar_month,
                                  size: 18,
                                ),
                                onPressed: _pickEndDate,
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
                      Text('進捗', style: theme.textTheme.titleSmall),
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
                Text('メモ', style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _memoController,
                  decoration: const InputDecoration(
                    hintText: 'メモ（任意）',
                  ),
                  maxLines: 3,
                  minLines: 2,
                ),

                // 関連書籍
                if (widget.books.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('関連書籍', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedBookId,
                    items: [
                      const DropdownMenuItem(
                        value: '',
                        child: Text('なし'),
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

                // 活動記録セクション（編集モード + studyLogService提供時のみ）
                if (_hasStudyLogSection) ...[
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 8),
                  _buildStudyLogSection(theme),
                ],
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
            onPressed: () {
              Navigator.of(context).pop(
                TaskDialogResult(
                  title: _titleController.text.trim(),
                  startDate: _startDate,
                  endDate: _endDate,
                  progress: _progress.round(),
                  memo: _memoController.text.trim(),
                  bookId: _selectedBookId,
                  deleteRequested: true,
                ),
              );
            },
            child: const Text('削除'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(_isEdit ? '更新' : '追加'),
        ),
      ],
    );
  }

  Widget _buildStudyLogSection(ThemeData theme) {
    final stats = _studyStats;
    final statsText = stats != null
        ? '合計: ${TaskStudyLogLogic.formatDuration(stats.totalMinutes)}'
            ' / ${stats.studyDays}日 / ${stats.logCount}件'
        : '合計: 0min / 0日 / 0件';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('活動記録 ($statsText)', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),

        // ログ一覧
        if (_studyLogs.isNotEmpty)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 150),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _studyLogs.length,
              itemBuilder: (_, index) {
                final entry = _studyLogs[index];
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '${_dateFormat.format(entry.studyDate)}  '
                    '${TaskStudyLogLogic.formatDuration(entry.durationMinutes)}',
                    style: theme.textTheme.bodySmall,
                  ),
                  subtitle: entry.memo.isNotEmpty
                      ? Text(entry.memo, style: theme.textTheme.labelSmall)
                      : null,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 16),
                    onPressed: () => _deleteStudyLog(entry.logId),
                  ),
                );
              },
            ),
          ),

        const SizedBox(height: 8),

        // ログ追加フォーム
        Row(
          children: [
            // 日付
            Expanded(
              flex: 3,
              child: InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _logDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _logDate = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: '活動日',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  child: Text(
                    _dateFormat.format(_logDate),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 時間
            SizedBox(
              width: 60,
              child: TextFormField(
                initialValue: _logHours.toString(),
                decoration: const InputDecoration(
                  labelText: '時間',
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) =>
                    _logHours = int.tryParse(v) ?? 0,
              ),
            ),
            const SizedBox(width: 4),
            // 分
            SizedBox(
              width: 60,
              child: TextFormField(
                initialValue: _logMinutes.toString(),
                decoration: const InputDecoration(
                  labelText: '分',
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) =>
                    _logMinutes = int.tryParse(v) ?? 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _logMemoController,
                decoration: const InputDecoration(
                  hintText: 'メモ（任意）',
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _addStudyLog,
              child: const Text('+ 記録追加'),
            ),
          ],
        ),
      ],
    );
  }
}
