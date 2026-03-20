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
                            onTap: () =>
                                _editDream(context, ref, dreams[index]),
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

    final category = _mapGuideCategory(result.categoryKey);
    await ref.read(dreamListProvider.notifier).createDream(
          title: result.title,
          description: result.description,
          why: result.why,
          category: category,
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

    // チュートリアル中: ガイドを使うか自分で入力するか選択
    if (isTutorial) {
      final useGuide = await _showTutorialDreamChoice(context);
      if (!context.mounted) return;
      if (useGuide == null) return; // キャンセル
      if (useGuide) {
        // ガイド経由: ガイド結果をそのまま登録（夢追加ダイアログは経由しない）
        final guideResult = await showDreamDiscoveryDialog(context);
        if (guideResult == null || !context.mounted) return;

        // カテゴリをガイドの選択から自動割り当て
        final category = _mapGuideCategory(guideResult.categoryKey);
        final dreamId =
            await ref.read(dreamListProvider.notifier).createDream(
                  title: guideResult.title,
                  description: guideResult.description,
                  why: guideResult.why,
                  category: category,
                );

        final tutorialService = ref.read(tutorialServiceProvider);
        await tutorialService.setTutorialDreamId(dreamId);
        await ref.read(tutorialStateProvider.notifier).advanceStep();
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
          category: result.category,
        );

    // チュートリアル中: 夢IDを記録してステップを進める
    if (isTutorial) {
      final tutorialService = ref.read(tutorialServiceProvider);
      await tutorialService.setTutorialDreamId(dreamId);
      await ref.read(tutorialStateProvider.notifier).advanceStep();
    }
  }

  /// チュートリアル中の夢追加で、ガイドを使うか自分で入力するかを選択.
  ///
  /// 戻り値: true=ガイドを使う, false=自分で入力, null=キャンセル.
  /// ガイドのカテゴリキーをDreamモデルのカテゴリ値にマッピング.
  String _mapGuideCategory(String? guideKey) {
    const mapping = {
      'career': 'career',
      'health': 'health',
      'learning': 'learning',
      'hobby': 'hobby',
      'relationships': 'relationship',
      'money': 'finance',
      'lifestyle': 'other',
    };
    return mapping[guideKey] ?? 'other';
  }

  Future<bool?> _showTutorialDreamChoice(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lightbulb_outline, size: 24),
            SizedBox(width: 8),
            Expanded(child: Text('やりたいことはありますか？')),
          ],
        ),
        content: const Text(
          'すでにやりたいことがある方はそのまま入力できます。\n'
          'まだ決まっていない方は、ガイドが一緒に見つけるお手伝いをします。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.explore, size: 18),
            label: const Text('ガイドで見つける'),
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

  Future<void> _editDream(
    BuildContext context,
    WidgetRef ref,
    Dream dream,
  ) async {
    final result = await showDreamDialog(context, dream: dream);
    if (result == null) return;

    if (result.deleteRequested) {
      await ref.read(dreamListProvider.notifier).deleteDream(dream.id);
      return;
    }

    await ref.read(dreamListProvider.notifier).updateDream(
          dreamId: dream.id,
          title: result.title,
          description: result.description,
          why: result.why,
          category: result.category,
        );
  }
}

/// 夢カードウィジェット.
class _DreamCard extends StatelessWidget {
  const _DreamCard({
    required this.dream,
    required this.goalCount,
    required this.onTap,
  });

  final Dream dream;
  final int goalCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final cat = dream.dreamCategory;

    return GestureDetector(
      onTap: onTap,
      child: Card(
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          children: [
            // カテゴリカラーバー
            Container(width: 6, color: cat.color),

            // カテゴリアイコン
            Container(
              width: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cat.color.withAlpha(30),
                    cat.color.withAlpha(10),
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(cat.icon, size: 28, color: cat.color),
                  const SizedBox(height: 2),
                  Text(
                    cat.label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cat.color,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // コンテンツ
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 14, 8, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // タイトル行
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            dream.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        // 目標数バッジ
                        if (goalCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: cat.color.withAlpha(25),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.flag, size: 12, color: cat.color),
                                const SizedBox(width: 3),
                                Text(
                                  '$goalCount',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: cat.color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Icon(Icons.chevron_right,
                            size: 18, color: colors.textMuted),
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    // Why（動機）
                    if (dream.why.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: cat.color.withAlpha(12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.favorite,
                              size: 13,
                              color: cat.color.withAlpha(180),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                dream.why,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.textSecondary,
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
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
      ),
    );
  }
}
