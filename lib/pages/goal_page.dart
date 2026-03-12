/// 目標ページ.
///
/// 目標一覧をカードリストで表示し、追加・編集・削除を提供する.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../dialogs/goal_dialog.dart';
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
                  '夢の実現に向けた目標を管理します。',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
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
                  return ListView.separated(
                    itemCount: goals.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, index) => _GoalCard(
                      goal: goals[index],
                      dreamTitle:
                          dreamMap[goals[index].dreamId]?.title ?? '(未設定)',
                      onEdit: () => _editGoal(context, ref, goals[index]),
                      onDelete: () =>
                          _deleteGoal(context, ref, goals[index]),
                    ),
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
            '目標がまだありません',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '「目標を追加」ボタンから新しい目標を作成しましょう',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  List<Dream> _getDreams(WidgetRef ref) {
    return ref.read(dreamListProvider).valueOrNull ?? [];
  }

  Future<void> _addGoal(BuildContext context, WidgetRef ref) async {
    final dreams = _getDreams(ref);
    if (dreams.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('先に「夢」を登録してください')),
      );
      return;
    }

    final tutorialState = ref.read(tutorialStateProvider);
    final isTutorial = tutorialState.isActive &&
        tutorialState.step == TutorialStep.addGoal;

    // チュートリアル中は制限をバイパス
    if (!isTutorial) {
      final goals = ref.read(goalListProvider).valueOrNull ?? [];
      final level = ref.read(unlockLevelProvider);
      final totalMax = maxDreams(level) * maxGoalsPerDream(level);
      if (goals.length >= totalMax) {
        await showTrialLimitDialog(
          context,
          itemName: '目標',
          currentCount: goals.length,
          maxCount: totalMax,
          feedbackService: ref.read(feedbackServiceProvider),
        );
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

  Future<void> _editGoal(
    BuildContext context,
    WidgetRef ref,
    Goal goal,
  ) async {
    final dreams = _getDreams(ref);
    if (dreams.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('先に「夢」を登録してください')),
      );
      return;
    }
    final result = await showGoalDialog(context, goal: goal, dreams: dreams);
    if (result == null) return;

    await ref.read(goalListProvider.notifier).updateGoal(
          goalId: goal.id,
          dreamId: result.dreamId,
          whenTarget: result.whenTarget,
          whenType: result.whenType,
          what: result.what,
          how: result.how,
        );
  }

  Future<void> _deleteGoal(
    BuildContext context,
    WidgetRef ref,
    Goal goal,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('目標を削除'),
        content: Text('「${goal.what}」を削除しますか？\n紐づくタスクもすべて削除されます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(goalListProvider.notifier).deleteGoal(goal.id);
  }
}

/// 目標カードウィジェット.
class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.dreamTitle,
    required this.onEdit,
    required this.onDelete,
  });

  final Goal goal;
  final String dreamTitle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  Color _parseColor(String hex) {
    final code = hex.replaceFirst('#', '');
    return Color(int.parse('FF$code', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final goalColor = _parseColor(goal.color);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          children: [
            // カラーバー
            Container(width: 6, color: goalColor),

            // コンテンツ
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
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
                        // ポップアップメニュー
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert,
                            size: 18,
                            color: colors.textMuted,
                          ),
                          padding: EdgeInsets.zero,
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 16),
                                  SizedBox(width: 8),
                                  Text('編集'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline,
                                      size: 16, color: colors.error),
                                  const SizedBox(width: 8),
                                  Text('削除',
                                      style: TextStyle(color: colors.error)),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'edit') onEdit();
                            if (value == 'delete') onDelete();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // 夢情報
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 13,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dreamTitle,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // 目標情報
                    _InfoRow(
                      icon: Icons.build_outlined,
                      label: 'How',
                      value: goal.how,
                      color: colors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ],
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

/// 情報行.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 12, color: color),
          ),
        ),
      ],
    );
  }
}
