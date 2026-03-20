/// 体験版の制限到達ダイアログ.
///
/// 制限に達した際にフィードバック送信による解除または課金を案内する.
library;

import 'package:flutter/material.dart';

import '../services/feedback_service.dart';
import '../services/trial_limit_service.dart';
import 'feedback_dialog.dart';
import 'upgrade_dialog.dart';

/// 体験版の制限到達ダイアログを表示する.
///
/// [itemName] は制限に達した項目名（例: '夢', '目標', 'タスク', '書籍'）.
/// [currentCount] は現在の登録数.
/// [maxCount] は制限数.
/// [feedbackService] はフィードバック送信・解除レベル管理用.
Future<void> showTrialLimitDialog(
  BuildContext context, {
  required String itemName,
  required int currentCount,
  required int maxCount,
  FeedbackService? feedbackService,
}) async {
  await showDialog<void>(
    context: context,
    builder: (context) => _TrialLimitDialog(
      itemName: itemName,
      currentCount: currentCount,
      maxCount: maxCount,
      feedbackService: feedbackService,
    ),
  );
}

class _TrialLimitDialog extends StatelessWidget {
  const _TrialLimitDialog({
    required this.itemName,
    required this.currentCount,
    required this.maxCount,
    this.feedbackService,
  });

  final String itemName;
  final int currentCount;
  final int maxCount;
  final FeedbackService? feedbackService;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final level = feedbackService?.unlockLevel ?? 0;
    final isMaxLevel = feedbackService?.isMaxLevel ?? false;
    final isFeedbackMax = feedbackService?.isFeedbackMaxLevel ?? false;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.lock_outline,
            size: 24,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text('$itemNameの上限に達しました')),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _UsageBar(current: currentCount, max: maxCount, itemName: itemName),
          const SizedBox(height: 16),
          Text(
            'スタータープランでは$itemNameを$maxCount件まで登録できます。',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          if (!isMaxLevel && !isFeedbackMax) ...[
            // フィードバックで解除可能
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'フィードバックで制限を解除',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text('アプリの改善にご協力いただくと、'
                      '制限が段階的に解除されます。'),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ] else if (!isMaxLevel && isFeedbackMax) ...[
            // フィードバック上限到達 → 課金案内
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiary.withAlpha(15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.tertiary.withAlpha(40),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'さらに制限を解除するには',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text('フィードバックによる解除は上限に達しました。\n'
                      'すべての機能を無制限で使うには、\n'
                      '有料プランをご検討ください。'),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            trialLimitDescription(unlockLevel: level),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.hintColor,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('閉じる'),
        ),
        if (!isMaxLevel && feedbackService != null)
          if (!isFeedbackMax)
            FilledButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                if (!context.mounted) return;
                await showFeedbackDialog(context, feedbackService!);
              },
              icon: const Icon(Icons.rate_review, size: 18),
              label: const Text('フィードバックを送信'),
            )
          else
            FilledButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                if (!context.mounted) return;
                await showUpgradeDialog(context);
              },
              icon: const Icon(Icons.star, size: 18),
              label: const Text('無制限プランを見る'),
            ),
      ],
    );
  }
}

/// 使用量バー.
class _UsageBar extends StatelessWidget {
  const _UsageBar({
    required this.current,
    required this.max,
    required this.itemName,
  });

  final int current;
  final int max;
  final String itemName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = (current / max).clamp(0.0, 1.0);
    final isAtLimit = current >= max;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(itemName, style: theme.textTheme.labelMedium),
            Text(
              '$current / $max',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isAtLimit ? theme.colorScheme.error : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(
              isAtLimit
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}
