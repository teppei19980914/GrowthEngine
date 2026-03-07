/// フィードバック送信ダイアログ.
///
/// カテゴリ選択、テキスト入力（100文字以上）、
/// バリデーション付きのフィードバックフォームを提供する.
library;

import 'package:flutter/material.dart';

import '../services/feedback_service.dart';

/// フィードバックダイアログを表示する.
///
/// 送信成功時は true を返す.
Future<bool> showFeedbackDialog(
  BuildContext context,
  FeedbackService feedbackService,
) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _FeedbackDialog(feedbackService: feedbackService),
  );
  return result ?? false;
}

class _FeedbackDialog extends StatefulWidget {
  const _FeedbackDialog({required this.feedbackService});

  final FeedbackService feedbackService;

  @override
  State<_FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<_FeedbackDialog> {
  final _controller = TextEditingController();
  FeedbackCategory? _category;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textLength = _controller.text.trim().length;
    final remaining = feedbackMinLength - textLength;
    final currentLevel = widget.feedbackService.unlockLevel;
    final nextLevel = (currentLevel + 1).clamp(0, feedbackMaxLevel);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.rate_review_outlined,
              size: 24, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Expanded(child: Text('フィードバックを送信')),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 解除レベル情報
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.primary.withAlpha(40),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock_open,
                        size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '送信すると制限がレベル$nextLevelに解除されます'
                        '（現在: レベル$currentLevel / $feedbackMaxLevel）',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // カテゴリ選択
              Text('カテゴリ *', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              DropdownButtonFormField<FeedbackCategory>(
                value: _category,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'カテゴリを選択してください',
                ),
                items: FeedbackCategory.values
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.label),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _category = value),
              ),
              const SizedBox(height: 16),

              // テキスト入力
              Row(
                children: [
                  Text('ご意見・ご感想 *', style: theme.textTheme.labelLarge),
                  const Spacer(),
                  Text(
                    remaining > 0
                        ? 'あと$remaining文字'
                        : '$textLength文字',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: remaining > 0
                          ? theme.colorScheme.error
                          : theme.hintColor,
                      fontWeight:
                          remaining > 0 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                maxLines: 8,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'アプリの改善点や使いにくい部分、\n'
                      '欲しい機能などをお聞かせください。\n\n'
                      '具体的なご意見は開発の参考になります。',
                  alignLabelWithHint: true,
                ),
                onChanged: (_) => setState(() => _errorMessage = null),
              ),
              const SizedBox(height: 8),

              // 文字数プログレスバー
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (textLength / feedbackMinLength).clamp(0.0, 1.0),
                  minHeight: 4,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(
                    textLength >= feedbackMinLength
                        ? theme.colorScheme.primary
                        : theme.colorScheme.error,
                  ),
                ),
              ),

              // エラーメッセージ
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('キャンセル'),
        ),
        FilledButton.icon(
          onPressed: _submitting ? null : _submit,
          icon: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send, size: 18),
          label: Text(_submitting ? '送信中...' : '送信する'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_category == null) {
      setState(() => _errorMessage = 'カテゴリの選択は必須です');
      return;
    }

    final validation =
        widget.feedbackService.validateFeedback(_controller.text);
    if (!validation.isValid) {
      setState(() => _errorMessage = validation.errorMessage);
      return;
    }

    setState(() => _submitting = true);

    final result = await widget.feedbackService.submitFeedback(
      category: _category!,
      text: _controller.text,
    );

    if (!mounted) return;

    if (result.success) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.newLevel >= feedbackMaxLevel
                ? 'ありがとうございます！制限が完全に解除されました'
                : 'ありがとうございます！制限がレベル${result.newLevel}に解除されました',
          ),
        ),
      );
    } else {
      setState(() {
        _submitting = false;
        _errorMessage = result.errorMessage;
      });
    }
  }
}
