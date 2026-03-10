/// アプリケーションのルートウィジェット.
///
/// MaterialApp + go_router + テーマ設定を統合する.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'pages/book_page.dart';
import 'pages/constellation_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/dream_page.dart';
import 'pages/gantt_page.dart';
import 'pages/goal_page.dart';
import 'pages/settings_page.dart';
import 'pages/stats_page.dart';
import 'providers/service_providers.dart';
import 'providers/theme_provider.dart';
import 'services/remote_config_service.dart';
import 'theme/app_theme.dart';
import 'widgets/navigation/app_drawer.dart';
import 'widgets/milestone/milestone_button.dart';
import 'widgets/notification/notification_button.dart';
import 'widgets/tutorial/tutorial_banner.dart';

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

/// go_routerの設定.
final _router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return _AppShell(
          title: _pageTitles[state.uri.path] ?? '',
          child: child,
        );
      },
      routes: [
        GoRoute(path: '/', builder: (_, _) => const DashboardPage()),
        GoRoute(path: '/dreams', builder: (_, _) => const DreamPage()),
        GoRoute(path: '/goals', builder: (_, _) => const GoalPage()),
        GoRoute(path: '/gantt', builder: (_, _) => const GanttPage()),
        GoRoute(path: '/books', builder: (_, _) => const BookPage()),
        GoRoute(
          path: '/constellations',
          builder: (_, _) => const ConstellationPage(),
        ),
        GoRoute(path: '/stats', builder: (_, _) => const StatsPage()),
        GoRoute(path: '/settings', builder: (_, _) => const SettingsPage()),
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

    return MaterialApp.router(
      title: 'ユメログ - 夢実現支援',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode:
          themeType == ThemeType.dark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: _router,
    );
  }
}

/// アプリケーションシェル（Scaffold + AppBar + Drawer）.
class _AppShell extends ConsumerStatefulWidget {
  const _AppShell({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  ConsumerState<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<_AppShell> {
  bool _resetChecked = false;

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
        });
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: 'メニュー',
          ),
        ),
        actions: const [
          MilestoneButton(),
          NotificationButton(),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          const TutorialBanner(),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}
