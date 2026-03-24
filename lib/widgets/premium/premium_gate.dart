/// プレミアム機能ゲートウィジェット.
///
/// Web体験版ではプレミアム機能をブラーオーバーレイでロックし、
/// アップグレードへの誘導を表示する.
/// サブスクプラン（isPremium=true）では通常表示する.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../dialogs/upgrade_dialog.dart';
import '../../services/trial_limit_service.dart';
import '../../theme/app_theme.dart';

/// フルページのプレミアムゲート.
///
/// [featureName] に機能名、[featureIcon] にアイコン、
/// [premiumPoints] に訴求ポイントを渡す.
/// [previewChild] を渡すとその内容をブラーで背景表示する.
class PremiumGate extends StatelessWidget {
  /// PremiumGateを作成する.
  const PremiumGate({
    required this.featureName,
    required this.featureIcon,
    required this.premiumPoints,
    this.previewChild,
    super.key,
  });

  /// 機能名（例: 'ガントチャート'）.
  final String featureName;

  /// 機能を表すアイコン.
  final IconData featureIcon;

  /// プレミアム機能の訴求ポイント.
  final List<String> premiumPoints;

  /// ブラー表示するプレビューコンテンツ（省略時はデフォルト背景）.
  final Widget? previewChild;

  @override
  Widget build(BuildContext context) {
    if (!isTrialMode || isPremium) {
      return previewChild ?? const SizedBox.expand();
    }

    final theme = Theme.of(context);

    return Stack(
      children: [
        // 背景: ブラーをかけたプレビュー
        Positioned.fill(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: previewChild ?? _DefaultBackground(theme: theme),
          ),
        ),
        // 半透明の暗転オーバーレイ
        Positioned.fill(
          child: Container(
            color: theme.colorScheme.surface.withAlpha(160),
          ),
        ),
        // アップグレードカード（中央）
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _UpgradeCard(
              featureName: featureName,
              featureIcon: featureIcon,
              premiumPoints: premiumPoints,
            ),
          ),
        ),
      ],
    );
  }
}

/// セクション単位のプレミアムゲート（統計ページのインラインセクション用）.
class PremiumSectionGate extends StatelessWidget {
  /// PremiumSectionGateを作成する.
  const PremiumSectionGate({
    required this.featureName,
    required this.featureIcon,
    required this.premiumPoints,
    super.key,
  });

  /// 機能名.
  final String featureName;

  /// アイコン.
  final IconData featureIcon;

  /// 訴求ポイント.
  final List<String> premiumPoints;

  @override
  Widget build(BuildContext context) {
    if (!isTrialMode || isPremium) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colors = theme.appColors;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.accent.withAlpha(80)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(featureIcon, size: 20, color: colors.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    featureName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.accent.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 12, color: colors.accent),
                      const SizedBox(width: 4),
                      Text(
                        'プレミアム',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...premiumPoints.map(
              (point) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.check, size: 14, color: colors.success),
                    const SizedBox(width: 6),
                    Text(point, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => showUpgradeDialog(context),
                icon: const Icon(Icons.upgrade, size: 16),
                label: const Text('プレミアムプランを見る'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.accent,
                  side: BorderSide(color: colors.accent),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// アップグレードカード（フルページゲート用）.
class _UpgradeCard extends StatelessWidget {
  const _UpgradeCard({
    required this.featureName,
    required this.featureIcon,
    required this.premiumPoints,
  });

  final String featureName;
  final IconData featureIcon;
  final List<String> premiumPoints;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Card(
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // プレミアムバッジ
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.accent.withAlpha(30),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 14, color: colors.accent),
                    const SizedBox(width: 4),
                    Text(
                      'プレミアム機能',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // アイコン
              Icon(featureIcon, size: 56, color: colors.accent),
              const SizedBox(height: 12),
              // 機能名
              Text(
                featureName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'プレミアムプランで利用できます',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
              const SizedBox(height: 20),
              // 訴求ポイント
              ...premiumPoints.map(
                (point) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 18,
                        color: colors.success,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          point,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // CTAボタン
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => showUpgradeDialog(context),
                  icon: const Icon(Icons.upgrade),
                  label: const Text('プレミアムプランを見る'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// デフォルト背景（previewChild未指定時のブラー背景）.
class _DefaultBackground extends StatelessWidget {
  const _DefaultBackground({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    // ガントチャート風のフェイクプレビュー
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ヘッダー行
          _FakeRow(theme: theme, labelWidth: 160, isHeader: true),
          const SizedBox(height: 6),
          // タスク行
          _FakeRow(
            theme: theme,
            labelWidth: 120,
            barStart: 0.05,
            barEnd: 0.45,
            color: const Color(0xFF89B4FA),
          ),
          const SizedBox(height: 4),
          _FakeRow(
            theme: theme,
            labelWidth: 140,
            barStart: 0.1,
            barEnd: 0.6,
            color: const Color(0xFFA6E3A1),
          ),
          const SizedBox(height: 4),
          _FakeRow(
            theme: theme,
            labelWidth: 100,
            barStart: 0.3,
            barEnd: 0.75,
            color: const Color(0xFFF38BA8),
          ),
          const SizedBox(height: 4),
          _FakeRow(
            theme: theme,
            labelWidth: 130,
            barStart: 0.5,
            barEnd: 0.9,
            color: const Color(0xFFFAB387),
          ),
          const SizedBox(height: 4),
          _FakeRow(
            theme: theme,
            labelWidth: 110,
            barStart: 0.15,
            barEnd: 0.55,
            color: const Color(0xFFCBA6F7),
          ),
        ],
      ),
    );
  }
}

class _FakeRow extends StatelessWidget {
  const _FakeRow({
    required this.theme,
    required this.labelWidth,
    this.isHeader = false,
    this.barStart,
    this.barEnd,
    this.color,
  });

  final ThemeData theme;
  final double labelWidth;
  final bool isHeader;
  final double? barStart;
  final double? barEnd;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final surface = theme.colorScheme.surfaceContainerHighest;
    return SizedBox(
      height: isHeader ? 24 : 32,
      child: Row(
        children: [
          Container(
            width: labelWidth,
            decoration: BoxDecoration(
              color: isHeader
                  ? theme.colorScheme.primary.withAlpha(120)
                  : surface,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: isHeader
                ? Row(
                    children: List.generate(
                      14,
                      (i) => Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final w = constraints.maxWidth;
                      final start = (barStart ?? 0) * w;
                      final width = ((barEnd ?? 1) - (barStart ?? 0)) * w;
                      return Stack(
                        children: [
                          Container(color: surface.withAlpha(80)),
                          Positioned(
                            left: start,
                            width: width,
                            top: 4,
                            bottom: 4,
                            child: Container(
                              decoration: BoxDecoration(
                                color: color ?? theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
