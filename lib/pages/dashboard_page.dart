/// ダッシュボードページ.
///
/// カスタマイズ可能なウィジェットグリッドで学習状況を一覧表示する.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/book.dart';
import '../providers/constellation_providers.dart';
import '../providers/dashboard_providers.dart';
import '../providers/theme_provider.dart';
import '../widgets/constellation/constellation_painter.dart';
import '../widgets/web/web_trial_banner.dart';
import '../providers/service_providers.dart';
import '../services/dashboard_layout_service.dart';
import '../services/remote_config_service.dart';
import '../services/study_stats_types.dart';
import '../theme/app_theme.dart';


/// ダッシュボードページ.
class DashboardPage extends ConsumerStatefulWidget {
  /// DashboardPageを作成する.
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  bool _editMode = false;
  bool _webDialogChecked = false;
  bool _resetChecked = false;

  @override
  Widget build(BuildContext context) {
    final layoutAsync = ref.watch(dashboardLayoutProvider);
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final prefs = ref.watch(sharedPreferencesProvider);

    // resetOnAccess: データベースリセット処理
    if (!_resetChecked) {
      _resetChecked = true;
      if (prefs.getBool(resetPendingKey) ?? false) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          final service = ref.read(dataExportServiceProvider);
          await service.clearAllData();
          await prefs.remove(resetPendingKey);
        });
      }
    }

    // Web体験版の初回ダイアログ表示
    if (!_webDialogChecked) {
      _webDialogChecked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showWebTrialDialogIfNeeded(context, prefs);
        }
      });
    }

    return layoutAsync.when(
      data: (layout) => Column(
        children: [
          // Web体験版バナー
          WebTrialBanner(prefs: prefs),
          // 編集モードバー
          _EditModeBar(
            editMode: _editMode,
            onToggle: () => setState(() => _editMode = !_editMode),
            onReset: () =>
                ref.read(dashboardLayoutProvider.notifier).resetToDefault(),
            colors: colors,
          ),
          // ウィジェットグリッド
          Expanded(
            child: _editMode
                ? _buildEditableGrid(context, layout, colors)
                : _buildGrid(context, layout),
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('エラー: $error')),
    );
  }

  Widget _buildGrid(BuildContext context, List<DashboardWidgetConfig> layout) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final spacing = 12.0;
          final halfWidth = (constraints.maxWidth - spacing) / 2;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final config in layout)
                SizedBox(
                  width: config.columnSpan == 2
                      ? constraints.maxWidth
                      : halfWidth,
                  child: _DashboardWidgetCard(config: config),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEditableGrid(
    BuildContext context,
    List<DashboardWidgetConfig> layout,
    AppColors colors,
  ) {
    final notifier = ref.read(dashboardLayoutProvider.notifier);
    final service = ref.read(dashboardLayoutServiceProvider);
    final available = service.getAvailableWidgets(layout);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 配置済みウィジェット
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: layout.length,
            onReorder: (from, to) {
              if (to > from) to--;
              notifier.reorder(from, to);
            },
            itemBuilder: (context, index) {
              final config = layout[index];
              final meta = widgetRegistry[config.widgetType];
              return ListTile(
                key: ValueKey('edit_$index'),
                leading: Text(meta?.icon ?? '?', style: const TextStyle(fontSize: 20)),
                title: Text(meta?.displayName ?? config.widgetType),
                subtitle: Text(
                  'スパン: ${config.columnSpan}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.aspect_ratio, size: 20),
                      onPressed: () => notifier.resizeWidget(index),
                      tooltip: 'サイズ変更',
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          size: 20, color: colors.error),
                      onPressed: () => notifier.removeWidget(index),
                      tooltip: '削除',
                    ),
                  ],
                ),
              );
            },
          ),
          // 追加可能ウィジェット
          if (available.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              '追加可能なウィジェット',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final meta in available)
                  ActionChip(
                    avatar: Text(meta.icon),
                    label: Text(meta.displayName),
                    onPressed: () => notifier.addWidget(meta.widgetType),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// 編集モードバー.
class _EditModeBar extends StatelessWidget {
  const _EditModeBar({
    required this.editMode,
    required this.onToggle,
    required this.onReset,
    required this.colors,
  });

  final bool editMode;
  final VoidCallback onToggle;
  final VoidCallback onReset;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (editMode)
            TextButton.icon(
              onPressed: onReset,
              icon: Icon(Icons.restore, size: 18, color: colors.warning),
              label: Text(
                'リセット',
                style: TextStyle(color: colors.warning),
              ),
            ),
          IconButton(
            icon: Icon(
              editMode ? Icons.check : Icons.edit_outlined,
              size: 20,
            ),
            onPressed: onToggle,
            tooltip: editMode ? '完了' : '編集',
          ),
        ],
      ),
    );
  }
}

/// 個別ダッシュボードウィジェットカード.
class _DashboardWidgetCard extends ConsumerWidget {
  const _DashboardWidgetCard({required this.config});

  final DashboardWidgetConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.appColors;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildContent(context, ref, theme, colors),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    AppColors colors,
  ) {
    return switch (config.widgetType) {
      'today_banner' => _TodayBannerContent(colors: colors),
      'total_time_card' => _TotalTimeContent(colors: colors),
      'study_days_card' => _StudyDaysContent(colors: colors),
      'dream_count_card' => _DreamCountContent(colors: colors),
      'goal_count_card' => _GoalCountContent(colors: colors),
      'streak_card' => _StreakContent(colors: colors),
      'bookshelf' => _BookshelfContent(colors: colors),
      'personal_record' => _PersonalRecordContent(colors: colors),
      'consistency' => _ConsistencyContent(colors: colors),
      'daily_chart' => _DailyChartContent(colors: colors),
      'constellation_preview' => const _ConstellationPreviewContent(),
      _ => Center(
          child: Text(
            config.widgetType,
            style: TextStyle(color: colors.textMuted),
          ),
        ),
    };
  }
}

/// 今日の学習バナー.
class _TodayBannerContent extends ConsumerWidget {
  const _TodayBannerContent({required this.colors});
  final AppColors colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(todayStudyProvider);
    final theme = Theme.of(context);

    return todayAsync.when(
      data: (data) {
        final hours = data.totalMinutes ~/ 60;
        final minutes = data.totalMinutes % 60;
        return Row(
          children: [
            Icon(
              data.studied ? Icons.check_circle : Icons.circle_outlined,
              color: data.studied ? colors.success : colors.textMuted,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    data.studied ? '今日は学習済み!' : 'まだ学習していません',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (data.studied)
                    Text(
                      '$hours時間$minutes分 / ${data.sessionCount}セッション',
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const _WidgetLoading(),
      error: (_, _) => const _WidgetError(),
    );
  }
}

/// 合計学習時間カード.
class _TotalTimeContent extends ConsumerWidget {
  const _TotalTimeContent({required this.colors});
  final AppColors colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordAsync = ref.watch(personalRecordProvider);
    final theme = Theme.of(context);

    return recordAsync.when(
      data: (data) => _StatDisplay(
        icon: Icons.timer_outlined,
        iconColor: colors.accent,
        label: '合計学習時間',
        value: '${data.totalHours.toStringAsFixed(1)}h',
        theme: theme,
      ),
      loading: () => const _WidgetLoading(),
      error: (_, _) => const _WidgetError(),
    );
  }
}

/// 学習日数カード.
class _StudyDaysContent extends ConsumerWidget {
  const _StudyDaysContent({required this.colors});
  final AppColors colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordAsync = ref.watch(personalRecordProvider);
    final theme = Theme.of(context);

    return recordAsync.when(
      data: (data) => _StatDisplay(
        icon: Icons.calendar_today_outlined,
        iconColor: colors.success,
        label: '学習日数',
        value: '${data.totalStudyDays}日',
        theme: theme,
      ),
      loading: () => const _WidgetLoading(),
      error: (_, _) => const _WidgetError(),
    );
  }
}

/// 夢の数カード.
class _DreamCountContent extends ConsumerWidget {
  const _DreamCountContent({required this.colors});
  final AppColors colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(dreamCountProvider);
    final theme = Theme.of(context);

    return countAsync.when(
      data: (count) => _StatDisplay(
        icon: Icons.auto_awesome_outlined,
        iconColor: colors.accent,
        label: '夢の数',
        value: '$count',
        theme: theme,
      ),
      loading: () => const _WidgetLoading(),
      error: (_, _) => const _WidgetError(),
    );
  }
}

/// 目標数カード.
class _GoalCountContent extends ConsumerWidget {
  const _GoalCountContent({required this.colors});
  final AppColors colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(goalCountProvider);
    final theme = Theme.of(context);

    return countAsync.when(
      data: (count) => _StatDisplay(
        icon: Icons.flag_outlined,
        iconColor: colors.warning,
        label: '目標数',
        value: '$count',
        theme: theme,
      ),
      loading: () => const _WidgetLoading(),
      error: (_, _) => const _WidgetError(),
    );
  }
}

/// ストリークカード.
class _StreakContent extends ConsumerWidget {
  const _StreakContent({required this.colors});
  final AppColors colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(streakProvider);
    final theme = Theme.of(context);

    return streakAsync.when(
      data: (data) => _StatDisplay(
        icon: Icons.local_fire_department_outlined,
        iconColor: colors.error,
        label: '連続学習',
        value: '${data.currentStreak}日',
        subtitle: '最長: ${data.longestStreak}日',
        theme: theme,
      ),
      loading: () => const _WidgetLoading(),
      error: (_, _) => const _WidgetError(),
    );
  }
}

/// 本棚ウィジェット.
class _BookshelfContent extends ConsumerWidget {
  const _BookshelfContent({required this.colors});
  final AppColors colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shelfAsync = ref.watch(bookshelfProvider);
    final theme = Theme.of(context);

    return shelfAsync.when(
      data: (data) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book_outlined, size: 20, color: colors.accent),
              const SizedBox(width: 8),
              Text('本棚', style: theme.textTheme.titleSmall),
              const Spacer(),
              Text(
                '${data.completedCount}/${data.totalCount}冊 読了',
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
          if (data.readingCount > 0) ...[
            const SizedBox(height: 4),
            Text(
              '読書中: ${data.readingCount}冊',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
          if (data.recentCompleted.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...data.recentCompleted.take(3).map((book) {
              final b = book as Book;
              final dateStr = b.completedDate != null
                  ? DateFormat('yyyy/MM/dd').format(b.completedDate!)
                  : '';
              return Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    Icon(Icons.check, size: 14, color: colors.success),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        b.title,
                        style: theme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (dateStr.isNotEmpty)
                      Text(
                        dateStr,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
      loading: () => const _WidgetLoading(),
      error: (_, _) => const _WidgetError(),
    );
  }
}

/// 自己ベストカード.
class _PersonalRecordContent extends ConsumerWidget {
  const _PersonalRecordContent({required this.colors});
  final AppColors colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordAsync = ref.watch(personalRecordProvider);
    final theme = Theme.of(context);

    return recordAsync.when(
      data: (data) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events_outlined, size: 20, color: colors.warning),
              const SizedBox(width: 8),
              Text('自己ベスト', style: theme.textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 8),
          _RecordRow(
            label: '1日最高',
            value: _formatMinutes(data.bestDayMinutes),
            colors: colors,
          ),
          _RecordRow(
            label: '1週間最高',
            value: _formatMinutes(data.bestWeekMinutes),
            colors: colors,
          ),
          _RecordRow(
            label: '最長連続',
            value: '${data.longestStreak}日',
            colors: colors,
          ),
        ],
      ),
      loading: () => const _WidgetLoading(),
      error: (_, _) => const _WidgetError(),
    );
  }

  String _formatMinutes(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0) return '${h}h${m}m';
    return '${m}m';
  }
}

/// 実施率カード.
class _ConsistencyContent extends ConsumerWidget {
  const _ConsistencyContent({required this.colors});
  final AppColors colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consistAsync = ref.watch(consistencyProvider);
    final theme = Theme.of(context);

    return consistAsync.when(
      data: (data) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_outlined, size: 20, color: colors.accent),
              const SizedBox(width: 8),
              Text('学習の実施率', style: theme.textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 8),
          // 全体実施率バー
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: data.overallRate.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: colors.border,
                    valueColor: AlwaysStoppedAnimation(colors.accent),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(data.overallRate * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '今週: ${data.thisWeekDays}日 / 今月: ${data.thisMonthDays}日',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
      loading: () => const _WidgetLoading(),
      error: (_, _) => const _WidgetError(),
    );
  }
}

/// アクティビティチャート.
class _DailyChartContent extends ConsumerWidget {
  const _DailyChartContent({required this.colors});
  final AppColors colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(dailyActivityProvider);
    final theme = Theme.of(context);

    return activityAsync.when(
      data: (data) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart, size: 20, color: colors.success),
              const SizedBox(width: 8),
              Text('学習アクティビティ (30日)', style: theme.textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: _MiniBarChart(data: data, colors: colors),
          ),
        ],
      ),
      loading: () => const _WidgetLoading(),
      error: (_, _) => const _WidgetError(),
    );
  }
}

/// ミニバーチャート（30日間アクティビティ表示）.
class _MiniBarChart extends StatelessWidget {
  const _MiniBarChart({required this.data, required this.colors});

  final DailyActivityData data;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    if (data.days.isEmpty || data.maxMinutes == 0) {
      return Center(
        child: Text(
          'データなし',
          style: TextStyle(color: colors.textMuted, fontSize: 12),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth =
            (constraints.maxWidth - (data.days.length - 1)) / data.days.length;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < data.days.length; i++) ...[
              if (i > 0) const SizedBox(width: 1),
              SizedBox(
                width: barWidth,
                child: FractionallySizedBox(
                  heightFactor:
                      (data.days[i].totalMinutes / data.maxMinutes)
                          .clamp(0.0, 1.0),
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    decoration: BoxDecoration(
                      color: data.days[i].totalMinutes > 0
                          ? colors.accent
                          : colors.border.withAlpha(50),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// 統計表示ヘルパー.
class _StatDisplay extends StatelessWidget {
  const _StatDisplay({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.theme,
    this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final ThemeData theme;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 6),
            Text(label, style: theme.textTheme.labelMedium),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (subtitle != null)
          Text(subtitle!, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

/// レコード行ヘルパー.
class _RecordRow extends StatelessWidget {
  const _RecordRow({
    required this.label,
    required this.value,
    required this.colors,
  });

  final String label;
  final String value;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// ウィジェットローディング表示.
class _WidgetLoading extends StatelessWidget {
  const _WidgetLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 40,
      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}

/// ウィジェットエラー表示.
class _WidgetError extends StatelessWidget {
  const _WidgetError();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 40,
      child: Center(child: Icon(Icons.error_outline, size: 20)),
    );
  }
}

/// 星座プレビュー（ダッシュボード用）.
class _ConstellationPreviewContent extends ConsumerWidget {
  const _ConstellationPreviewContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(constellationProgressProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return progressAsync.when(
      data: (progressList) {
        if (progressList.isEmpty) {
          return Center(
            child: Text(
              '夢を追加すると星座が表示されます',
              style: theme.textTheme.bodySmall,
            ),
          );
        }
        // 最も進捗が高い星座を表示
        final best = progressList.reduce(
          (a, b) => a.completionRate >= b.completionRate ? a : b,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  best.constellation.symbol,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    best.dreamTitle,
                    style: theme.textTheme.labelMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${best.litStarCount}/${best.constellation.starCount}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: best.isComplete
                        ? const Color(0xFFFFD700)
                        : theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1A1A2E).withAlpha(150)
                      : const Color(0xFFF0F4F8).withAlpha(150),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ConstellationWidget(
                  progress: best,
                  compact: true,
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const _WidgetLoading(),
      error: (_, _) => const _WidgetError(),
    );
  }
}
