/// 目標ページ.
///
/// 夢ごとにグルーピングした目標一覧を表示し、
/// ドラッグ&ドロップで並び替え、追加・編集・削除を提供する.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../dialogs/goal_dialog.dart';
import '../dialogs/goal_discovery_dialog.dart';
import '../dialogs/trial_limit_dialog.dart';
import '../l10n/app_labels.dart';
import '../models/dream.dart';
import '../models/goal.dart';
import '../providers/dream_providers.dart';
import '../providers/goal_providers.dart';
import '../providers/service_providers.dart';
import '../services/trial_limit_service.dart';
import '../services/tutorial_service.dart';
import '../theme/app_theme.dart';
import '../widgets/tutorial/tutorial_banner.dart';
import '../widgets/tutorial/tutorial_target_keys.dart';

/// 目標ページ.
class GoalPage extends ConsumerWidget {
  /// GoalPageを作成する.
  const GoalPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalListProvider);
    final dreamsAsync = ref.watch(dreamListProvider);
    final theme = Theme.of(context);
    final colors = theme.appColors;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー
          Row(
            children: [
              Expanded(
                child: Text(
                  AppLabels.goalPageDesc,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _openGoalGuide(context, ref),
                icon: const Icon(Icons.explore, size: 16),
                label: const Text(AppLabels.goalDiscoveryGuide),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                key: TutorialTargetKeys.addGoalButton,
                onPressed: () => _addGoal(context, ref),
                icon: const Icon(Icons.add, size: 18),
                label: const Text(AppLabels.goalAddButton),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 目標リスト（夢別グルーピング）
          Expanded(
            child: goalsAsync.when(
              data: (goals) => dreamsAsync.when(
                data: (dreams) {
                  if (goals.isEmpty) {
                    return _buildEmptyState(theme, colors);
                  }
                  return _GroupedGoalList(
                    goals: goals,
                    dreams: dreams,
                    ref: ref,
                    onEditGoal: (goal) => _editGoal(context, ref, goal),
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Text(AppLabels.errorWithDetail(error.toString())),
                ),
              ),
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text(AppLabels.errorWithDetail(error.toString())),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, dynamic colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag_outlined, size: 64, color: colors.textMuted),
          const SizedBox(height: 16),
          Text(
            AppLabels.goalEmptyHeading,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLabels.goalEmptyHint,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  List<Dream> _getDreams(WidgetRef ref) {
    return ref.read(dreamListProvider).valueOrNull ?? [];
  }

  Future<void> _openGoalGuide(BuildContext context, WidgetRef ref) async {
    final dreams = _getDreams(ref);
    final result = await showGoalDiscoveryDialog(context, dreams: dreams);
    if (result == null) return;

    await ref.read(goalListProvider.notifier).createGoal(
          dreamId: result.dreamId,
          what: result.what,
          how: result.how,
          whenType: WhenType.period,
          whenTarget: result.whenTarget,
        );
    ref.invalidate(goalProgressProvider);
  }

  Future<void> _addGoal(BuildContext context, WidgetRef ref) async {
    final dreams = _getDreams(ref);

    final tutorialState = ref.read(tutorialStateProvider);
    final isTutorial = tutorialState.isActive &&
        tutorialState.step == TutorialStep.addGoal;

    // チュートリアル中は制限をバイパス
    if (!isTutorial) {
      final goals = await ref.read(goalListProvider.future);
      final level = ref.read(unlockLevelProvider);
      if (!canAddGoal(currentGoalCount: goals.length, unlockLevel: level)) {
        if (!context.mounted) return;
        await showTrialLimitDialog(
          context,
          itemName: AppLabels.pageGoals,
          currentCount: goals.length,
          maxCount: maxGoals(level),
          feedbackService: ref.read(feedbackServiceProvider),
        );
        ref.invalidate(feedbackServiceProvider);
        return;
      }
    }

    if (!context.mounted) return;

    // チュートリアル中: ガイドを使うか自分で入力するかを選択
    if (isTutorial) {
      final useGuide = await _showTutorialGoalChoice(context);
      if (useGuide == null || !context.mounted) return;

      if (useGuide) {
        // ガイド経由
        final guideResult =
            await showGoalDiscoveryDialog(context, dreams: dreams);
        if (guideResult == null) return;

        final goalId = await ref.read(goalListProvider.notifier).createGoal(
              dreamId: guideResult.dreamId,
              what: guideResult.what,
              how: guideResult.how,
              whenType: WhenType.period,
              whenTarget: guideResult.whenTarget,
            );

        final tutorialService = ref.read(tutorialServiceProvider);
        await tutorialService.setTutorialGoalId(goalId);
        await ref.read(tutorialStateProvider.notifier).advanceStep();
        ref.invalidate(goalProgressProvider);
        return;
      }
    }

    final result = await showGoalDialog(context, dreams: dreams);
    if (result == null) return;

    final goalId = await ref.read(goalListProvider.notifier).createGoal(
          dreamId: result.dreamId,
          whenTarget: result.whenTarget,
          whenType: result.whenType,
          what: result.what,
          how: result.how,
        );

    // チュートリアル中: 目標IDを記録してステップを進める
    if (isTutorial) {
      final tutorialService = ref.read(tutorialServiceProvider);
      await tutorialService.setTutorialGoalId(goalId);
      await ref.read(tutorialStateProvider.notifier).advanceStep();
    }
  }

  /// チュートリアル中の目標追加で、ガイドを使うか自分で入力するかを選択.
  Future<bool?> _showTutorialGoalChoice(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lightbulb_outline, size: 24),
            SizedBox(width: 8),
            Expanded(child: Text(AppLabels.goalEmptyTitle)),
          ],
        ),
        content: const Text(
          AppLabels.goalTutorialGuideChoice,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppLabels.btnCancel),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.explore, size: 18),
            label: const Text(AppLabels.goalEmptyAction),
            onPressed: () => Navigator.pop(context, true),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.edit, size: 18),
            label: const Text(AppLabels.goalTutorialSelfInput),
            onPressed: () => Navigator.pop(context, false),
          ),
        ],
      ),
    );
  }

  Future<void> _editGoal(
    BuildContext context,
    WidgetRef ref,
    Goal goal,
  ) async {
    final dreams = _getDreams(ref);
    final result = await showGoalDialog(context, goal: goal, dreams: dreams);
    if (result == null) return;

    if (result.deleteRequested) {
      await ref.read(goalListProvider.notifier).deleteGoal(goal.id);
      return;
    }

    await ref.read(goalListProvider.notifier).updateGoal(
          goalId: goal.id,
          dreamId: result.dreamId,
          whenTarget: result.whenTarget,
          whenType: result.whenType,
          what: result.what,
          how: result.how,
        );
  }
}

/// 夢別にグルーピングされた目標リスト.
class _GroupedGoalList extends StatelessWidget {
  const _GroupedGoalList({
    required this.goals,
    required this.dreams,
    required this.ref,
    required this.onEditGoal,
  });

  final List<Goal> goals;
  final List<Dream> dreams;
  final WidgetRef ref;
  final void Function(Goal goal) onEditGoal;

  @override
  Widget build(BuildContext context) {
    final dreamMap = {for (final d in dreams) d.id: d};
    final progressAsync = ref.watch(goalProgressProvider);
    final progressMap = progressAsync.valueOrNull ?? {};

    // 夢IDでグルーピング（sortOrder順）
    final grouped = <String, List<Goal>>{};
    for (final goal in goals) {
      final key = goal.dreamId.isEmpty ? '' : goal.dreamId;
      (grouped[key] ??= []).add(goal);
    }
    // 各グループ内をsortOrder順にソート
    for (final list in grouped.values) {
      list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }

    // 夢のある目標を先、独立目標は末尾
    final dreamIds = grouped.keys.where((k) => k.isNotEmpty).toList()
      ..sort((a, b) {
        final da = dreamMap[a]?.title ?? '';
        final db = dreamMap[b]?.title ?? '';
        return da.compareTo(db);
      });
    final hasStandalone = grouped.containsKey('');

    return ListView(
      children: [
        for (final dreamId in dreamIds) ...[
          _DreamSectionHeader(dream: dreamMap[dreamId]),
          _ReorderableGoalSection(
            dreamId: dreamId,
            goals: grouped[dreamId]!,
            progressMap: progressMap,
            onEditGoal: onEditGoal,
            onReorder: (reordered) => _persistOrder(reordered),
          ),
          const SizedBox(height: 16),
        ],
        if (hasStandalone) ...[
          _DreamSectionHeader(dream: null),
          _ReorderableGoalSection(
            dreamId: '',
            goals: grouped['']!,
            progressMap: progressMap,
            onEditGoal: onEditGoal,
            onReorder: (reordered) => _persistOrder(reordered),
          ),
        ],
      ],
    );
  }

  void _persistOrder(List<Goal> reordered) {
    final orders = <(String, int)>[];
    for (var i = 0; i < reordered.length; i++) {
      orders.add((reordered[i].id, i));
    }
    ref.read(goalListProvider.notifier).reorderGoals(orders);
  }
}

/// 夢セクションヘッダー.
class _DreamSectionHeader extends StatelessWidget {
  const _DreamSectionHeader({required this.dream});

  final Dream? dream;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;

    if (dream == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Row(
          children: [
            Icon(Icons.flag_outlined, size: 18, color: colors.textMuted),
            const SizedBox(width: 8),
            Text(
              AppLabels.goalIndependentSection,
              style: theme.textTheme.titleSmall?.copyWith(
                color: colors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    final cat = dream!.dreamCategory;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: cat.color.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(cat.icon, size: 18, color: cat.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dream!.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  cat.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cat.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 並び替え可能な目標セクション.
class _ReorderableGoalSection extends StatefulWidget {
  const _ReorderableGoalSection({
    required this.dreamId,
    required this.goals,
    required this.progressMap,
    required this.onEditGoal,
    required this.onReorder,
  });

  final String dreamId;
  final List<Goal> goals;
  final Map<String, ({int total, int completed})> progressMap;
  final void Function(Goal) onEditGoal;
  final void Function(List<Goal>) onReorder;

  @override
  State<_ReorderableGoalSection> createState() =>
      _ReorderableGoalSectionState();
}

class _ReorderableGoalSectionState extends State<_ReorderableGoalSection> {
  late List<Goal> _orderedGoals;

  @override
  void initState() {
    super.initState();
    _orderedGoals = List.of(widget.goals);
  }

  @override
  void didUpdateWidget(_ReorderableGoalSection old) {
    super.didUpdateWidget(old);
    if (old.goals != widget.goals) {
      _orderedGoals = List.of(widget.goals);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: _orderedGoals.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex--;
          final item = _orderedGoals.removeAt(oldIndex);
          _orderedGoals.insert(newIndex, item);
        });
        widget.onReorder(_orderedGoals);
      },
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) => Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: child,
          ),
          child: child,
        );
      },
      itemBuilder: (context, index) {
        final goal = _orderedGoals[index];
        final progress = widget.progressMap[goal.id];

        return Padding(
          key: ValueKey(goal.id),
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              // 順序インジケーター
              SizedBox(
                width: 28,
                child: Column(
                  children: [
                    if (index > 0)
                      Container(
                        width: 2,
                        height: 8,
                        color: colors.border,
                      ),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primary.withAlpha(20),
                        border: Border.all(
                          color: theme.colorScheme.primary.withAlpha(80),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${index + 1}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    if (index < _orderedGoals.length - 1)
                      Container(
                        width: 2,
                        height: 8,
                        color: colors.border,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              // 目標カード
              Expanded(
                child: _GoalCard(
                  goal: goal,
                  totalTasks: progress?.total ?? 0,
                  completedTasks: progress?.completed ?? 0,
                  onTap: () => widget.onEditGoal(goal),
                ),
              ),
              // ドラッグハンドル
              ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    Icons.drag_indicator,
                    size: 20,
                    color: colors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 目標カードウィジェット.
class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.totalTasks,
    required this.completedTasks,
    required this.onTap,
  });

  final Goal goal;
  final int totalTasks;
  final int completedTasks;
  final VoidCallback onTap;

  Color _parseColor(String hex) {
    final code = hex.replaceFirst('#', '');
    return Color(int.parse('FF$code', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final goalColor = _parseColor(goal.color);

    final progressPercent =
        totalTasks > 0 ? completedTasks / totalTasks : 0.0;
    final progressText = totalTasks > 0
        ? '$completedTasks / $totalTasks'
        : AppLabels.goalTaskNotSet;

    return GestureDetector(
      onTap: onTap,
      child: Card(
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          children: [
            // カラーバー
            Container(width: 6, color: goalColor),

            // 達成率リング
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: SizedBox(
                width: 52,
                height: 52,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: CircularProgressIndicator(
                        value: progressPercent,
                        strokeWidth: 4,
                        backgroundColor: goalColor.withAlpha(30),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(goalColor),
                      ),
                    ),
                    Text(
                      totalTasks > 0
                          ? '${(progressPercent * 100).round()}%'
                          : '—',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: goalColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // コンテンツ
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 14, 8, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // タイトル行
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            goal.what,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        _WhenBadge(goal: goal),
                        Icon(Icons.chevron_right,
                            size: 18, color: colors.textMuted),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // 進捗テキスト
                    Row(
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 13, color: goalColor),
                        const SizedBox(width: 4),
                        Text(
                          progressText,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

/// When情報のバッジ.
class _WhenBadge extends StatelessWidget {
  const _WhenBadge({required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDate = goal.whenType == WhenType.date;
    final targetDate = goal.getTargetDate();

    String label;
    Color? badgeColor;

    if (isDate && targetDate != null) {
      final remaining = targetDate.difference(DateTime.now()).inDays;
      label = DateFormat('yyyy/MM/dd').format(targetDate);
      if (remaining < 0) {
        badgeColor = theme.colorScheme.error;
      } else if (remaining <= 30) {
        badgeColor = theme.appColors.warning;
      }
    } else {
      label = goal.whenTarget;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor?.withAlpha(30) ??
            theme.colorScheme.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: badgeColor?.withAlpha(80) ??
              theme.colorScheme.primary.withAlpha(50),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDate ? Icons.calendar_today : Icons.schedule,
            size: 12,
            color: badgeColor ?? theme.colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: badgeColor ?? theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
