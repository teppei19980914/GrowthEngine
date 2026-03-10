import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yume_log/app.dart';
import 'package:yume_log/database/app_database.dart' hide Book, Dream, Goal, Task;
import 'package:yume_log/models/goal.dart';
import 'package:yume_log/providers/dashboard_providers.dart';
import 'package:yume_log/providers/database_provider.dart';
import 'package:yume_log/providers/goal_providers.dart';
import 'package:yume_log/providers/theme_provider.dart';
import 'package:yume_log/services/study_stats_types.dart';
import 'package:yume_log/models/task.dart';
import 'package:yume_log/pages/stats_page.dart';
import 'package:yume_log/providers/gantt_providers.dart';
import 'package:yume_log/models/book.dart';
import 'package:yume_log/models/constellation.dart';
import 'package:yume_log/models/dream.dart';
import 'package:yume_log/providers/book_providers.dart';
import 'package:yume_log/providers/constellation_providers.dart';
import 'package:yume_log/providers/dream_providers.dart';
import 'package:yume_log/widgets/notification/notification_button.dart';
import 'package:yume_log/widgets/stats/goal_stats_section.dart';

/// テスト用のProviderScopeオーバーライドを作成する.
List<Override> _testOverrides(
  SharedPreferences prefs,
  AppDatabase db,
) {
  return [
    sharedPreferencesProvider.overrideWithValue(prefs),
    databaseProvider.overrideWithValue(db),
    // GoalPageの非同期DBアクセスを回避（fake async環境では解決しない）
    goalListProvider.overrideWith(() => _ImmediateGoalListNotifier()),
    // ダッシュボードの非同期DBアクセスを回避
    dashboardLayoutProvider
        .overrideWith(() => _ImmediateDashboardLayoutNotifier()),
    todayStudyProvider.overrideWith(
      (ref) async => const TodayStudyData(
        totalMinutes: 0,
        sessionCount: 0,
        studied: false,
      ),
    ),
    streakProvider.overrideWith(
      (ref) async => const StreakData(
        currentStreak: 0,
        longestStreak: 0,
        studiedToday: false,
      ),
    ),
    personalRecordProvider.overrideWith(
      (ref) async => const PersonalRecordData(
        bestDayMinutes: 0,
        bestWeekMinutes: 0,
        longestStreak: 0,
        totalHours: 0,
        totalStudyDays: 0,
      ),
    ),
    consistencyProvider.overrideWith(
      (ref) async => const ConsistencyData(
        thisWeekDays: 0,
        thisWeekTotal: 1,
        thisWeekMinutes: 0,
        thisMonthDays: 0,
        thisMonthTotal: 1,
        thisMonthMinutes: 0,
        overallRate: 0,
        overallStudyDays: 0,
        overallTotalDays: 1,
      ),
    ),
    bookshelfProvider.overrideWith(
      (ref) async => const BookshelfData(
        totalCount: 0,
        completedCount: 0,
        readingCount: 0,
        recentCompleted: [],
      ),
    ),
    dreamListProvider.overrideWith(() => _ImmediateDreamListNotifier()),
    bookListProvider.overrideWith(() => _ImmediateBookListNotifier()),
    constellationProgressProvider.overrideWith(
      (ref) async => const ConstellationOverallProgress(
        constellations: [],
        totalMinutes: 0,
        totalLitStars: 0,
        totalStars: 0,
      ),
    ),
    dreamCountProvider.overrideWith((ref) async => 0),
    goalCountProvider.overrideWith((ref) async => 0),
    // 通知ボタンの非同期DBアクセスを回避
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
    activityChartProvider.overrideWith(
      (ref) async => ActivityChartData(
        buckets: const [],
        maxMinutes: 0,
        periodType: ActivityPeriodType.monthly,
      ),
    ),
    ganttTasksProvider.overrideWith((ref) async => <Task>[]),
    ganttGoalListProvider.overrideWith((ref) async => <Goal>[]),
    milestoneDataProvider.overrideWith(
      (ref) async => const MilestoneData(
        totalHours: 0,
        studyDays: 0,
        currentStreak: 0,
        achieved: [],
      ),
    ),
    goalStatsProvider
        .overrideWith((ref) async => <GoalStatsDisplayData>[]),
    bookStatsProvider
        .overrideWith((ref) async => <GoalStatsDisplayData>[]),
  ];
}

/// テスト用: 即座に空リストを返すDreamListNotifier.
class _ImmediateDreamListNotifier extends DreamListNotifier {
  @override
  Future<List<Dream>> build() async => [];
}

/// テスト用: 即座に空リストを返すGoalListNotifier.
class _ImmediateGoalListNotifier extends GoalListNotifier {
  @override
  Future<List<Goal>> build() async => [];
}

/// テスト用: 即座に空リストを返すBookListNotifier.
class _ImmediateBookListNotifier extends BookListNotifier {
  @override
  Future<List<Book>> build() async => [];
}

/// テスト用: 即座にデフォルトレイアウトを返すDashboardLayoutNotifier.
class _ImmediateDashboardLayoutNotifier extends DashboardLayoutNotifier {
  @override
  Future<List<DashboardWidgetConfig>> build() async => const [
        DashboardWidgetConfig(widgetType: 'today_banner', columnSpan: 2),
        DashboardWidgetConfig(widgetType: 'total_time_card', columnSpan: 1),
        DashboardWidgetConfig(widgetType: 'study_days_card', columnSpan: 1),
      ];
}

void main() {
  late AppDatabase db;

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('App smoke test - ダッシュボードが表示される',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: _testOverrides(prefs, db),
        child: const YumeLogApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ダッシュボード'), findsWidgets);
  });

  testWidgets('ドロワーから夢ページに遷移', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: _testOverrides(prefs, db),
        child: const YumeLogApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    await tester.tap(find.text('夢').last);
    await tester.pumpAndSettle();

    expect(find.text('夢'), findsWidgets);
  });

  testWidgets('ドロワーからページ遷移', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: _testOverrides(prefs, db),
        child: const YumeLogApp(),
      ),
    );
    await tester.pumpAndSettle();

    // ハンバーガーメニューを開く
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    // 「目標」をタップ
    await tester.tap(find.text('目標').last);
    await tester.pumpAndSettle();

    // AppBarタイトルが「目標」に変わることを確認
    expect(find.text('目標'), findsWidgets);
  });

  testWidgets('テーマ切替', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: _testOverrides(prefs, db),
        child: const YumeLogApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 設定ページに遷移
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('設定'));
    await tester.pumpAndSettle();

    // ダークモードスイッチを確認
    expect(find.text('ダークモード'), findsOneWidget);

    // ダークモードのトグルをタップ（最初のSwitchListTile）
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    // ライトテーマに切り替わったことを確認
    expect(find.text('Catppuccin Latte'), findsOneWidget);
  });
}
