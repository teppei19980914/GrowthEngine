/// ダッシュボードページ.
///
/// カスタマイズ可能なウィジェットグリッドで活動状況を一覧表示する.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/constellations.dart';
import '../models/book.dart';
import '../providers/book_providers.dart';
import '../providers/constellation_providers.dart';
import '../providers/dashboard_providers.dart';
import '../providers/theme_provider.dart';
import '../widgets/constellation/constellation_painter.dart';
import '../widgets/tutorial/tutorial_banner.dart';
import '../widgets/web/web_trial_banner.dart';
import '../providers/service_providers.dart';
import '../services/dashboard_layout_service.dart';
import '../services/study_stats_types.dart';
import '../theme/app_theme.dart';
import '../dialogs/onboarding_dialog.dart';


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

  @override
  Widget build(BuildContext context) {
    final layoutAsync = ref.watch(dashboardLayoutProvider);
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final prefs = ref.watch(sharedPreferencesProvider);

    // 初回アクセス: オンボーディング → 体験版ダイアログ → チュートリアル確認
    if (!_webDialogChecked) {
      _webDialogChecked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;

        // オンボーディング（初回のみ表示）
        final onboarded = await showOnboardingDialog(context, prefs);
        if (!context.mounted) return;

        // ダイアログ間にゆったりとした間を入れる
        if (onboarded) {
          await Future<void>.delayed(const Duration(milliseconds: 400));
          if (!context.mounted) return;
        }

        final shown = await showWebTrialDialogIfNeeded(context, prefs);
        if (!shown || !context.mounted) return;

        await Future<void>.delayed(const Duration(milliseconds: 400));
        if (!context.mounted) return;

        // チュートリアル実行の確認ダイアログ
        final wantTutorial = await showGeneralDialog<bool>(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.black54,
          barrierLabel: 'Tutorial',
          transitionDuration: const Duration(milliseconds: 500),
          transitionBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          pageBuilder: (context, animation, secondaryAnimation) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.school, size: 24),
                SizedBox(width: 8),
                Text('アプリの使い方'),
              ],
            ),
            content: const Text(
              'アプリの基本的な使い方を説明しますか？\n'
              '実際の操作を通じて、夢・目標・タスクの登録方法を体験できます。',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('いいえ'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('はい'),
              ),
            ],
          ),
        );

        if (wantTutorial == true && mounted) {
          final tutorialState = ref.read(tutorialStateProvider);
          if (!tutorialState.isActive) {
            await ref.read(tutorialStateProvider.notifier).start();
          }
        }
      });
    }

    return layoutAsync.when(
      data: (layout) => Column(
        children: [
          // Web体験版バナー
          WebTrialBanner(prefs: prefs),
          // 挨拶ヘッダー + 編集ボタン
          _GreetingBar(editMode: _editMode, onToggle: () => setState(() => _editMode = !_editMode), onReset: () => ref.read(dashboardLayoutProvider.notifier).resetToDefault(), colors: colors),
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

/// 挨拶バー（時間帯別あいさつ + ダッシュボード編集ボタン）.
class _GreetingBar extends StatelessWidget {
  const _GreetingBar({
    required this.editMode,
    required this.onToggle,
    required this.onReset,
    required this.colors,
  });

  final bool editMode;
  final VoidCallback onToggle;
  final VoidCallback onReset;
  final AppColors colors;

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'お疲れさまです';
    if (hour < 12) return 'おはようございます';
    if (hour < 18) return 'こんにちは';
    return 'こんばんは';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 0),
      child: Row(
        children: [
          if (!editMode) ...[
            Text(
              _greeting(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
          ],
          const Spacer(),
          if (editMode)
            TextButton.icon(
              onPressed: onReset,
              icon: Icon(Icons.restore, size: 16, color: colors.warning),
              label: Text(
                'リセット',
                style: TextStyle(color: colors.warning, fontSize: 13),
              ),
            ),
          IconButton(
            icon: Icon(
              editMode ? Icons.check_circle_outline : Icons.tune_outlined,
              size: 20,
              color: editMode ? colors.success : colors.textMuted,
            ),
            onPressed: onToggle,
            tooltip: editMode ? '完了' : 'ウィジェット編集',
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

/// 今日の活動バナー.
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
                    data.studied ? '今日は活動済み!' : '今日の活動を始めよう',
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

/// 合計活動時間カード.
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
        label: '合計活動時間',
        value: '${data.totalHours.toStringAsFixed(1)}h',
        theme: theme,
      ),
      loading: () => const _WidgetLoading(),
      error: (_, _) => const _WidgetError(),
    );
  }
}

/// 活動日数カード.
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
        label: '活動日数',
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
        label: '連続活動',
        value: '${data.currentStreak}日',
        subtitle: '最長: ${data.longestStreak}日',
        theme: theme,
      ),
      loading: () => const _WidgetLoading(),
      error: (_, _) => const _WidgetError(),
    );
  }
}

/// 本棚ウィジェット（読了・読書中の本を横並びで表示）.
class _BookshelfContent extends ConsumerWidget {
  const _BookshelfContent({required this.colors});
  final AppColors colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(bookListProvider);
    final theme = Theme.of(context);

    return booksAsync.when(
      data: (books) {
        // 読了・読書中の本のみ（読了を先に表示）
        final displayBooks = books
            .where((b) =>
                b.status == BookStatus.completed ||
                b.status == BookStatus.reading)
            .toList()
          ..sort((a, b) {
            if (a.status == b.status) return 0;
            return a.status == BookStatus.completed ? -1 : 1;
          });
        final completedCount =
            books.where((b) => b.status == BookStatus.completed).length;

        return Column(
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
                  '$completedCount/${books.length}冊 読了',
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (displayBooks.isEmpty)
              Text(
                '読書を始めると本棚に並びます',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.textMuted,
                ),
              )
            else
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF2C1810), // 棚の奥の背景
                ),
                child: Column(
                  children: [
                    // 本の列
                    SizedBox(
                      height: 100,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            for (final b in displayBooks)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 1),
                                child: SizedBox(
                                  width: 36,
                                  height: 75 +
                                      (b.title.length % 4) * 6.0,
                                  child: _MiniBookCover(
                                      book: b, colors: colors),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    // 木目調の棚板
                    CustomPaint(
                      size: const Size(double.infinity, 10),
                      painter: _MiniShelfPainter(),
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

/// ダッシュボード用の背表紙スタイル本カバー.
class _MiniBookCover extends StatelessWidget {
  const _MiniBookCover({required this.book, required this.colors});

  final Book book;
  final AppColors colors;

  Color _bookBaseColor() {
    const palette = [
      Color(0xFF1B5E20), Color(0xFF004D40), Color(0xFF0D47A1),
      Color(0xFF311B92), Color(0xFF880E4F), Color(0xFFBF360C),
      Color(0xFF4E342E), Color(0xFF263238), Color(0xFF1A237E),
      Color(0xFF33691E),
    ];
    return palette[book.title.hashCode.abs() % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = _bookBaseColor();
    final darkerColor = Color.lerp(baseColor, Colors.black, 0.3)!;
    final lighterColor = Color.lerp(baseColor, Colors.white, 0.15)!;

    final bandColor = switch (book.status) {
      BookStatus.reading => colors.accent,
      BookStatus.completed => colors.success,
      _ => Colors.transparent,
    };

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          stops: const [0.0, 0.08, 0.2, 0.8, 0.92, 1.0],
          colors: [
            darkerColor, baseColor, lighterColor,
            lighterColor, baseColor, darkerColor,
          ],
        ),
        borderRadius: BorderRadius.circular(2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            offset: const Offset(1, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          // 装飾ライン
          Positioned(top: 4, left: 3, right: 3,
            child: Container(height: 0.5,
                color: Colors.white.withAlpha(35))),
          Positioned(bottom: 4, left: 3, right: 3,
            child: Container(height: 0.5,
                color: Colors.white.withAlpha(35))),
          if (bandColor != Colors.transparent)
            Positioned(top: 7, left: 2, right: 2,
              child: Container(height: 2,
                decoration: BoxDecoration(
                  color: bandColor,
                  borderRadius: BorderRadius.circular(1),
                ))),
          // タイトル
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 2, vertical: 10),
              child: Text(
                book.title,
                style: TextStyle(
                  fontSize: 7,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withAlpha(210),
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ダッシュボード用の小さな木目棚板.
class _MiniShelfPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height - 1),
      Paint()..color = const Color(0xFF5D4037),
    );
    final grainPaint = Paint()
      ..color = const Color(0xFF4E342E)
      ..strokeWidth = 0.6;
    for (var y = 1.5; y < size.height - 1; y += 2.5) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 0.3), grainPaint);
    }
    canvas.drawLine(
      const Offset(0, 0.3), Offset(size.width, 0.3),
      Paint()..color = const Color(0xFF8D6E63)..strokeWidth = 1,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - 1, size.width, 1),
      Paint()..color = const Color(0xFF3E2723),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
              Text('活動の実施率', style: theme.textTheme.titleSmall),
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
              Text('アクティビティ (30日)', style: theme.textTheme.titleSmall),
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
      data: (overall) {
        // 進行中または最後に完成した星座を表示
        final current = overall.constellations.lastWhere(
          (c) => c.litStarCount > 0,
          orElse: () => overall.constellations.first,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  current.constellation.symbol,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${overall.completedCount}/${constellations.length} 星座完成',
                    style: theme.textTheme.labelMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${overall.totalLitStars}/${overall.totalStars}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: current.isComplete
                        ? const Color(0xFFFFD700)
                        : theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 120,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1A1A2E).withAlpha(150)
                      : const Color(0xFFF0F4F8).withAlpha(150),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ConstellationWidget(
                  progress: current,
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
