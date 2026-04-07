/// アプリケーションのルートウィジェット.
///
/// MaterialApp + go_router + テーマ設定を統合する.
library;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'dialogs/app_guide_dialog.dart';
import 'services/demo_data_service.dart' show isDemoDataSeeded, seedDemoData;
import 'services/firestore_sync_service.dart' show FirestoreSyncService;
import 'services/sync_manager.dart';
import 'dialogs/help_dialog.dart';
import 'dialogs/monitor_submission_dialog.dart';
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
import 'services/remote_config_service.dart'
    show RemoteConfigService, resetPendingKey;
import 'services/stripe_service.dart' show StripeService, portalOpenPending;
import 'services/trial_limit_service.dart'
    show isPremium, setInvitePremium, setDeveloperMode, setSubscriptionPremium;
import 'theme/app_theme.dart';
import 'l10n/app_labels.dart';
import 'widgets/navigation/app_drawer.dart';
import 'widgets/milestone/milestone_button.dart';
import 'widgets/contact/contact_button.dart';
import 'services/tutorial_service.dart';
import 'widgets/notification/notification_button.dart';
import 'widgets/tutorial/tutorial_banner.dart';
import 'widgets/tutorial/tutorial_overlay.dart';
import 'widgets/tutorial/tutorial_target_keys.dart';

/// テスト環境で受信ボックスチェックを無効化するフラグ.
bool _disableInboxCheck = false;

/// テスト用: 受信ボックスの自動チェックを無効化する.
void disableInboxCheckForTest() => _disableInboxCheck = true;

/// ページタイトルマップ.
const _pageTitles = <String, String>{
  '/': AppLabels.pageHome,
  '/dreams': AppLabels.pageDreams,
  '/goals': AppLabels.pageGoals,
  '/gantt': AppLabels.pageSchedule,
  '/books': AppLabels.pageBooks,
  '/constellations': AppLabels.pageConstellations,
  '/stats': AppLabels.pageStats,
  '/settings': AppLabels.pageSettings,
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
class YumeHashiApp extends ConsumerWidget {
  /// YumeHashiAppを作成する.
  const YumeHashiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeType = ref.watch(themeProvider);

    // 招待コードの有効状態をグローバルフラグに同期
    final inviteStatus = ref.watch(inviteStatusProvider);
    setInvitePremium(enabled: inviteStatus.isActive);

    return MaterialApp.router(
      title: AppLabels.appTitle,
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
  (path: '/', icon: Icons.home_outlined, activeIcon: Icons.home, label: AppLabels.pageHome),
  (
    path: '/dreams',
    icon: Icons.auto_awesome_outlined,
    activeIcon: Icons.auto_awesome,
    label: AppLabels.pageDreams,
  ),
  (
    path: '/goals',
    icon: Icons.flag_outlined,
    activeIcon: Icons.flag,
    label: AppLabels.pageGoals,
  ),
  (
    path: '/gantt',
    icon: Icons.view_timeline_outlined,
    activeIcon: Icons.view_timeline,
    label: AppLabels.pageSchedule,
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
  bool _demoChecked = false;
  bool _monitorChecked = false;
  bool _cloudAuthChecked = false;
  bool _inboxChecked = false;


  static const _monitorSubmittedKey = 'monitor_data_submitted';

  /// Customer Portal からタブ復帰時にサブスク状態を再検証する.
  Future<void> _verifySubscriptionOnResume() async {
    if (!kIsWeb || !portalOpenPending) return;
    portalOpenPending = false;

    final prefs = ref.read(sharedPreferencesProvider);
    final stripeService = StripeService(prefs);
    final userKey = RemoteConfigService(prefs).savedUserKey;
    if (userKey == null || userKey.isEmpty) return;

    final active = await stripeService.verifySubscription(userKey: userKey);
    if (active == null) return; // 通信エラー時は変更しない

    setSubscriptionPremium(enabled: active);
    if (mounted) setState(() {}); // UIを再描画
  }

  /// ローカル実行（localhost）かどうかを判定する.
  static bool _isLocalhost() {
    if (!kIsWeb) return true; // デスクトップ版はローカル実行
    final host = Uri.base.host;
    return host == 'localhost' || host == '127.0.0.1';
  }

  /// 受信ボックスのチェック（リマインダー自動生成 + 開発者通知読み込み）.
  void _checkInbox() {
    if (_inboxChecked) return;
    _inboxChecked = true;

    // 初回レンダリング完了後に実行（UIをブロックしない）
    if (!_disableInboxCheck) {
      Future.delayed(const Duration(seconds: 2), _loadInboxAsync);
    }
  }

  Future<void> _loadInboxAsync() async {
    try {
      if (!mounted) return;
      final notifService = ref.read(notificationServiceProvider);

      // 1. 期限リマインダーのチェック
      final taskService = ref.read(taskServiceProvider);
      final goalService = ref.read(goalServiceProvider);
      final allTasks = await taskService.getAllTasks();
      final allGoals = await goalService.getAllGoals();

      final deadlines =
          <({String id, String title, DateTime deadline, bool isGoal})>[];
      for (final task in allTasks) {
        if (task.progress < 100) {
          deadlines.add((
            id: task.id,
            title: task.title,
            deadline: task.endDate,
            isGoal: false,
          ));
        }
      }
      for (final goal in allGoals) {
        final targetDate = goal.getTargetDate();
        if (targetDate != null) {
          deadlines.add((
            id: goal.id,
            title: goal.what,
            deadline: targetDate,
            isGoal: true,
          ));
        }
      }
      await notifService.checkAndCreateReminders(deadlines: deadlines);

      // 2. 開発者通知の読み込み（assets/announcements.json）
      try {
        final jsonStr = await rootBundle.loadString('assets/announcements.json');
        await notifService.syncSystemNotificationsFromJson(jsonStr);
      } on Object {
        // アセット読み込み失敗（テスト環境等）は無視
      }

      // Provider再読み込み
      if (mounted) {
        ref.invalidate(unreadCountProvider);
        ref.invalidate(allNotificationsProvider);
      }
    } on Object {
      // 受信ボックスチェック失敗はアプリ起動に影響させない
    }
  }

  /// クラウド同期の初期化（匿名認証ベース）.
  ///
  /// SyncManagerを初期化し、起動時の初回同期を実行する.
  /// ライフサイクル監視で離脱時にも未同期データを保存する.
  void _checkCloudAuth() {
    if (_cloudAuthChecked) return;
    _cloudAuthChecked = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !kIsWeb) return;

      // SyncManager初期化
      final syncManager = SyncManager();
      syncManager.init(
        ref.read(dataExportServiceProvider),
        prefs: ref.read(sharedPreferencesProvider),
      );

      // ライフサイクル監視: アプリ離脱時に未同期データを保存
      // AppLifecycleListenerは自動でBindingに登録される
      AppLifecycleListener(
        onHide: () => syncManager.syncOnExit(),
        onPause: () => syncManager.syncOnExit(),
        onShow: () => _verifySubscriptionOnResume(),
      );

      // 開発者判定: 認証メールが開発者のものなら全機能解放
      final syncService = FirestoreSyncService();
      await syncService.ensureSignedIn();
      setDeveloperMode(
        enabled: syncService.email == 'teppei09141998@gmail.com',
      );
      // プレミアム状態が変わった場合、UIを再描画してバナーを更新
      if (mounted && isPremium) setState(() {});

      // 起動時の初回同期
      await syncManager.syncNow();
    });
  }

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

    // 既にチュートリアル中の場合はリセットして再開するか確認
    if (tutorialState.isActive) {
      final restart = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('チュートリアル実行中'),
          content: const Text(
            'チュートリアルが実行中です。\n'
            '最初からやり直しますか？',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('最初から'),
            ),
          ],
        ),
      );
      if (restart != true || !mounted) return;

      // 既存のチュートリアルデータを削除してリセット
      final tutorialService = ref.read(tutorialServiceProvider);
      final taskId = tutorialService.tutorialTaskId;
      final goalId = tutorialService.tutorialGoalId;
      final dreamId = tutorialService.tutorialDreamId;
      if (taskId != null) {
        await ref.read(taskServiceProvider).deleteTask(taskId);
      }
      if (goalId != null) {
        await ref.read(goalListProvider.notifier).deleteGoal(goalId);
      }
      if (dreamId != null) {
        await ref.read(dreamListProvider.notifier).deleteDream(dreamId);
      }
      await tutorialService.finish();
      ref.read(tutorialStateProvider.notifier).reset();
    }

    if (!mounted) return;
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

    // ローカル実行時はプレミアム（開発者モード）として動作
    if (!_demoChecked && !_disableInboxCheck && _isLocalhost()) {
      setDeveloperMode(enabled: true);
    }

    // デモデータ投入（ローカル実行時のみ・初回のみ）
    if (!_demoChecked && !_disableInboxCheck && _isLocalhost()) {
      _demoChecked = true;
      final prefs = ref.read(sharedPreferencesProvider);
      if (!isDemoDataSeeded(prefs)) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          await seedDemoData(
            prefs: prefs,
            dreamService: ref.read(dreamServiceProvider),
            goalService: ref.read(goalServiceProvider),
            taskService: ref.read(taskServiceProvider),
            bookService: ref.read(bookServiceProvider),
            studyLogService: ref.read(studyLogServiceProvider),
          );
          if (!mounted) return;
          ref.invalidate(dreamListProvider);
          ref.invalidate(goalListProvider);
          ref.invalidate(bookListProvider);
          ref.invalidate(allLogsProvider);
        });
      }
    }

    // リリースノートの確認
    // モニターデータ提出の確認
    _checkMonitorSubmission();

    // 受信ボックス: リマインダー・お知らせチェック
    _checkInbox();

    // クラウド認証の確認
    _checkCloudAuth();

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
                tooltip: AppLabels.tooltipMenu,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.menu_book_outlined),
                tooltip: AppLabels.tooltipHowToUse,
                onPressed: () => showAppGuideDialog(
                  context,
                  isPremium: isPremium,
                  onStartTutorial: _startTutorial,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.help_outline),
                tooltip: AppLabels.tooltipHelp,
                onPressed: () => showHelpDialog(context),
              ),
              const NotificationButton(),
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

