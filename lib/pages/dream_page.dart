/// 夢ページ.
///
/// 夢一覧をカードリストで表示し、追加・編集・削除を提供する.
/// 各夢の配下に紐づく目標数を表示する.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dialogs/dream_dialog.dart';
import '../dialogs/dream_discovery_dialog.dart';
import '../dialogs/trial_limit_dialog.dart';
import '../models/dream.dart';
import '../providers/dream_providers.dart';
import '../providers/goal_providers.dart';
import '../providers/service_providers.dart';
import '../services/trial_limit_service.dart';
import '../services/tutorial_service.dart';
import '../theme/app_theme.dart';
import '../widgets/tutorial/tutorial_banner.dart';
import '../widgets/tutorial/tutorial_target_keys.dart';

/// 夢ページ.
class DreamPage extends ConsumerWidget {
  /// DreamPageを作成する.
  const DreamPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dreamsAsync = ref.watch(dreamListProvider);
    final goalsAsync = ref.watch(goalListProvider);
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
                  '将来の夢を設定し、夢の実現に向けた目標を管理します。',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _openDiscoveryGuide(context, ref),
                icon: const Icon(Icons.explore, size: 18),
                label: const Text('発見ガイド'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                key: TutorialTargetKeys.addDreamButton,
                onPressed: () => _addDream(context, ref),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('夢を追加'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 夢リスト
          Expanded(
            child: dreamsAsync.when(
              data: (dreams) => dreams.isEmpty
                  ? _buildEmptyState(theme, colors)
                  : goalsAsync.when(
                      data: (goals) {
                        final goalCountByDream = <String, int>{};
                        for (final goal in goals) {
                          goalCountByDream[goal.dreamId] =
                              (goalCountByDream[goal.dreamId] ?? 0) + 1;
                        }
                        return ListView.separated(
                          itemCount: dreams.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, index) => _DreamCard(
                            dream: dreams[index],
                            goalCount:
                                goalCountByDream[dreams[index].id] ?? 0,
                            onEdit: () =>
                                _editDream(context, ref, dreams[index]),
                            onDelete: () =>
                                _deleteDream(context, ref, dreams[index]),
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
          Icon(Icons.auto_awesome_outlined, size: 64, color: colors.textMuted),
          const SizedBox(height: 16),
          Text(
            'やりたいことを見つけよう',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '「夢を追加」ボタンから直接追加するか、\n'
            '「発見ガイド」でやりたいことを見つけましょう',
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _openDiscoveryGuide(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final result = await showDreamDiscoveryDialog(context);
    if (result == null || !context.mounted) return;

    await ref.read(dreamListProvider.notifier).createDream(
          title: result.title,
          description: result.description,
          why: result.why,
        );
  }

  Future<void> _addDream(BuildContext context, WidgetRef ref) async {
    final tutorialState = ref.read(tutorialStateProvider);
    final isTutorial = tutorialState.isActive &&
        tutorialState.step == TutorialStep.addDream;

    // チュートリアル中は制限をバイパス
    if (!isTutorial) {
      final dreams = await ref.read(dreamListProvider.future);
      final currentCount = dreams.length;
      final level = ref.read(unlockLevelProvider);
      if (!canAddDream(currentCount: currentCount, unlockLevel: level)) {
        if (!context.mounted) return;
        await showTrialLimitDialog(
          context,
          itemName: '夢',
          currentCount: currentCount,
          maxCount: maxDreams(level),
          feedbackService: ref.read(feedbackServiceProvider),
        );
        ref.invalidate(feedbackServiceProvider);
        return;
      }
    }

    if (!context.mounted) return;
    final result = await showDreamDialog(context);
    if (result == null) return;

    final dreamId = await ref.read(dreamListProvider.notifier).createDream(
          title: result.title,
          description: result.description,
          why: result.why,
        );

    // チュートリアル中: 夢IDを記録してステップを進める
    if (isTutorial) {
      final tutorialService = ref.read(tutorialServiceProvider);
      await tutorialService.setTutorialDreamId(dreamId);
      await ref.read(tutorialStateProvider.notifier).advanceStep();
    }
  }

  Future<void> _editDream(
    BuildContext context,
    WidgetRef ref,
    Dream dream,
  ) async {
    final result = await showDreamDialog(context, dream: dream);
    if (result == null) return;

    await ref.read(dreamListProvider.notifier).updateDream(
          dreamId: dream.id,
          title: result.title,
          description: result.description,
          why: result.why,
        );
  }

  Future<void> _deleteDream(
    BuildContext context,
    WidgetRef ref,
    Dream dream,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('夢を削除'),
        content: Text(
          '「${dream.title}」を削除しますか？\n紐づく目標とタスクもすべて削除されます。',
        ),
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

    await ref.read(dreamListProvider.notifier).deleteDream(dream.id);
  }
}

/// 夢カードウィジェット.
class _DreamCard extends StatelessWidget {
  const _DreamCard({
    required this.dream,
    required this.goalCount,
    required this.onEdit,
    required this.onDelete,
  });

  final Dream dream;
  final int goalCount;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final primary = theme.colorScheme.primary;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          children: [
            // カラーバー
            Container(width: 6, color: primary),

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
                        Icon(Icons.auto_awesome, size: 18, color: primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            dream.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        // 目標数バッジ（1件以上の場合のみ表示）
                        if (goalCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: primary.withAlpha(20),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '目標 $goalCount',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
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

                    // 説明
                    if (dream.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        dream.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],

                    // Why（動機）— 強調表示
                    if (dream.why.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: primary.withAlpha(12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.favorite,
                              size: 13,
                              color: primary.withAlpha(180),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                dream.why,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.textSecondary,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
