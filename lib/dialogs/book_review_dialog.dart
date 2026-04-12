/// 書籍読了レビューダイアログ.
///
/// 読了日、要約、感想を入力させる.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_labels.dart';

/// BookReviewDialog の入力結果.
class BookReviewResult {
  /// BookReviewResultを作成する.
  const BookReviewResult({
    required this.completedDate,
    required this.summary,
    required this.impressions,
  });

  /// 読了日.
  final DateTime completedDate;

  /// 要約.
  final String summary;

  /// 感想.
  final String impressions;
}

/// 読了レビューダイアログを表示する.
///
/// [bookTitle]はダイアログタイトルに表示する書籍名.
Future<BookReviewResult?> showBookReviewDialog(
  BuildContext context, {
  required String bookTitle,
}) {
  return showDialog<BookReviewResult>(
    context: context,
    builder: (_) => _BookReviewDialogContent(bookTitle: bookTitle),
  );
}

class _BookReviewDialogContent extends StatefulWidget {
  const _BookReviewDialogContent({required this.bookTitle});

  final String bookTitle;

  @override
  State<_BookReviewDialogContent> createState() =>
      _BookReviewDialogContentState();
}

class _BookReviewDialogContentState extends State<_BookReviewDialogContent> {
  late final TextEditingController _dateController;
  late final TextEditingController _summaryController;
  late final TextEditingController _impressionsController;
  DateTime _completedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(_completedDate),
    );
    _summaryController = TextEditingController();
    _impressionsController = TextEditingController();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _summaryController.dispose();
    _impressionsController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _completedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _completedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _submit() {
    Navigator.of(context).pop(
      BookReviewResult(
        completedDate: _completedDate,
        summary: _summaryController.text.trim(),
        impressions: _impressionsController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(AppLabels.reviewTitle(widget.bookTitle)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 読了日
              Text(AppLabels.reviewDate, style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              TextFormField(
                controller: _dateController,
                decoration: InputDecoration(
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_month),
                    onPressed: _pickDate,
                  ),
                ),
                readOnly: true,
                onTap: _pickDate,
              ),
              const SizedBox(height: 16),

              // 要約
              Text(AppLabels.reviewSummary, style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              TextField(
                controller: _summaryController,
                decoration: const InputDecoration(
                  hintText: AppLabels.reviewSummaryHint,
                ),
                maxLines: 6,
                minLines: 3,
              ),
              const SizedBox(height: 16),

              // 感想
              Text(AppLabels.reviewImpressions, style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              TextField(
                controller: _impressionsController,
                decoration: const InputDecoration(
                  hintText: AppLabels.reviewImpressionsHint,
                ),
                maxLines: 6,
                minLines: 3,
              ),
            ],
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
          child: const Text(AppLabels.bookStatusCompleted),
        ),
      ],
    );
  }
}
