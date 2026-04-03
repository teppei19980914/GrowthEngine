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
import '../l10n/app_labels.dart';
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
                  AppLabels.dreamPageDesc,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20),
                tooltip: '',
                padding: EdgeInsets.zero,
                onSelected: (value) {
                  if (value == 'discovery') {
                    _openDiscoveryGuide(context, ref);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'discovery',
                    child: ListTile(
                      leading: Icon(Icons.explore, size: 20),
                      title: Text(AppLabels.dreamDiscoveryGuide),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              FloatingActionButton.small(
                key: TutorialTargetKeys.addDreamButton,
                heroTag: 'dream_add',
                onPressed: () => _addDream(context, ref),
                child: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 8),

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
                        final sorted = [...dreams]
                          ..sort((a, b) =>
                              a.sortOrder.compareTo(b.sortOrder));
                        return _ReorderableDreamList(
                          dreams: sorted,
                          goalCountByDream: goalCountByDream,
                          onEditDream: (dream) =>
                              _editDream(context, ref, dream),
                          onReorder: (reordered) {
                            final orders = <(String, int)>[];
                            for (var i = 0; i < reordered.length; i++) {
                              orders.add((reordered[i].id, i));
                            }
                            ref
                                .read(dreamListProvider.notifier)
                                .reorderDreams(orders);
                          },
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
          Icon(Icons.auto_awesome_outlined, size: 64, color: colors.textMuted),
          const SizedBox(height: 16),
          Text(
            AppLabels.dreamEmptyHeading,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLabels.dreamEmptyHint,
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
          itemName: AppLabels.pageDreams,
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
            Expanded(child: Text(AppLabels.dreamEmptyTitle)),
          ],
        ),
        content: const Text(
          AppLabels.dreamTutorialGuideChoice,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppLabels.btnCancel),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.explore, size: 18),
            label: const Text(AppLabels.dreamEmptyAction),
            onPressed: () => Navigator.pop(context, true),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.edit, size: 18),
            label: const Text(AppLabels.dreamTutorialSelfInput),
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

/// 並び替え可能な夢リスト.
class _ReorderableDreamList extends StatefulWidget {
  const _ReorderableDreamList({
    required this.dreams,
    required this.goalCountByDream,
    required this.onEditDream,
    required this.onReorder,
  });

  final List<Dream> dreams;
  final Map<String, int> goalCountByDream;
  final void Function(Dream) onEditDream;
  final void Function(List<Dream>) onReorder;

  @override
  State<_ReorderableDreamList> createState() => _ReorderableDreamListState();
}

class _ReorderableDreamListState extends State<_ReorderableDreamList> {
  late List<Dream> _ordered;

  @override
  void initState() {
    super.initState();
    _ordered = List.of(widget.dreams);
  }

  @override
  void didUpdateWidget(_ReorderableDreamList old) {
    super.didUpdateWidget(old);
    if (old.dreams != widget.dreams) {
      _ordered = List.of(widget.dreams);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      itemCount: _ordered.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex--;
          final item = _ordered.removeAt(oldIndex);
          _ordered.insert(newIndex, item);
        });
        widget.onReorder(_ordered);
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
        final dream = _ordered[index];
        return Padding(
          key: ValueKey(dream.id),
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: _DreamCard(
                  dream: dream,
                  goalCount: widget.goalCountByDream[dream.id] ?? 0,
                  onTap: () => widget.onEditDream(dream),
                ),
              ),
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
