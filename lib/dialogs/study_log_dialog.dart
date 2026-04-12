/// 活動ログ記録ダイアログ.
///
/// 活動日、活動時間（分）、メモを入力させる.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../l10n/app_labels.dart';
import '../widgets/app_snackbar.dart';

/// StudyLogDialog の入力結果.
class StudyLogDialogResult {
  /// StudyLogDialogResultを作成する.
  const StudyLogDialogResult({
    required this.studyDate,
    required this.durationMinutes,
    required this.memo,
  });

  /// 活動日.
  final DateTime studyDate;

  /// 活動時間（分）.
  final int durationMinutes;

  /// メモ.
  final String memo;
}

/// 活動ログダイアログを表示する.
///
/// [taskName]はダイアログタイトルに表示するタスク名.
Future<StudyLogDialogResult?> showStudyLogDialog(
  BuildContext context, {
  required String taskName,
}) {
  return showDialog<StudyLogDialogResult>(
    context: context,
    builder: (_) => _StudyLogDialogContent(taskName: taskName),
  );
}

class _StudyLogDialogContent extends StatefulWidget {
  const _StudyLogDialogContent({required this.taskName});

  final String taskName;

  @override
  State<_StudyLogDialogContent> createState() => _StudyLogDialogContentState();
}

class _StudyLogDialogContentState extends State<_StudyLogDialogContent> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _dateController;
  late final TextEditingController _hoursController;
  late final TextEditingController _minutesController;
  late final TextEditingController _memoController;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(_selectedDate),
    );
    _hoursController = TextEditingController(text: '0');
    _minutesController = TextEditingController(text: '30');
    _memoController = TextEditingController();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _hoursController.dispose();
    _minutesController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final hours = int.tryParse(_hoursController.text) ?? 0;
    final minutes = int.tryParse(_minutesController.text) ?? 0;
    final totalMinutes = hours * 60 + minutes;

    if (totalMinutes <= 0) {
      showInfoSnackBar(context, AppLabels.logMinRequired);
      return;
    }

    Navigator.of(context).pop(
      StudyLogDialogResult(
        studyDate: _selectedDate,
        durationMinutes: totalMinutes,
        memo: _memoController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text('${AppLabels.logDialogTitle}: ${widget.taskName}'),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
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
              // 活動日
              Text(AppLabels.logDate, style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              TextFormField(
                controller: _dateController,
                decoration: InputDecoration(
                  hintText: 'yyyy-MM-dd',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_month),
                    onPressed: _pickDate,
                  ),
                ),
                readOnly: true,
                onTap: _pickDate,
              ),
              const SizedBox(height: 16),

              // 活動時間
              Text(AppLabels.logDuration, style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _hoursController,
                      decoration: const InputDecoration(
                        suffixText: AppLabels.logHours,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _minutesController,
                      decoration: const InputDecoration(
                        suffixText: AppLabels.logMinutes,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // メモ
              Text(AppLabels.logMemo, style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              TextFormField(
                controller: _memoController,
                decoration: const InputDecoration(
                  hintText: AppLabels.logMemoHint,
                ),
                maxLines: 4,
              ),
            ],
          ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppLabels.btnCancel),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text(AppLabels.btnRecord),
        ),
      ],
    );
  }
}
