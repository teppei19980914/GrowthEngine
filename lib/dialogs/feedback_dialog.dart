/// フィードバック送信ダイアログ.
///
/// カテゴリ選択、テキスト入力（15文字以上）、
/// バリデーション付きのフィードバックフォームを提供する.
library;

import 'package:flutter/material.dart';

import '../l10n/app_labels.dart';
import '../widgets/app_snackbar.dart';
import '../services/feedback_service.dart';
import '../services/trial_limit_service.dart' show isPremium;

/// フィードバックダイアログを表示する.
///
/// 送信成功時は true を返す.
/// [userKey] はリモート設定のユーザーキー（任意）.
Future<bool> showFeedbackDialog(
  BuildContext context,
  FeedbackService feedbackService, {
  String? userKey,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _FeedbackDialog(
      feedbackService: feedbackService,
      userKey: userKey,
    ),
  );
  return result ?? false;
}

class _FeedbackDialog extends StatefulWidget {
  const _FeedbackDialog({required this.feedbackService, this.userKey});

  final FeedbackService feedbackService;
  final String? userKey;

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
          const Expanded(child: Text(AppLabels.feedbackTitle)),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 解除レベル情報（プレミアムプランでは非表示）
              if (!isPremium) ...[
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
                      Icon(
                        currentLevel >= feedbackUnlockableLevel
                            ? Icons.favorite
                            : Icons.lock_open,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          currentLevel >= feedbackUnlockableLevel
                              ? AppLabels.feedbackThanksMessage
                              : AppLabels.feedbackUnlockNext(nextLevel, currentLevel, feedbackMaxLevel),
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
              ],

              // カテゴリ選択
              Text(AppLabels.feedbackCategory, style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              DropdownButtonFormField<FeedbackCategory>(
                initialValue: _category,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: AppLabels.feedbackSelectCategory,
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
                  Text(AppLabels.feedbackContent, style: theme.textTheme.labelLarge),
                  const Spacer(),
                  Text(
                    remaining > 0
                        ? AppLabels.feedbackRemainingChars(remaining)
                        : AppLabels.feedbackCharCount(textLength),
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
                maxLines: 5,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: AppLabels.feedbackGuide,
                  alignLabelWithHint: true,
                ),
                onChanged: (_) => setState(() => _errorMessage = null),
              ),
              const SizedBox(height: 8),

              // 匿名性の注記
              Row(
                children: [
                  Icon(Icons.shield_outlined,
                      size: 14, color: theme.hintColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      AppLabels.feedbackPrivacyNote,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ),
                ],
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
          child: const Text(AppLabels.btnCancel),
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
          label: Text(_submitting ? AppLabels.btnSending : AppLabels.btnSend),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_category == null) {
      setState(() => _errorMessage = AppLabels.feedbackCategoryRequired);
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
      userKey: widget.userKey,
    );

    if (!mounted) return;

    if (result.success) {
      Navigator.of(context).pop(true);
      showSuccessSnackBar(
        context,
        isPremium
            ? AppLabels.feedbackSuccessMax
            : widget.feedbackService.isFeedbackMaxLevel
                ? AppLabels.feedbackSuccessMax
                : result.newLevel >= feedbackMaxLevel
                    ? AppLabels.feedbackSuccessUnlockMax(result.newLevel)
                    : AppLabels.feedbackSuccessUnlock(result.newLevel),
      );
    } else {
      setState(() {
        _submitting = false;
        _errorMessage = result.errorMessage;
      });
    }
  }
}
