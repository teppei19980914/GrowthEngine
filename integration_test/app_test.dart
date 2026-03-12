/// UIインテグレーションテスト.
///
/// アプリ全体のナビゲーションフローとウィジェット表示を検証する.
library;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yume_log/app.dart';
import 'package:yume_log/database/app_database.dart'
    hide Book, Dream, Goal, Task;
import 'package:yume_log/models/book.dart';
import 'package:yume_log/models/dream.dart';
import 'package:yume_log/models/goal.dart';
import 'package:yume_log/models/task.dart';
import 'package:yume_log/pages/stats_page.dart';
import 'package:yume_log/providers/book_providers.dart';
import 'package:yume_log/providers/constellation_providers.dart';
import 'package:yume_log/providers/dashboard_providers.dart';
import 'package:yume_log/providers/database_provider.dart';
import 'package:yume_log/providers/dream_providers.dart';
import 'package:yume_log/providers/gantt_providers.dart';
import 'package:yume_log/providers/goal_providers.dart';
import 'package:yume_log/providers/service_providers.dart';
import 'package:yume_log/services/remote_config_service.dart';
import 'package:yume_log/services/study_stats_types.dart';
import 'package:yume_log/widgets/stats/goal_stats_section.dart';

class _ImmediateDreamListNotifier extends DreamListNotifier {
  @override
  Future<List<Dream>> build() async => [];
}

class _ImmediateGoalListNotifier extends GoalListNotifier {
  @override
  Future<List<Goal>> build() async => [];
}

class _ImmediateBookListNotifier extends BookListNotifier {
  @override
  Future<List<Book>> build() async => [];
}

class _ImmediateDashboardLayoutNotifier extends DashboardLayoutNotifier {
  @override
  Future<List<DashboardWidgetConfig>> build() async => const [
        DashboardWidgetConfig(widgetType: 'today_banner', columnSpan: 2),
        DashboardWidgetConfig(widgetType: 'total_time_card', columnSpan: 1),
        DashboardWidgetConfig(widgetType: 'study_days_card', columnSpan: 1),
        DashboardWidgetConfig(widgetType: 'streak_card', columnSpan: 1),
        DashboardWidgetConfig(widgetType: 'goal_count_card', columnSpan: 1),
      ];
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<Widget> _buildApp() async {
    final prefs = await SharedPreferences.getInstance();
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        databaseProvider.overrideWithValue(db),
        remoteConfigProvider.overrideWithValue(UserConfig.defaultConfig),
        dreamListProvider.overrideWith(() => _ImmediateDreamListNotifier()),
        goalListProvider.overrideWith(() => _ImmediateGoalListNotifier()),
        bookListProvider.overrideWith(() => _ImmediateBookListNotifier()),
        dashboardLayoutProvider
            .overrideWith(() => _ImmediateDashboardLayoutNotifier()),
        todayStudyProvider.overrideWith(
          (ref) async => const TodayStudyData(
            totalMinutes: 60,
            sessionCount: 2,
            studied: true,
          ),
        ),
        streakProvider.overrideWith(
          (ref) async => const StreakData(
            currentStreak: 3,
            longestStreak: 7,
            studiedToday: true,
          ),
        ),
        personalRecordProvider.overrideWith(
          (ref) async => const PersonalRecordData(
            bestDayMinutes: 120,
            bestWeekMinutes: 300,
            longestStreak: 7,
            totalHours: 10.5,
            totalStudyDays: 14,
          ),
        ),
        consistencyProvider.overrideWith(
          (ref) async => const ConsistencyData(
            thisWeekDays: 3,
            thisWeekTotal: 5,
            thisWeekMinutes: 180,
            thisMonthDays: 10,
            thisMonthTotal: 15,
            thisMonthMinutes: 600,
            overallRate: 0.7,
            overallStudyDays: 14,
            overallTotalDays: 20,
          ),
        ),
        bookshelfProvider.overrideWith(
          (ref) async => const BookshelfData(
            totalCount: 5,
            completedCount: 2,
            readingCount: 1,
            recentCompleted: [],
          ),
        ),
        dreamCountProvider.overrideWith((ref) async => 1),
        goalCountProvider.overrideWith((ref) async => 3),
        unreadCountProvider.overrideWith((ref) async => 0),
        allNotificationsProvider.overrideWith((ref) async => []),
        dailyActivityProvider.overrideWith(
          (ref) async => DailyActivityData(
            days: const [],
            maxMinutes: 0,
            periodStart: DateTime(2026),
            periodEnd: DateTime(2026),
          ),
        ),
        allLogsProvider.overrideWith((ref) async => []),
        ganttTasksProvider.overrideWith((ref) async => <Task>[]),
        ganttGoalListProvider.overrideWith((ref) async => <Goal>[]),
        goalStatsProvider
            .overrideWith((ref) async => <GoalStatsDisplayData>[]),
        bookStatsProvider
            .overrideWith((ref) async => <GoalStatsDisplayData>[]),
        milestoneDataProvider.overrideWith(
          (ref) async => const MilestoneData(
            totalHours: 0,
            studyDays: 0,
            currentStreak: 0,
            achieved: [],
          ),
        ),
        constellationProgressProvider.overrideWith(
          (ref) async => const ConstellationOverallProgress(
            constellations: [],
            totalMinutes: 0,
            totalLitStars: 0,
            totalStars: 0,
          ),
        ),
        activityChartProvider.overrideWith(
          (ref) async => ActivityChartData(
            buckets: const [],
            maxMinutes: 0,
            periodType: ActivityPeriodType.monthly,
          ),
        ),
      ],
      child: const YumeLogApp(),
    );
  }

  // GoRouterはモジュールレベルのシングルトンのため、全ナビゲーションを1テストで実行する.
  testWidgets('アプリ全体のUIナビゲーションフロー', (tester) async {
    await tester.pumpWidget(await _buildApp());
    await tester.pumpAndSettle();

    // ─── ダッシュボード ───────────────────────────────
    expect(find.text('ダッシュボード'), findsOneWidget);

    // ボトムナビゲーション4タブが表示される
    expect(find.byIcon(Icons.home), findsOneWidget); // active home
    expect(find.byIcon(Icons.auto_awesome_outlined), findsOneWidget);
    expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
    expect(find.byIcon(Icons.bar_chart_outlined), findsOneWidget);

    // 今日の活動バナーが表示される
    expect(find.text('今日は活動済み!'), findsOneWidget);

    // 編集モード切替
    await tester.tap(find.byIcon(Icons.tune_outlined));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    expect(find.text('リセット'), findsOneWidget);

    // 編集モード終了
    await tester.tap(find.byIcon(Icons.check_circle_outline));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.tune_outlined), findsOneWidget);

    // ─── 夢ページ ───────────────────────────────────
    await tester.tap(find.byIcon(Icons.auto_awesome_outlined));
    await tester.pumpAndSettle();
    expect(find.text('夢がまだありません'), findsOneWidget);
    // 夢を追加ボタンが表示される
    expect(find.text('夢を追加'), findsOneWidget);

    // ─── 目標ページ ──────────────────────────────────
    await tester.tap(find.byIcon(Icons.flag_outlined));
    await tester.pumpAndSettle();
    expect(find.text('目標がまだありません'), findsOneWidget);
    // 目標を追加ボタンが表示される
    expect(find.text('目標を追加'), findsOneWidget);

    // ─── 統計ページ ──────────────────────────────────
    await tester.tap(find.byIcon(Icons.bar_chart_outlined));
    await tester.pumpAndSettle();
    expect(find.text('統計'), findsOneWidget);

    // ─── ホームへ戻る ────────────────────────────────
    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pumpAndSettle();
    expect(find.text('ダッシュボード'), findsOneWidget);
  });

  testWidgets('ドロワーメニューが開く', (tester) async {
    await tester.pumpWidget(await _buildApp());
    await tester.pumpAndSettle();

    // ハンバーガーアイコンをタップ
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    // ドロワーが開く（Drawer内のナビゲーション項目が表示される）
    expect(find.text('ガントチャート'), findsOneWidget);
    expect(find.text('書籍'), findsOneWidget);
    expect(find.text('設定'), findsOneWidget);
  });
}
