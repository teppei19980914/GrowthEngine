/// 夢ページ.
///
/// 夢一覧をカードリストで表示し、追加・編集・削除を提供する.
/// 各夢の配下に紐づく目標数を表示する.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../dialogs/dream_dialog.dart';
import '../dialogs/trial_limit_dialog.dart';
import '../models/dream.dart';
import '../providers/dream_providers.dart';
import '../providers/goal_providers.dart';
import '../providers/service_providers.dart';
import '../services/trial_limit_service.dart';
import '../services/tutorial_service.dart';
import '../theme/app_theme.dart';
import '../widgets/tutorial/tutorial_banner.dart';

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
              const SizedBox(width: 16),
              ElevatedButton.icon(
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
            '夢がまだありません',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '「夢を追加」ボタンから新しい夢を設定しましょう',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Future<void> _addDream(BuildContext context, WidgetRef ref) async {
    final tutorialState = ref.read(tutorialStateProvider);
    final isTutorial = tutorialState.isActive &&
        tutorialState.step == TutorialStep.addDream;

    // チュートリアル中は制限をバイパス
    if (!isTutorial) {
      final currentCount =
          ref.read(dreamListProvider).valueOrNull?.length ?? 0;
      final level = ref.read(unlockLevelProvider);
      if (!canAddDream(currentCount: currentCount, unlockLevel: level)) {
        await showTrialLimitDialog(
          context,
          itemName: '夢',
          currentCount: currentCount,
          maxCount: maxDreams(level),
          feedbackService: ref.read(feedbackServiceProvider),
        );
        return;
      }
    }

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

    return Card(
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          children: [
            // カラーバー
            Container(width: 6, color: theme.colorScheme.primary),

            // コンテンツ
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // タイトル行
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            dream.title,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        // 目標数バッジ
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                theme.colorScheme.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '目標: $goalCount件',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: onEdit,
                          tooltip: '編集',
                          visualDensity: VisualDensity.compact,
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: colors.error,
                          ),
                          onPressed: onDelete,
                          tooltip: '削除',
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),

                    // 説明
                    if (dream.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        dream.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],

                    // Why（動機）
                    if (dream.why.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.favorite_outline,
                            size: 14,
                            color: colors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              dream.why,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 8),
                    Text(
                      '作成: ${DateFormat('yyyy/MM/dd').format(dream.createdAt)}',
                      style: theme.textTheme.labelSmall,
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
