/// 目標ページ.
///
/// 目標一覧をカードリストで表示し、追加・編集・削除を提供する.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../dialogs/goal_dialog.dart';
import '../dialogs/goal_discovery_dialog.dart';
import '../dialogs/trial_limit_dialog.dart';
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
                  'やりたいことに向けた目標を管理します。',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _openGoalGuide(context, ref),
                icon: const Icon(Icons.explore, size: 16),
                label: const Text('発見ガイド'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                key: TutorialTargetKeys.addGoalButton,
                onPressed: () => _addGoal(context, ref),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('目標を追加'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 目標リスト
          Expanded(
            child: goalsAsync.when(
              data: (goals) => dreamsAsync.when(
                data: (dreams) {
                  if (goals.isEmpty) {
                    return _buildEmptyState(theme, colors);
                  }
                  final dreamMap = {for (final d in dreams) d.id: d};
                  final progressAsync = ref.watch(goalProgressProvider);
                  final progressMap = progressAsync.valueOrNull ?? {};
                  return ListView.separated(
                    itemCount: goals.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final goal = goals[index];
                      final dreamTitle = goal.dreamId.isEmpty
                          ? null
                          : dreamMap[goal.dreamId]?.title ?? '(未設定)';
                      final progress = progressMap[goal.id];
                      return _GoalCard(
                        goal: goal,
                        dreamTitle: dreamTitle,
                        totalTasks: progress?.total ?? 0,
                        completedTasks: progress?.completed ?? 0,
                        onTap: () => _editGoal(context, ref, goal),
                      );
                    },
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Text('エラーが発生しました: $error'),
                ),
              ),
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

  Widget _buildEmptyState(ThemeData theme, dynamic colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag_outlined, size: 64, color: colors.textMuted),
          const SizedBox(height: 16),
          Text(
            '最初の目標を設定しよう',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '「目標を追加」ボタンから始められます',
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
      final totalMax = maxDreams(level) * maxGoalsPerDream(level);
      if (goals.length >= totalMax) {
        if (!context.mounted) return;
        await showTrialLimitDialog(
          context,
          itemName: '目標',
          currentCount: goals.length,
          maxCount: totalMax,
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
            Expanded(child: Text('どんな目標を立てますか？')),
          ],
        ),
        content: const Text(
          '夢を実現するための具体的な目標を設定します。\n'
          'まだ決まっていない方は、ガイドが一緒に考えるお手伝いをします。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.explore, size: 18),
            label: const Text('ガイドで考える'),
            onPressed: () => Navigator.pop(context, true),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('自分で入力する'),
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

/// 目標カードウィジェット.
class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.dreamTitle,
    required this.totalTasks,
    required this.completedTasks,
    required this.onTap,
  });

  final Goal goal;
  final String? dreamTitle;
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
        : 'タスク未設定';

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
                    const SizedBox(height: 4),

                    // 夢情報（紐づく夢がある場合のみ表示）
                    if (dreamTitle != null) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 13,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              dreamTitle!,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
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

