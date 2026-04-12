/// モニターデータ提出ダイアログ.
///
/// 招待コードユーザーの期限1週間前に表示し、
/// アンケート回答とアプリデータを一括送信する.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../l10n/app_labels.dart';
import '../services/feedback_service.dart' show feedbackEndpointUrl;
import '../theme/app_theme.dart';

/// モニター提出用ダイアログを表示する.
Future<void> showMonitorSubmissionDialog(
  BuildContext context, {
  required int remainingDays,
  required String inviteName,
  required Future<String> Function() exportData,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _MonitorSubmissionDialog(
      remainingDays: remainingDays,
      inviteName: inviteName,
      exportData: exportData,
    ),
  );
}

class _MonitorSubmissionDialog extends StatefulWidget {
  const _MonitorSubmissionDialog({
    required this.remainingDays,
    required this.inviteName,
    required this.exportData,
  });

  final int remainingDays;
  final String inviteName;
  final Future<String> Function() exportData;

  @override
  State<_MonitorSubmissionDialog> createState() =>
      _MonitorSubmissionDialogState();
}

class _MonitorSubmissionDialogState extends State<_MonitorSubmissionDialog> {
  int _currentStep = 0; // 0=説明, 1=アンケート, 2=送信中, 3=完了
  String? _error;

  // アンケート回答
  int _usabilityRating = 0; // 1-5
  final _goodPointController = TextEditingController();
  final _improvementController = TextEditingController();
  final _featureRequestController = TextEditingController();

  @override
  void dispose() {
    _goodPointController.dispose();
    _improvementController.dispose();
    _featureRequestController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _currentStep = 2;
      _error = null;
    });

    try {
      // データをエクスポート
      final exportedData = await widget.exportData();

      // アンケート + データを送信
      final payload = jsonEncode({
        'type': 'data_submission',
        'inviteName': widget.inviteName,
        'survey': {
          'usabilityRating': _usabilityRating,
          'goodPoints': _goodPointController.text.trim(),
          'improvements': _improvementController.text.trim(),
          'featureRequests': _featureRequestController.text.trim(),
        },
        'appData': exportedData,
        'submittedAt': DateTime.now().toIso8601String(),
      });

      final response = await http
          .post(
            Uri.parse(feedbackEndpointUrl),
            headers: {'Content-Type': 'text/plain'},
            body: payload,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        setState(() {
          _currentStep = 3;
        });
      } else {
        setState(() {
          _error = AppLabels.monitorSendFailed;
          _currentStep = 1;
        });
      }
    } on Exception {
      setState(() {
        _error = AppLabels.monitorNetworkError;
        _currentStep = 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.assignment_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Expanded(child: Text(AppLabels.monitorTitle)),
        ],
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: switch (_currentStep) {
            0 => _buildIntroPage(theme, colors),
            1 => _buildSurveyPage(theme, colors),
            2 => _buildSendingPage(theme),
            3 => _buildCompletePage(theme, colors),
            _ => const SizedBox.shrink(),
          },
        ),
      ),
      actions: switch (_currentStep) {
        0 => [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(AppLabels.btnLater),
            ),
            ElevatedButton(
              onPressed: () => setState(() => _currentStep = 1),
              child: const Text(AppLabels.monitorAnswer),
            ),
          ],
        1 => [
            TextButton(
              onPressed: () => setState(() => _currentStep = 0),
              child: const Text(AppLabels.btnBack),
            ),
            ElevatedButton(
              onPressed: _usabilityRating > 0 ? _submit : null,
              child: const Text(AppLabels.monitorSubmit),
            ),
          ],
        2 => [],
        3 => [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(AppLabels.btnClose),
            ),
          ],
        _ => [],
      },
    );
  }

  Widget _buildIntroPage(ThemeData theme, AppColors colors) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.warning.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.schedule,
                  color: widget.remainingDays > 0
                      ? colors.warning
                      : colors.error,
                  size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.remainingDays > 0
                      ? AppLabels.monitorRemainingDays(widget.remainingDays)
                      : AppLabels.monitorExpired,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: widget.remainingDays > 0
                        ? colors.warning
                        : colors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          AppLabels.monitorThanks,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        Text(
          AppLabels.monitorRequestDesc,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withAlpha(10),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.primary.withAlpha(30),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.security, size: 16,
                      color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    AppLabels.monitorDataHandlingTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                AppLabels.monitorDataHandlingDesc,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          AppLabels.monitorSubmissionContents,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        _buildBullet(AppLabels.monitorBullet1, colors),
        _buildBullet(AppLabels.monitorBullet2, colors),
      ],
    );
  }

  Widget _buildBullet(String text, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('・', style: TextStyle(color: colors.textSecondary)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurveyPage(ThemeData theme, AppColors colors) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.error.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(_error!, style: TextStyle(color: colors.error)),
          ),
          const SizedBox(height: 12),
        ],

        // Q1: 使いやすさ（5段階）
        Text(
          AppLabels.monitorQ1,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final rating = i + 1;
            final selected = _usabilityRating >= rating;
            return IconButton(
              onPressed: () => setState(() => _usabilityRating = rating),
              icon: Icon(
                selected ? Icons.star : Icons.star_border,
                color: selected ? colors.warning : colors.textMuted,
                size: 32,
              ),
            );
          }),
        ),
        Center(
          child: Text(
            _usabilityRating > 0
                ? ['', AppLabels.monitorRating1, AppLabels.monitorRating2, AppLabels.monitorRating3, AppLabels.monitorRating4, AppLabels.monitorRating5][_usabilityRating]
                : AppLabels.monitorRatingHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Q2: 良かった点
        Text(
          AppLabels.monitorQ2,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: _goodPointController,
          decoration: const InputDecoration(
            hintText: AppLabels.monitorQ2Hint,
          ),
          maxLines: 4,
        ),
        const SizedBox(height: 16),

        // Q3: 改善点・要望
        Text(
          AppLabels.monitorQ3,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: _improvementController,
          decoration: const InputDecoration(
            hintText: AppLabels.monitorQ3Hint,
          ),
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildSendingPage(ThemeData theme) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              AppLabels.monitorSending,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletePage(ThemeData theme, AppColors colors) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 48, color: colors.success),
            const SizedBox(height: 16),
            Text(
              AppLabels.monitorComplete,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLabels.monitorCompleteDesc,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
