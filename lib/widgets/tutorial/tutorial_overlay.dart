/// チュートリアルオーバーレイ.
///
/// 2つのウィジェットに分離して配置する:
/// - [TutorialOverlay]: 完了ダイアログのみ（MaterialApp.builder内、ダイアログより上）
/// - [TutorialSpotlight]: グレーアウト+スポットライト+吹き出し（Scaffold外Stack内、ダイアログより下）
///
/// 吹き出しはターゲットウィジェット付近に動的に配置される.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/dream_providers.dart';
import '../../providers/service_providers.dart';
import '../../services/tutorial_service.dart';
import 'tutorial_banner.dart';
import 'tutorial_target_keys.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TutorialOverlay（MaterialApp.builder 内に配置）
// ─────────────────────────────────────────────────────────────────────────────

/// チュートリアルの完了ダイアログ + ダイアログ上の吹き出し.
///
/// MaterialApp.builder 内の Stack に配置し、
/// ダイアログより上に完了画面やダイアログ内ターゲットの吹き出しを表示する.
class TutorialOverlay extends ConsumerStatefulWidget {
  /// TutorialOverlayを作成する.
  const TutorialOverlay({super.key});

  @override
  ConsumerState<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends ConsumerState<TutorialOverlay> {
  GlobalKey? _lastDialogKey;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tutorialStateProvider);
    if (!state.isActive) return const SizedBox.shrink();

    if (state.step == TutorialStep.completed) {
      _lastDialogKey = null;
      return _buildCompletedOverlay(context);
    }

    // ダイアログ内のターゲットが表示されていれば吹き出しを表示
    final dialogKey = _getDialogTargetKey(state.step);

    // 動的チェック: ダイアログ開閉を検知
    _scheduleDialogRecheck(state.step, dialogKey);
    _lastDialogKey = dialogKey;

    if (dialogKey != null) {
      final screenSize = MediaQuery.of(context).size;
      return Stack(
        children: [
          _DialogBubble(
            step: state.step,
            screenSize: screenSize,
            onClose: () => _stopTutorial(ref),
            instruction: _getDialogInstruction(state.step),
            hint: _getDialogHint(state.step),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  /// ダイアログ内ターゲットのGlobalKeyを返す（該当なしならnull）.
  GlobalKey? _getDialogTargetKey(TutorialStep step) {
    switch (step) {
      case TutorialStep.addDream:
        final key = TutorialTargetKeys.dreamDialogSubmit;
        return key.currentContext != null ? key : null;
      case TutorialStep.addGoal:
        final key = TutorialTargetKeys.goalDialogSubmit;
        return key.currentContext != null ? key : null;
      default:
        return null;
    }
  }

  void _scheduleDialogRecheck(TutorialStep step, GlobalKey? currentKey) {
    if (step == TutorialStep.addDream || step == TutorialStep.addGoal) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final newKey = _getDialogTargetKey(step);
        if (newKey != _lastDialogKey) {
          setState(() {});
        } else {
          _scheduleDialogRecheck(step, currentKey);
        }
      });
    }
  }

  String _getDialogInstruction(TutorialStep step) {
    if (step == TutorialStep.addDream) {
      return 'タイトルを入力して「追加」をタップしてください';
    }
    if (step == TutorialStep.addGoal) {
      return '各項目を入力して「追加」をタップしてください';
    }
    return step.instruction;
  }

  String _getDialogHint(TutorialStep step) {
    if (step == TutorialStep.addDream) {
      return '説明やWhyは後から編集できます';
    }
    if (step == TutorialStep.addGoal) {
      return 'What・When・Howを入力してください';
    }
    return step.hint;
  }

  Future<void> _stopTutorial(WidgetRef ref) async {
    final tutorialService = ref.read(tutorialServiceProvider);
    final dreamId = tutorialService.tutorialDreamId;

    if (dreamId != null) {
      await ref.read(dreamListProvider.notifier).deleteDream(dreamId);
    }

    await tutorialService.finish();
    ref.read(tutorialStateProvider.notifier).reset();
  }

  Widget _buildCompletedOverlay(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {}, // 背景タップを吸収
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.black54,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(32),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'チュートリアル完了！',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'アプリの基本操作を体験しました。\n'
                  'チュートリアルで作成したデータをどうしますか？',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline,
                        size: 14, color: theme.hintColor),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '設定画面からいつでもチュートリアルを再実行できます',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () => _stopTutorial(ref),
                      child: const Text('データを削除'),
                    ),
                    FilledButton(
                      onPressed: () async {
                        final tutorialService =
                            ref.read(tutorialServiceProvider);
                        await tutorialService.finish();
                        ref.read(tutorialStateProvider.notifier).reset();
                      },
                      child: const Text('データを保持'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TutorialSpotlight（Scaffold 外の Stack に配置）
// ─────────────────────────────────────────────────────────────────────────────

/// チュートリアルのグレーアウト+スポットライト+吹き出し.
///
/// Scaffold を囲む Stack に配置し、
/// ダイアログより下にグレーアウト・スポットライト・指示吹き出しを表示する.
class TutorialSpotlight extends ConsumerStatefulWidget {
  /// TutorialSpotlightを作成する.
  const TutorialSpotlight({super.key});

  @override
  ConsumerState<TutorialSpotlight> createState() => _TutorialSpotlightState();
}

class _TutorialSpotlightState extends ConsumerState<TutorialSpotlight>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  GlobalKey? _lastTargetKey;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// ダイアログ内のターゲットが現在表示中か判定する.
  bool _isDialogTargetActive(TutorialStep step) {
    if (step == TutorialStep.addDream) {
      return TutorialTargetKeys.dreamDialogSubmit.currentContext != null;
    }
    if (step == TutorialStep.addGoal) {
      return TutorialTargetKeys.goalDialogSubmit.currentContext != null;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tutorialStateProvider);

    // 非アクティブ or 完了時はスポットライト不要
    if (!state.isActive || state.step == TutorialStep.completed) {
      _lastTargetKey = null;
      if (_pulseController.isAnimating) _pulseController.stop();
      return const SizedBox.shrink();
    }

    // ダイアログ内ターゲットが表示中 → TutorialOverlayに委譲
    if (_isDialogTargetActive(state.step)) {
      _lastTargetKey = null;
      if (_pulseController.isAnimating) _pulseController.stop();
      return const SizedBox.shrink();
    }

    // ターゲットキーを取得
    final targetKey = _getTargetKey(state.step);
    final targetRect = _findTargetRectFromKey(targetKey);

    // 動的ターゲット変化の検知（ドロワー開閉など）
    _scheduleTargetRecheck(state.step, targetKey);
    _lastTargetKey = targetKey;

    final screenSize = MediaQuery.of(context).size;

    // ターゲットが未マウント → スポットライトなしで吹き出しのみ表示
    if (targetRect == null) {
      if (_pulseController.isAnimating) _pulseController.stop();
      // ガントチャート制限時（addTask でターゲットなし）は完了ステップに進める
      final onClose = state.step == TutorialStep.addTask
          ? _finishTutorial
          : _stopTutorial;
      return Stack(
        children: [
          _FloatingBubble(
            step: state.step,
            screenSize: screenSize,
            onClose: onClose,
            instruction: _getInstruction(state.step, targetKey),
            hint: _getHint(state.step, targetKey),
          ),
        ],
      );
    }

    // パルスアニメーション開始
    if (!_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    }

    return Stack(
      children: [
        // グレーアウト背景 + スポットライト（タップ透過）
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return CustomPaint(
                painter: _SpotlightPainter(
                  targetRect: targetRect,
                  pulseValue: _pulseController.value,
                ),
                child: const SizedBox.expand(),
              );
            },
          ),
        ),
        // 吹き出し（タップ透過）+ ×ボタン（タップ可能）
        _TutorialBubble(
          step: state.step,
          targetRect: targetRect,
          screenSize: screenSize,
          onClose: _stopTutorial,
          instruction: _getInstruction(state.step, targetKey),
          hint: _getHint(state.step, targetKey),
        ),
      ],
    );
  }

  /// ターゲットが動的に切り替わる可能性があるステップか判定する.
  bool _isDynamicStep(TutorialStep step) {
    return step == TutorialStep.addDream ||
        step == TutorialStep.addGoal ||
        step == TutorialStep.addTask;
  }

  /// 動的にターゲットが変わるステップで次フレームの再チェックを予約する.
  void _scheduleTargetRecheck(TutorialStep step, GlobalKey? currentKey) {
    if (_isDynamicStep(step)) {
      // ドロワー/ダイアログ開閉等でターゲットが変わる可能性がある
      // 変化するまで毎フレーム再チェックを継続する
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // ダイアログ内ターゲットが出現/消滅したら再描画
        if (_isDialogTargetActive(step)) {
          setState(() {});
          return;
        }
        final newKey = _getTargetKey(step);
        if (newKey != _lastTargetKey ||
            _findTargetRectFromKey(newKey) == null) {
          setState(() {});
        } else {
          // まだ変化なし → 次フレームも再チェック
          _scheduleTargetRecheck(step, currentKey);
        }
      });
    } else if (_findTargetRectFromKey(currentKey) == null) {
      // ターゲットが未マウント → 次フレームで再試行
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
  }

  /// GlobalKeyからスクリーン座標を取得する.
  Rect? _findTargetRectFromKey(GlobalKey? key) {
    if (key == null) return null;

    final ctx = key.currentContext;
    if (ctx == null) return null;

    final renderBox = ctx.findRenderObject();
    if (renderBox is! RenderBox || !renderBox.attached) return null;
    if (!renderBox.hasSize) return null;

    final position = renderBox.localToGlobal(Offset.zero);
    return position & renderBox.size;
  }

  /// ステップに対応するGlobalKeyを返す.
  GlobalKey? _getTargetKey(TutorialStep step) {
    switch (step) {
      case TutorialStep.goToDreams:
        return TutorialTargetKeys.dreamTab;
      case TutorialStep.addDream:
        return TutorialTargetKeys.addDreamButton;
      case TutorialStep.goToGoals:
        return TutorialTargetKeys.goalTab;
      case TutorialStep.addGoal:
        return TutorialTargetKeys.addGoalButton;
      case TutorialStep.goToGantt:
        return TutorialTargetKeys.ganttTab;
      case TutorialStep.addTask:
        if (TutorialTargetKeys.addTaskButton.currentContext != null) {
          return TutorialTargetKeys.addTaskButton;
        }
        return TutorialTargetKeys.ganttDropdown;
      case TutorialStep.completed:
        return null;
    }
  }

  /// ステップとターゲットに応じた指示テキストを返す.
  String _getInstruction(TutorialStep step, GlobalKey? targetKey) {
    // ガントチャート画面でターゲットが見つからない（Web体験版等）
    if (step == TutorialStep.addTask &&
        _findTargetRectFromKey(targetKey) == null) {
      return 'ガントチャートで目標達成までの道のりを可視化しよう！';
    }
    return step.instruction;
  }

  /// ステップとターゲットに応じたヒントテキストを返す.
  String _getHint(TutorialStep step, GlobalKey? targetKey) {
    if (step == TutorialStep.addTask &&
        _findTargetRectFromKey(targetKey) == null) {
      return 'サブスクWebアプリまたはネイティブアプリで'
          'タスク管理・進捗トラッキングなど全機能をご利用いただけます';
    }
    return step.hint;
  }

  /// チュートリアルを中断し、データを削除する.
  Future<void> _stopTutorial() async {
    final tutorialService = ref.read(tutorialServiceProvider);
    final dreamId = tutorialService.tutorialDreamId;

    if (dreamId != null) {
      await ref.read(dreamListProvider.notifier).deleteDream(dreamId);
    }

    await tutorialService.finish();
    ref.read(tutorialStateProvider.notifier).reset();
  }

  /// チュートリアルを完了ステップに進め、保持/削除ダイアログを表示する.
  Future<void> _finishTutorial() async {
    await ref.read(tutorialStateProvider.notifier).advanceStep();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 吹き出しウィジェット（ターゲット付近）
// ─────────────────────────────────────────────────────────────────────────────

/// ターゲット付近に表示される吹き出し.
class _TutorialBubble extends StatelessWidget {
  const _TutorialBubble({
    required this.step,
    required this.targetRect,
    required this.screenSize,
    required this.onClose,
    required this.instruction,
    required this.hint,
  });

  final TutorialStep step;
  final Rect targetRect;
  final Size screenSize;
  final VoidCallback onClose;
  final String instruction;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stepIndex = step.index;
    final totalSteps = TutorialStep.values.length - 1;

    const bubbleMargin = 16.0;
    const arrowSize = 8.0;
    final spotlightBottom = targetRect.bottom + 8 + arrowSize;
    final spotlightTop = targetRect.top - 8 - arrowSize;

    // ターゲットの下に十分なスペースがあるか判定
    final spaceBelow = screenSize.height - spotlightBottom;
    final showBelow = spaceBelow > 100;

    // 吹き出しの水平位置: ターゲットの中心に寄せるが画面内に収める
    final bubbleWidth = (screenSize.width - bubbleMargin * 2)
        .clamp(200.0, 360.0);
    var bubbleLeft = targetRect.center.dx - bubbleWidth / 2;
    bubbleLeft = bubbleLeft.clamp(
      bubbleMargin,
      screenSize.width - bubbleWidth - bubbleMargin,
    );

    // 矢印の水平位置（ターゲット中心）
    final arrowLeft =
        (targetRect.center.dx - bubbleLeft - arrowSize).clamp(
      12.0,
      bubbleWidth - arrowSize * 2 - 12,
    );

    final bubbleContent = _buildBubbleContent(
      theme: theme,
      bubbleWidth: bubbleWidth,
      stepIndex: stepIndex,
      totalSteps: totalSteps,
    );

    // 矢印ウィジェット
    final arrow = CustomPaint(
      size: Size(arrowSize * 2, arrowSize),
      painter: _ArrowPainter(
        color: theme.colorScheme.primary,
        pointUp: !showBelow,
      ),
    );

    return Positioned(
      left: bubbleLeft,
      top: showBelow ? spotlightBottom : null,
      bottom: showBelow ? null : screenSize.height - spotlightTop,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showBelow)
                Padding(
                  padding: EdgeInsets.only(left: arrowLeft),
                  child: arrow,
                ),
              // 吹き出し本体（タップ透過）
              IgnorePointer(child: bubbleContent),
              if (!showBelow)
                Padding(
                  padding: EdgeInsets.only(left: arrowLeft),
                  child: arrow,
                ),
            ],
          ),
          // ×ボタン（タップ可能）
          Positioned(
            right: 4,
            top: showBelow ? arrowSize + 4 : 4,
            child: GestureDetector(
              onTap: onClose,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onPrimary.withAlpha(40),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close,
                    size: 14, color: theme.colorScheme.onPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubbleContent({
    required ThemeData theme,
    required double bubbleWidth,
    required int stepIndex,
    required int totalSteps,
  }) {
    return Container(
      width: bubbleWidth,
      padding: const EdgeInsets.fromLTRB(12, 8, 32, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(60),
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
              Icon(Icons.school,
                  size: 14, color: theme.colorScheme.onPrimary),
              const SizedBox(width: 4),
              Text(
                'ステップ ${stepIndex + 1} / $totalSteps',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimary.withAlpha(200),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            instruction,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            hint,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onPrimary.withAlpha(180),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// フローティング吹き出し（ターゲットなし時）
// ─────────────────────────────────────────────────────────────────────────────

/// ターゲットが見つからない場合に画面中央上部に表示される吹き出し.
class _FloatingBubble extends StatelessWidget {
  const _FloatingBubble({
    required this.step,
    required this.screenSize,
    required this.onClose,
    required this.instruction,
    required this.hint,
  });

  final TutorialStep step;
  final Size screenSize;
  final VoidCallback onClose;
  final String instruction;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stepIndex = step.index;
    final totalSteps = TutorialStep.values.length - 1;

    const bubbleMargin = 16.0;
    final bubbleWidth = (screenSize.width - bubbleMargin * 2)
        .clamp(200.0, 360.0);
    final bubbleLeft = (screenSize.width - bubbleWidth) / 2;

    final bubbleContent = Container(
      width: bubbleWidth,
      padding: const EdgeInsets.fromLTRB(12, 8, 32, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(60),
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
              Icon(Icons.school,
                  size: 14, color: theme.colorScheme.onPrimary),
              const SizedBox(width: 4),
              Text(
                'ステップ ${stepIndex + 1} / $totalSteps',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimary.withAlpha(200),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            instruction,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            hint,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onPrimary.withAlpha(180),
            ),
          ),
        ],
      ),
    );

    return Positioned(
      left: bubbleLeft,
      top: 80,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IgnorePointer(child: bubbleContent),
          // ×ボタン（タップ可能）
          Positioned(
            right: 4,
            top: 4,
            child: GestureDetector(
              onTap: onClose,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onPrimary.withAlpha(40),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close,
                    size: 14, color: theme.colorScheme.onPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ダイアログ表示時の吹き出し（画面下部に配置）
// ─────────────────────────────────────────────────────────────────────────────

/// ダイアログが開いている時に画面下部に表示される吹き出し.
class _DialogBubble extends StatelessWidget {
  const _DialogBubble({
    required this.step,
    required this.screenSize,
    required this.onClose,
    required this.instruction,
    required this.hint,
  });

  final TutorialStep step;
  final Size screenSize;
  final VoidCallback onClose;
  final String instruction;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stepIndex = step.index;
    final totalSteps = TutorialStep.values.length - 1;

    const bubbleMargin = 16.0;
    final bubbleWidth = (screenSize.width - bubbleMargin * 2)
        .clamp(200.0, 360.0);
    final bubbleLeft = (screenSize.width - bubbleWidth) / 2;

    final bubbleContent = Container(
      width: bubbleWidth,
      padding: const EdgeInsets.fromLTRB(12, 8, 32, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(60),
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
              Icon(Icons.school,
                  size: 14, color: theme.colorScheme.onPrimary),
              const SizedBox(width: 4),
              Text(
                'ステップ ${stepIndex + 1} / $totalSteps',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimary.withAlpha(200),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            instruction,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            hint,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onPrimary.withAlpha(180),
            ),
          ),
        ],
      ),
    );

    return Positioned(
      left: bubbleLeft,
      top: bubbleMargin,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IgnorePointer(child: bubbleContent),
          Positioned(
            right: 4,
            top: 4,
            child: GestureDetector(
              onTap: onClose,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onPrimary.withAlpha(40),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close,
                    size: 14, color: theme.colorScheme.onPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 吹き出しの矢印を描画するPainter.
class _ArrowPainter extends CustomPainter {
  _ArrowPainter({required this.color, required this.pointUp});

  final Color color;
  final bool pointUp;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();

    if (pointUp) {
      // ▲
      path.moveTo(0, size.height);
      path.lineTo(size.width / 2, 0);
      path.lineTo(size.width, size.height);
    } else {
      // ▼
      path.moveTo(0, 0);
      path.lineTo(size.width / 2, size.height);
      path.lineTo(size.width, 0);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ArrowPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.pointUp != pointUp;
}

// ─────────────────────────────────────────────────────────────────────────────
// スポットライト描画
// ─────────────────────────────────────────────────────────────────────────────

/// スポットライト切り抜きを描画するCustomPainter.
class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter({
    required this.targetRect,
    required this.pulseValue,
  });

  final Rect targetRect;
  final double pulseValue;

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0x88000000);
    final spotlightRect = targetRect.inflate(8);

    final path = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(
        spotlightRect,
        const Radius.circular(12),
      ))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, bgPaint);

    final pulseRadius = 4 + pulseValue * 4;
    final pulsePaint = Paint()
      ..color = Colors.white.withAlpha((60 + 40 * pulseValue).toInt())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        spotlightRect.inflate(pulseRadius),
        Radius.circular(12 + pulseRadius),
      ),
      pulsePaint,
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter oldDelegate) =>
      oldDelegate.targetRect != targetRect ||
      oldDelegate.pulseValue != pulseValue;
}
