/// 課金案内ダイアログ.
///
/// フィードバックによる制限解除が上限に達した後、
/// プレミアム機能へのアップグレードを案内する.
library;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// プレミアム機能の一覧.
const _premiumFeatures = [
  (Icons.view_timeline_outlined, 'ガントチャート', 'タスクの日程をタイムラインでビジュアル管理'),
  (Icons.file_download_outlined, 'Excel出力', 'ガントチャートをExcelエクスポートして共有'),
  (Icons.bar_chart, '目標別統計', '目標・タスクごとの活動時間を詳細分析'),
  (Icons.show_chart, 'アクティビティチャート', '日・週・月・年単位の活動推移をグラフ表示'),
  (Icons.menu_book, '読書スケジュール', '書籍の読書計画をガントチャートで管理'),
  (Icons.add_circle_outline, '今後の新機能すべて', '追加される最新機能を最優先で利用可能'),
];

/// 課金案内ダイアログを表示する.
Future<void> showUpgradeDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (context) => const _UpgradeDialog(),
  );
}

class _UpgradeDialog extends StatelessWidget {
  const _UpgradeDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.star, size: 24, color: colors.accent),
          const SizedBox(width: 8),
          const Expanded(child: Text('プレミアムプランのご案内')),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'プレミアムプランでは以下の機能が全てご利用いただけます。',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),

              // プレミアム機能一覧
              ...(_premiumFeatures.map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(f.$1, size: 20, color: colors.accent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              f.$2,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              f.$3,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.hintColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              // プラン選択
              Text(
                'プランを選択',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // ネイティブアプリ
              _PlanCard(
                icon: Icons.install_desktop,
                iconColor: colors.accent,
                title: 'ネイティブアプリ（買い切り）',
                description:
                    'Windows / macOS / Android / iOS 対応。'
                    'オフライン利用可能。全プレミアム機能が永久利用可能。',
                badge: '買い切り',
                badgeColor: colors.success,
                theme: theme,
              ),
              const SizedBox(height: 10),

              // Web有料プラン
              _PlanCard(
                icon: Icons.language,
                iconColor: colors.success,
                title: 'Webプレミアムプラン（サブスク）',
                description:
                    'ブラウザからそのまま全機能を利用可能。'
                    'どのデバイスからもアクセス可能。',
                badge: 'サブスク',
                badgeColor: colors.accent,
                theme: theme,
              ),
              const SizedBox(height: 12),

              // 注意書き
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.error.withAlpha(60),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        size: 18, color: theme.colorScheme.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ネイティブアプリとWebプレミアムは別々のサービスです。\n'
                        'それぞれ別途ご契約が必要です。',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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

/// プランカード.
class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.badge,
    required this.badgeColor,
    required this.theme,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String badge;
  final Color badgeColor;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: badgeColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
