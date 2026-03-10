/// マイルストーン（実績）ポップアップ.
library;

import 'package:flutter/material.dart';

import '../../services/study_stats_types.dart';
import '../../theme/app_theme.dart';

/// 実績一覧ダイアログ.
class MilestonePopup extends StatelessWidget {
  /// MilestonePopupを作成する.
  const MilestonePopup({super.key, required this.data});

  /// 実績データ.
  final MilestoneData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;

    return AlertDialog(
      title: Row(
        children: [
          const Text('\u{1F3C6}', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text('実績', style: theme.textTheme.titleLarge),
        ],
      ),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatRow(
              icon: '\u{23F0}',
              label: '累計活動時間',
              value: '${data.totalHours}時間',
              theme: theme,
            ),
            const SizedBox(height: 8),
            _StatRow(
              icon: '\u{1F4C5}',
              label: '累計活動日数',
              value: '${data.studyDays}日',
              theme: theme,
            ),
            const SizedBox(height: 8),
            _StatRow(
              icon: '\u{1F525}',
              label: '連続活動日数',
              value: '${data.currentStreak}日',
              theme: theme,
            ),
            const Divider(height: 24),
            if (data.achieved.isNotEmpty)
              ...data.achieved.map(
                (m) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '\u{2728} ${m.label}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
            else
              Text(
                'まだ実績はありません',
                style: TextStyle(color: colors.textMuted),
              ),
            if (data.nextMilestone != null) ...[
              const SizedBox(height: 12),
              Text(
                '次の目標: ${data.nextMilestone!.label}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('閉じる'),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
  });

  final String icon;
  final String label;
  final String value;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Text(label, style: theme.textTheme.bodyMedium),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
