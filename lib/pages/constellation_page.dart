/// 星座ページ.
///
/// 総合活動時間に応じて12星座が順番に完成していく.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/constellations.dart';
import '../models/constellation.dart';
import '../providers/constellation_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/constellation/constellation_painter.dart';

/// 星座ページ.
class ConstellationPage extends ConsumerWidget {
  /// ConstellationPageを作成する.
  const ConstellationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(constellationProgressProvider);
    final theme = Theme.of(context);
    final colors = theme.appColors;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー
          Text(
            '活動時間に応じて星が灯り、星座が完成します。'
            '${minutesPerStar ~/ 60}時間ごとに1つの星が輝きます。',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),

          // 総合進捗
          progressAsync.when(
            data: (overall) => _OverallProgressBar(overall: overall),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),

          // 星座リスト
          Expanded(
            child: progressAsync.when(
              data: (overall) {
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 400,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: overall.constellations.length,
                  itemBuilder: (_, index) => _ConstellationCard(
                    progress: overall.constellations[index],
                  ),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text('エラーが発生しました: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 総合進捗バー.
class _OverallProgressBar extends StatelessWidget {
  const _OverallProgressBar({required this.overall});

  final ConstellationOverallProgress overall;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${overall.completedCount}/${constellations.length} 星座完成'
              '　${overall.totalLitStars}/${overall.totalStars} 星',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            Text(
              '${overall.totalHours.toStringAsFixed(1)}h',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: overall.overallCompletionRate,
            minHeight: 6,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(
              overall.completedCount >= constellations.length
                  ? const Color(0xFFFFD700)
                  : theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}

/// 個別の星座カード.
class _ConstellationCard extends StatelessWidget {
  const _ConstellationCard({required this.progress});

  final ConstellationProgress progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final constellation = progress.constellation;
    final isDark = theme.brightness == Brightness.dark;
    final hasDescription = constellation.description.isNotEmpty;

    return Card(
      clipBehavior: Clip.antiAlias,
      color: isDark
          ? const Color(0xFF1A1A2E)
          : const Color(0xFFF0F4F8),
      child: InkWell(
        onTap: progress.isComplete && hasDescription
            ? () => _showDescriptionDialog(context)
            : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // タイトル行
              Row(
                children: [
                  Text(
                    constellation.symbol,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      constellation.jaName,
                      style: theme.textTheme.titleSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (progress.isComplete)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '完成',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: const Color(0xFFFFD700),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // 星座描画エリア
              Expanded(
                child: ConstellationWidget(progress: progress),
              ),

              const SizedBox(height: 8),

              // 進捗バー
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.completionRate,
                  minHeight: 4,
                  backgroundColor: isDark
                      ? Colors.white.withAlpha(15)
                      : Colors.black.withAlpha(10),
                  valueColor: AlwaysStoppedAnimation(
                    progress.isComplete
                        ? const Color(0xFFFFD700)
                        : theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 4),

              // 統計行
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${progress.litStarCount}/${constellation.starCount} 星',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.textMuted,
                    ),
                  ),
                  if (progress.isComplete && hasDescription)
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: colors.textMuted,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDescriptionDialog(BuildContext context) {
    final theme = Theme.of(context);
    final constellation = progress.constellation;
    final isDark = theme.brightness == Brightness.dark;

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(
              constellation.symbol,
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    constellation.jaName,
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(
                    constellation.name,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? Colors.white60
                          : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Text(
          constellation.description,
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.6,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
}
