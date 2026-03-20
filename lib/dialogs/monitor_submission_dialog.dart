/// モニターデータ提出ダイアログ.
///
/// 招待コードユーザーの期限1週間前に表示し、
/// アンケート回答とアプリデータを一括送信する.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
            headers: {'Content-Type': 'application/json'},
            body: payload,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        setState(() {
          _currentStep = 3;
        });
      } else {
        setState(() {
          _error = '送信に失敗しました。後ほど再度お試しください。';
          _currentStep = 1;
        });
      }
    } on Exception {
      setState(() {
        _error = '通信エラーが発生しました。後ほど再度お試しください。';
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
          const Expanded(child: Text('モニターデータの提出')),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 500),
        child: SingleChildScrollView(
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
              child: const Text('あとで'),
            ),
            ElevatedButton(
              onPressed: () => setState(() => _currentStep = 1),
              child: const Text('回答する'),
            ),
          ],
        1 => [
            TextButton(
              onPressed: () => setState(() => _currentStep = 0),
              child: const Text('戻る'),
            ),
            ElevatedButton(
              onPressed: _usabilityRating > 0 ? _submit : null,
              child: const Text('提出する'),
            ),
          ],
        2 => [],
        3 => [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('閉じる'),
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
                      ? '招待プランの残り日数: ${widget.remainingDays}日'
                      : '招待プランの期限が終了しました',
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
          'モニターとしてアプリをご利用いただきありがとうございます。',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        Text(
          'アプリの改善のため、ご利用データと簡単なアンケートの'
          '提出にご協力をお願いいたします。',
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
                    'データの取り扱いについて',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '提出いただいたデータはアプリの改善を目的とした'
                '参考資料としてのみ使用いたします。\n'
                '第三者への提供や、改善目的以外での流用は一切行いません。',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '提出内容:',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        _buildBullet('アプリの使いやすさに関するアンケート（3問）', colors),
        _buildBullet('アプリ内の登録データ（夢・目標・タスク・書籍・活動ログ）', colors),
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
          'Q1. アプリの使いやすさはいかがでしたか？',
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
                ? ['', '使いにくい', 'やや使いにくい', '普通', '使いやすい', 'とても使いやすい'][_usabilityRating]
                : '星をタップして評価してください',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Q2: 良かった点
        Text(
          'Q2. 良かった点を教えてください（任意）',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: _goodPointController,
          decoration: const InputDecoration(
            hintText: '例: 夢から目標に落とし込む流れがわかりやすい',
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),

        // Q3: 改善点・要望
        Text(
          'Q3. 改善点やほしい機能はありますか？（任意）',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: _improvementController,
          decoration: const InputDecoration(
            hintText: '例: 通知機能がほしい、画面遷移が分かりにくい',
          ),
          maxLines: 2,
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
              'データを送信しています...',
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
              'ご協力ありがとうございます！',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'いただいたデータはアプリの改善に活用させていただきます。',
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
