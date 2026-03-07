/// チュートリアル進行バナー.
///
/// チュートリアル実行中にAppBar直下に表示し、
/// 現在のステップの指示とヒントを表示する.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/dream_providers.dart';
import '../../providers/service_providers.dart';
import '../../services/tutorial_service.dart';

/// チュートリアルバナーウィジェット.
///
/// チュートリアルが実行中の場合にのみ表示される.
/// ルート変更を検知して適切なステップに自動遷移する.
class TutorialBanner extends ConsumerStatefulWidget {
  /// TutorialBannerを作成する.
  const TutorialBanner({super.key});

  @override
  ConsumerState<TutorialBanner> createState() => _TutorialBannerState();
}

class _TutorialBannerState extends ConsumerState<TutorialBanner> {
  @override
  Widget build(BuildContext context) {
    final tutorialState = ref.watch(tutorialStateProvider);
    if (!tutorialState.isActive) return const SizedBox.shrink();

    final step = tutorialState.step;
    final theme = Theme.of(context);

    // ルート変更を検知してステップを自動進行
    _checkRouteAdvance(step);

    if (step == TutorialStep.completed) {
      return _CompletedBanner(theme: theme);
    }

    final stepIndex = step.index;
    final totalSteps = TutorialStep.values.length - 1; // completed を除く

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withAlpha(60),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.school,
                size: 20,
                color: theme.colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 8),
              Text(
                'チュートリアル',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'ステップ ${stepIndex + 1} / $totalSteps',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer.withAlpha(180),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _skipTutorial,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'スキップ',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onPrimaryContainer.withAlpha(180),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // プログレスバー
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: (stepIndex + 1) / totalSteps,
              minHeight: 3,
              backgroundColor:
                  theme.colorScheme.onPrimaryContainer.withAlpha(30),
              valueColor: AlwaysStoppedAnimation(
                theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // 指示テキスト
          Row(
            children: [
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  step.instruction,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(
              step.hint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer.withAlpha(160),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _checkRouteAdvance(TutorialStep step) {
    final path = GoRouterState.of(context).uri.path;

    if (step == TutorialStep.goToDreams && path == '/dreams') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(tutorialStateProvider.notifier).advanceStep();
      });
    } else if (step == TutorialStep.goToGoals && path == '/goals') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(tutorialStateProvider.notifier).advanceStep();
      });
    }
  }

  Future<void> _skipTutorial() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('チュートリアルをスキップ'),
        content: const Text('チュートリアルを終了しますか？\n'
            'チュートリアル中に作成したデータは削除されます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('続ける'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('スキップ'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _cleanupAndFinish();
    }
  }

  Future<void> _cleanupAndFinish() async {
    final tutorialService = ref.read(tutorialServiceProvider);
    final dreamId = tutorialService.tutorialDreamId;

    // チュートリアルで作成した夢を削除（目標もカスケード削除される）
    if (dreamId != null) {
      await ref.read(dreamListProvider.notifier).deleteDream(dreamId);
    }

    await tutorialService.finish();
    ref.read(tutorialStateProvider.notifier).reset();
  }
}

/// チュートリアル完了バナー.
class _CompletedBanner extends ConsumerWidget {
  const _CompletedBanner({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withAlpha(60),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle,
            size: 32,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            'チュートリアル完了！',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'アプリの基本操作を体験しました。\n'
            'チュートリアルで作成したデータをどうしますか？',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer.withAlpha(180),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: () => _deleteData(ref),
                child: const Text('データを削除'),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: () => _keepData(ref),
                child: const Text('データを保持'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _deleteData(WidgetRef ref) async {
    final tutorialService = ref.read(tutorialServiceProvider);
    final dreamId = tutorialService.tutorialDreamId;

    if (dreamId != null) {
      await ref.read(dreamListProvider.notifier).deleteDream(dreamId);
    }

    await tutorialService.finish();
    ref.read(tutorialStateProvider.notifier).reset();
  }

  Future<void> _keepData(WidgetRef ref) async {
    final tutorialService = ref.read(tutorialServiceProvider);
    await tutorialService.finish();
    ref.read(tutorialStateProvider.notifier).reset();
  }
}

/// チュートリアル状態.
class TutorialState {
  const TutorialState({required this.isActive, required this.step});

  static const inactive =
      TutorialState(isActive: false, step: TutorialStep.goToDreams);

  /// チュートリアル実行中か.
  final bool isActive;

  /// 現在のステップ.
  final TutorialStep step;
}

/// チュートリアル状態のNotifier.
class TutorialStateNotifier extends StateNotifier<TutorialState> {
  /// TutorialStateNotifierを作成する.
  TutorialStateNotifier(this._service)
      : super(TutorialState(
          isActive: _service.isActive,
          step: _service.isActive
              ? _service.currentStep
              : TutorialStep.goToDreams,
        ));

  final TutorialService _service;

  /// チュートリアルを開始する.
  Future<void> start() async {
    await _service.start();
    state = const TutorialState(
      isActive: true,
      step: TutorialStep.goToDreams,
    );
  }

  /// 次のステップに進む.
  Future<void> advanceStep() async {
    if (!state.isActive) return;
    await _service.advanceStep();
    state = TutorialState(
      isActive: true,
      step: _service.currentStep,
    );
  }

  /// チュートリアルをリセットする.
  void reset() {
    state = TutorialState.inactive;
  }
}

/// チュートリアル状態のProvider.
final tutorialStateProvider =
    StateNotifierProvider<TutorialStateNotifier, TutorialState>((ref) {
  final service = ref.watch(tutorialServiceProvider);
  return TutorialStateNotifier(service);
});
