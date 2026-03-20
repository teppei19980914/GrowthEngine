/// アプリケーションのルートウィジェット.
///
/// MaterialApp + go_router + テーマ設定を統合する.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'dialogs/app_guide_dialog.dart';
import 'dialogs/help_dialog.dart';
import 'dialogs/monitor_submission_dialog.dart';
import 'dialogs/release_notes_dialog.dart';
import 'services/invite_service.dart';
import 'pages/book_page.dart';
import 'pages/constellation_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/dream_page.dart';
import 'pages/gantt_page.dart';
import 'pages/goal_page.dart';
import 'pages/settings_page.dart';
import 'pages/stats_page.dart';
import 'providers/book_providers.dart';
import 'providers/dashboard_providers.dart';
import 'providers/dream_providers.dart';
import 'providers/goal_providers.dart';
import 'providers/service_providers.dart';
import 'providers/theme_provider.dart';
import 'services/remote_config_service.dart';
import 'services/trial_limit_service.dart' show isPremium, setInvitePremium;
import 'theme/app_theme.dart';
import 'widgets/navigation/app_drawer.dart';
import 'widgets/milestone/milestone_button.dart';
import 'widgets/contact/contact_button.dart';
import 'services/tutorial_service.dart';
import 'widgets/tutorial/tutorial_banner.dart';
import 'widgets/tutorial/tutorial_overlay.dart';
import 'widgets/tutorial/tutorial_target_keys.dart';

/// ページタイトルマップ.
const _pageTitles = <String, String>{
  '/': 'ダッシュボード',
  '/dreams': '夢',
  '/goals': '目標',
  '/gantt': 'ガントチャート',
  '/books': '書籍',
  '/constellations': '星座',
  '/stats': '統計',
  '/settings': '設定',
};

/// フェード遷移のルートを生成するヘルパー.
GoRoute _fadeRoute(String path, Widget page) => GoRoute(
      path: path,
      pageBuilder: (context, state) => CustomTransitionPage<void>(
        key: state.pageKey,
        child: page,
        transitionDuration: const Duration(milliseconds: 200),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );

/// go_routerの設定.
final _router = GoRouter(
  navigatorKey: TutorialTargetKeys.navigatorKey,
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return _AppShell(
          title: _pageTitles[state.uri.path] ?? '',
          currentPath: state.uri.path,
          child: child,
        );
      },
      routes: [
        _fadeRoute('/', const DashboardPage()),
        _fadeRoute('/dreams', const DreamPage()),
        _fadeRoute('/goals', const GoalPage()),
        _fadeRoute('/gantt', const GanttPage()),
        _fadeRoute('/books', const BookPage()),
        _fadeRoute('/constellations', const ConstellationPage()),
        _fadeRoute('/stats', const StatsPage()),
        _fadeRoute('/settings', const SettingsPage()),
      ],
    ),
  ],
);

/// アプリケーションのルートウィジェット.
class YumeLogApp extends ConsumerWidget {
  /// YumeLogAppを作成する.
  const YumeLogApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeType = ref.watch(themeProvider);

    // 招待コードの有効状態をグローバルフラグに同期
    final inviteStatus = ref.watch(inviteStatusProvider);
    setInvitePremium(enabled: inviteStatus.isActive);

    return MaterialApp.router(
      title: 'ユメログ - 夢実現支援',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode:
          themeType == ThemeType.dark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: _router,
      // ステータスバー+完了ダイアログをNavigatorの上に配置
      builder: (context, child) => Stack(
        children: [
          child!,
          const TutorialOverlay(),
        ],
      ),
    );
  }
}

/// ボトムナビゲーションの定義.
const _bottomNavItems = [
  (path: '/', icon: Icons.home_outlined, activeIcon: Icons.home, label: 'ホーム'),
  (
    path: '/dreams',
    icon: Icons.auto_awesome_outlined,
    activeIcon: Icons.auto_awesome,
    label: '夢',
  ),
  (
    path: '/goals',
    icon: Icons.flag_outlined,
    activeIcon: Icons.flag,
    label: '目標',
  ),
  (
    path: '/gantt',
    icon: Icons.view_timeline_outlined,
    activeIcon: Icons.view_timeline,
    label: 'ガントチャート',
  ),
];

/// アプリケーションシェル（Scaffold + AppBar + Drawer + BottomNav）.
class _AppShell extends ConsumerStatefulWidget {
  const _AppShell({
    required this.title,
    required this.currentPath,
    required this.child,
  });

  final String title;
  final String currentPath;
  final Widget child;

  @override
  ConsumerState<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<_AppShell> {
  bool _resetChecked = false;
  bool _releaseNotesChecked = false;
  bool _monitorChecked = false;

  static const _seenVersionKey = 'release_notes_seen_version';
  static const _monitorSubmittedKey = 'monitor_data_submitted';

  /// モニターデータ提出の確認.
  void _checkMonitorSubmission() {
    if (_monitorChecked) return;
    _monitorChecked = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final prefs = ref.read(sharedPreferencesProvider);

      // 既に提出済みならスキップ
      if (prefs.getBool(_monitorSubmittedKey) ?? false) return;

      final inviteService = InviteService(prefs);
      final status = inviteService.getStatus();

      // 招待コード未使用ならスキップ
      if (inviteService.savedCode == null) return;

      // 表示条件: 期限7日前〜期限切れ後7日間
      int displayRemainingDays;
      String inviteName;
      if (status.isActive && status.remainingDays != null) {
        // 有効期間内: 残り7日以内のみ
        if (status.remainingDays! > 7) return;
        displayRemainingDays = status.remainingDays!;
        inviteName = status.name ?? '';
      } else if (status.expiredAt != null) {
        // 期限切れ: 切れてから7日以内のみ
        final daysSinceExpiry =
            DateTime.now().difference(status.expiredAt!).inDays;
        if (daysSinceExpiry > 7) return;
        displayRemainingDays = 0;
        inviteName = status.name ?? '';
      } else {
        return;
      }

      if (!mounted) return;
      await showMonitorSubmissionDialog(
        context,
        remainingDays: displayRemainingDays,
        inviteName: inviteName,
        exportData: () async {
          final exportService = ref.read(dataExportServiceProvider);
          return exportService.exportData();
        },
      );

      // 提出完了後はフラグを保存（ダイアログ内で送信成功した場合）
      await prefs.setBool(_monitorSubmittedKey, true);
    });
  }

  /// チュートリアルを開始する.
  Future<void> _startTutorial() async {
    final tutorialState = ref.read(tutorialStateProvider);
    if (tutorialState.isActive) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('チュートリアルを開始'),
        content: const Text(
          '実際にアプリを操作しながら基本的な使い方を体験します。\n\n'
          '画面上部のバナーに従って操作してください。\n'
          'チュートリアル中に作成したデータは、完了時に保持するか削除するかを選べます。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('開始する'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await ref.read(tutorialStateProvider.notifier).start();
    if (!mounted) return;
    GoRouter.of(context).go('/');
  }

  /// リリースノートの確認と表示.
  void _checkReleaseNotes() {
    if (_releaseNotesChecked) return;
    _releaseNotesChecked = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final prefs = ref.read(sharedPreferencesProvider);
      final service = RemoteConfigService(prefs);
      final release = await service.fetchReleaseNotes();
      if (release == null || !mounted) return;

      final seenVersion = prefs.getString(_seenVersionKey);
      // 初回アクセス（seenVersionが未保存）はスキップしてバージョンだけ保存
      if (seenVersion == null) {
        await prefs.setString(_seenVersionKey, release.version);
        return;
      }
      if (seenVersion == release.version) return;
      // リリース通知がOFFの場合はバージョンだけ更新してスキップ
      if (!(prefs.getBool('release_notes_enabled') ?? true)) {
        await prefs.setString(_seenVersionKey, release.version);
        return;
      }

      await prefs.setString(_seenVersionKey, release.version);
      if (!mounted) return;
      await showReleaseNotesDialog(
        context,
        version: release.version,
        notes: release.notes,
      );
    });
  }

  /// ルート変更を検知してチュートリアルステップを自動進行する.
  void _checkTutorialRouteAdvance(TutorialStep step) {
    final path = GoRouterState.of(context).uri.path;

    const routeMap = {
      TutorialStep.goToDreams: '/dreams',
      TutorialStep.goToGoals: '/goals',
      TutorialStep.goToGantt: '/gantt',
    };

    final expectedPath = routeMap[step];
    if (expectedPath != null && path == expectedPath) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(tutorialStateProvider.notifier).advanceStep();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // resetOnAccess: データベースリセット処理（どのルートでも実行）
    if (!_resetChecked) {
      _resetChecked = true;
      final prefs = ref.read(sharedPreferencesProvider);
      if (prefs.getBool(resetPendingKey) ?? false) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          final service = ref.read(dataExportServiceProvider);
          await service.clearAllData();
          await prefs.remove(resetPendingKey);
          // リセット後、全Providerのキャッシュを更新してUIに反映
          ref.invalidate(dreamListProvider);
          ref.invalidate(goalListProvider);
          ref.invalidate(bookListProvider);
          ref.invalidate(allLogsProvider);
        });
      }
    }

    // リリースノートの確認
    _checkReleaseNotes();

    // モニターデータ提出の確認
    _checkMonitorSubmission();

    // チュートリアル: ルート変更を検知してステップを自動進行
    final tutorialState = ref.watch(tutorialStateProvider);
    if (tutorialState.isActive) {
      _checkTutorialRouteAdvance(tutorialState.step);
    }

    final selectedIndex = _bottomNavItems
        .indexWhere((item) => item.path == widget.currentPath);
    final hasBottomNav = selectedIndex >= 0;

    // NavigationDestination にチュートリアル用 GlobalKey を付与
    final navKeyMap = <String, GlobalKey>{
      '/dreams': TutorialTargetKeys.dreamTab,
      '/goals': TutorialTargetKeys.goalTab,
      '/gantt': TutorialTargetKeys.ganttTab,
    };

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
            leading: Builder(
              builder: (context) => IconButton(
                key: TutorialTargetKeys.menuButton,
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
                tooltip: 'メニュー',
              ),
            ),
            actions: [
              IconButton(
                icon: CustomPaint(
                  size: const Size(22, 22),
                  painter: _BeginnerMarkPainter(
                    color: IconTheme.of(context).color ?? Colors.white,
                  ),
                ),
                tooltip: '使い方',
                onPressed: () => showAppGuideDialog(
                  context,
                  isPremium: isPremium,
                  onStartTutorial: _startTutorial,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.help_outline),
                tooltip: 'ヘルプ',
                onPressed: () {
                  final prefs = ref.read(sharedPreferencesProvider);
                  showHelpDialog(context, prefs: prefs);
                },
              ),
              const ContactButton(),
              const MilestoneButton(),
            ],
          ),
          drawer: const AppDrawer(),
          body: widget.child,
          bottomNavigationBar: hasBottomNav
          ? NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) =>
                  context.go(_bottomNavItems[index].path),
              destinations: [
                for (final item in _bottomNavItems)
                  NavigationDestination(
                    key: navKeyMap[item.path],
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.activeIcon),
                    label: item.label,
                  ),
              ],
            )
          : null,
        ),
        // グレーアウト+スポットライト（Scaffoldの上、ダイアログの下に表示）
        const TutorialSpotlight(),
      ],
    );
  }
}

/// 初心者マーク（若葉マーク）のカスタムペインター.
class _BeginnerMarkPainter extends CustomPainter {
  _BeginnerMarkPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 若葉マーク: 上が尖り、左右に膨らみ、下が尖ったV字盾型
    // 左半分
    final leftPath = Path()
      ..moveTo(w * 0.5, h * 0.02) // 上の頂点
      ..cubicTo(
        w * 0.1, h * 0.15, // 左上に膨らむ
        w * 0.05, h * 0.55, // 左の最大膨らみ
        w * 0.5, h * 0.98, // 下の頂点
      )
      ..lineTo(w * 0.5, h * 0.02)
      ..close();

    // 右半分
    final rightPath = Path()
      ..moveTo(w * 0.5, h * 0.02) // 上の頂点
      ..cubicTo(
        w * 0.9, h * 0.15, // 右上に膨らむ
        w * 0.95, h * 0.55, // 右の最大膨らみ
        w * 0.5, h * 0.98, // 下の頂点
      )
      ..lineTo(w * 0.5, h * 0.02)
      ..close();

    // 左半分を塗る（やや薄く）
    final leftFill = Paint()
      ..color = color.withAlpha(100)
      ..style = PaintingStyle.fill;
    canvas.drawPath(leftPath, leftFill);

    // 右半分を塗る（やや濃く）
    final rightFill = Paint()
      ..color = color.withAlpha(180)
      ..style = PaintingStyle.fill;
    canvas.drawPath(rightPath, rightFill);

    // 全体の輪郭
    final outline = Path()
      ..moveTo(w * 0.5, h * 0.02)
      ..cubicTo(w * 0.1, h * 0.15, w * 0.05, h * 0.55, w * 0.5, h * 0.98)
      ..cubicTo(w * 0.95, h * 0.55, w * 0.9, h * 0.15, w * 0.5, h * 0.02)
      ..close();

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(outline, strokePaint);

    // 中央の縦線
    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(w * 0.5, h * 0.1),
      Offset(w * 0.5, h * 0.9),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(_BeginnerMarkPainter oldDelegate) =>
      color != oldDelegate.color;
}
