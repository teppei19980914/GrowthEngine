/// 読書時間記録ダイアログ.
///
/// 書籍の読書時間を記録・一覧表示する.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/task_study_log_logic.dart';
import '../theme/app_theme.dart';

/// 読書ログ用のtaskIdプレフィックス.
const String bookLogPrefix = 'book__';

/// 書籍IDからログ用taskIdを生成する.
String bookLogTaskId(String bookId) => '$bookLogPrefix$bookId';

/// taskIdが書籍ログかどうかを判定する.
bool isBookLogTaskId(String taskId) => taskId.startsWith(bookLogPrefix);

/// 活動時間記録ダイアログを表示する.
///
/// 書籍の読書時間やタスクの活動時間を記録するための共通ダイアログ.
/// 戻り値が `'back'` の場合、呼び出し元で選択肢画面に戻る.
Future<String?> showReadingLogDialog(
  BuildContext context, {
  required TaskStudyLogLogic logic,
  required String bookTitle,
  String? dialogTitle,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _ReadingLogDialog(
      logic: logic,
      title: dialogTitle ?? '読書時間 - $bookTitle',
    ),
  );
}

class _ReadingLogDialog extends StatefulWidget {
  const _ReadingLogDialog({
    required this.logic,
    required this.title,
  });

  final TaskStudyLogLogic logic;
  final String title;

  @override
  State<_ReadingLogDialog> createState() => _ReadingLogDialogState();
}

class _ReadingLogDialogState extends State<_ReadingLogDialog> {
  final _hoursController = TextEditingController(text: '0');
  final _minutesController = TextEditingController(text: '30');
  final _memoController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  List<StudyLogDisplayEntry> _logs = [];
  bool _loading = true;
  int _totalMinutes = 0;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    final logs = await widget.logic.getLogs();
    final stats = await widget.logic.getStats();
    if (mounted) {
      setState(() {
        _logs = logs;
        _totalMinutes = stats.totalMinutes;
        _loading = false;
      });
    }
  }

  Future<void> _addLog() async {
    final hours = int.tryParse(_hoursController.text) ?? 0;
    final minutes = int.tryParse(_minutesController.text) ?? 0;
    final total = hours * 60 + minutes;
    if (total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('1分以上で入力してください')),
      );
      return;
    }

    await widget.logic.addLog(
      studyDate: _selectedDate,
      durationMinutes: total,
      memo: _memoController.text.trim(),
    );
    _memoController.clear();
    _hoursController.text = '0';
    _minutesController.text = '30';
    await _loadLogs();
  }

  Future<void> _deleteLog(String logId) async {
    await widget.logic.deleteLog(logId);
    await _loadLogs();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.timer_outlined, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.title,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 合計時間
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.accent.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '合計: ${TaskStudyLogLogic.formatDuration(_totalMinutes)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colors.accent,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 日付選択
              Text('日付', style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    suffixIcon: Icon(Icons.calendar_month, size: 20),
                  ),
                  child: Text(
                    DateFormat('yyyy/MM/dd').format(_selectedDate),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 時間入力
              Text('読書時間', style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _hoursController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(suffixText: '時間'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _minutesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(suffixText: '分'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // メモ + 記録ボタン
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _memoController,
                      decoration: const InputDecoration(
                        hintText: 'メモ（任意）',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _addLog,
                    child: const Text('記録'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ログ一覧
              Text('記録一覧', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (_logs.isEmpty)
                Text(
                  '読書を始めると記録が表示されます',
                  style: TextStyle(color: colors.textMuted, fontSize: 13),
                )
              else
                for (final log in _logs) ...[
                  Row(
                    children: [
                      Text(
                        DateFormat('MM/dd').format(log.studyDate),
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        TaskStudyLogLogic.formatDuration(log.durationMinutes),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (log.memo.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            log.memo,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textMuted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ] else
                        const Spacer(),
                      IconButton(
                        icon: Icon(Icons.close, size: 16, color: colors.error),
                        onPressed: () => _deleteLog(log.logId),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const Divider(height: 8),
                ],
            ],
          ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop('back'),
          child: const Text('戻る'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('閉じる'),
        ),
      ],
    );
  }
}
