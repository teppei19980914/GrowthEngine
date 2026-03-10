/// 目標別統計セクション.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/dashboard_providers.dart';
import '../../services/study_stats_types.dart';
import '../../theme/app_theme.dart';


/// 目標別統計の表示用データ.
class GoalStatsDisplayData {
  /// GoalStatsDisplayDataを作成する.
  const GoalStatsDisplayData({
    required this.name,
    required this.color,
    required this.stats,
    this.taskNames = const {},
  });

  /// 目標名.
  final String name;

  /// カラーコード.
  final String color;

  /// 活動統計.
  final GoalStudyStats stats;

  /// タスクID→タスク名のマップ.
  final Map<String, String> taskNames;
}

/// 目標/読書モード.
enum _StatsMode { goals, books }

/// 目標別統計セクション.
class GoalStatsSection extends ConsumerStatefulWidget {
  /// GoalStatsSectionを作成する.
  const GoalStatsSection({super.key});

  @override
  ConsumerState<GoalStatsSection> createState() => _GoalStatsSectionState();
}

class _GoalStatsSectionState extends ConsumerState<GoalStatsSection> {
  _StatsMode _mode = _StatsMode.goals;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final dataAsync = _mode == _StatsMode.goals
        ? ref.watch(goalStatsProvider)
        : ref.watch(bookStatsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assessment_outlined, size: 20, color: colors.accent),
                const SizedBox(width: 8),
                Text('目標別統計', style: theme.textTheme.titleMedium),
                const Spacer(),
                SegmentedButton<_StatsMode>(
                  segments: const [
                    ButtonSegment(
                      value: _StatsMode.goals,
                      label: Text('目標'),
                    ),
                    ButtonSegment(
                      value: _StatsMode.books,
                      label: Text('読書'),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (selected) {
                    setState(() => _mode = selected.first);
                  },
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    textStyle: WidgetStatePropertyAll(
                      theme.textTheme.labelSmall,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            dataAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        _mode == _StatsMode.goals
                            ? '目標がありません'
                            : '読書データがありません',
                        style: TextStyle(color: colors.textMuted),
                      ),
                    ),
                  );
                }
                return Column(
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      if (i > 0) const Divider(height: 16),
                      _GoalStatsCard(data: items[i], colors: colors),
                    ],
                  ],
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, _) => const Text('エラーが発生しました'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalStatsCard extends StatelessWidget {
  const _GoalStatsCard({required this.data, required this.colors});

  final GoalStatsDisplayData data;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _parseColor(data.color);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 4, height: 20, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                data.name,
                style: theme.textTheme.titleSmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final taskStat in data.stats.taskStats)
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    data.taskNames[taskStat.taskId] ?? taskStat.taskId,
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${_formatDuration(taskStat.totalMinutes)} / ${taskStat.studyDays}日',
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ),
        if (data.stats.taskStats.length > 1)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '合計',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${_formatDuration(data.stats.totalMinutes)} / ${data.stats.totalStudyDays}日',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _formatDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0) return '${h}h${m.toString().padLeft(2, '0')}min';
    return '${m}min';
  }

  Color _parseColor(String hex) {
    final hexStr = hex.replaceAll('#', '');
    return Color(int.parse('FF$hexStr', radix: 16));
  }
}
