/// テスト用共通ヘルパー.
///
/// ProviderScope overridesとユーティリティ関数を提供する.
library;

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yume_log/database/app_database.dart' hide Book, Dream, Goal, Task;
import 'package:yume_log/models/dream.dart';
import 'package:yume_log/models/goal.dart';
import 'package:yume_log/models/constellation.dart';
import 'package:yume_log/providers/book_providers.dart';
import 'package:yume_log/providers/constellation_providers.dart';
import 'package:yume_log/providers/dashboard_providers.dart';
import 'package:yume_log/providers/database_provider.dart';
import 'package:yume_log/providers/dream_providers.dart';
import 'package:yume_log/providers/goal_providers.dart';
import 'package:yume_log/providers/theme_provider.dart';
import 'package:yume_log/services/study_stats_types.dart';
import 'package:yume_log/widgets/notification/notification_button.dart';
import 'package:yume_log/widgets/stats/goal_stats_section.dart';
import 'package:yume_log/models/book.dart';
import 'package:yume_log/models/task.dart';
import 'package:yume_log/pages/stats_page.dart';
import 'package:yume_log/providers/gantt_providers.dart';

/// テスト用のProviderScope overridesを作成する.
///
/// [customOverrides] で追加のoverridesを渡せる.
List<Override> createTestOverrides({
  required SharedPreferences prefs,
  required AppDatabase db,
  List<Override> customOverrides = const [],
}) {
  return [
    sharedPreferencesProvider.overrideWithValue(prefs),
    databaseProvider.overrideWithValue(db),
    dreamListProvider.overrideWith(() => ImmediateDreamListNotifier()),
    goalListProvider.overrideWith(() => ImmediateGoalListNotifier()),
    bookListProvider.overrideWith(() => ImmediateBookListNotifier()),
    dashboardLayoutProvider
        .overrideWith(() => ImmediateDashboardLayoutNotifier()),
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
    goalProgressProvider.overrideWith(
      (ref) async => <String, ({int total, int completed})>{},
    ),
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
    ...customOverrides,
  ];
}

/// テスト用: 即座に空リストを返すDreamListNotifier.
class ImmediateDreamListNotifier extends DreamListNotifier {
  @override
  Future<List<Dream>> build() async => [];
}

/// テスト用: サンプルDreamを返すDreamListNotifier.
class SampleDreamListNotifier extends DreamListNotifier {
  @override
  Future<List<Dream>> build() async => [
        Dream(id: 'dream-1', title: '医者になる'),
        Dream(id: 'dream-2', title: 'エンジニアになる'),
      ];
}

/// テスト用: 即座に空リストを返すGoalListNotifier.
class ImmediateGoalListNotifier extends GoalListNotifier {
  @override
  Future<List<Goal>> build() async => [];
}

/// テスト用: サンプルGoalを返すGoalListNotifier.
class SampleGoalListNotifier extends GoalListNotifier {
  @override
  Future<List<Goal>> build() async => [
        Goal(
          id: 'goal-1',
          dreamId: 'dream-1',
          why: 'スキルアップ',
          whenTarget: '2026-12-31',
          whenType: WhenType.date,
          what: 'Flutter活動',
          how: '毎日1時間',
          color: '#cba6f7',
        ),
        Goal(
          id: 'goal-2',
          dreamId: 'dream-1',
          why: '資格取得',
          whenTarget: '半年以内',
          whenType: WhenType.period,
          what: '基本情報技術者',
          how: '過去問を解く',
          color: '#f38ba8',
        ),
      ];
}

/// テスト用: 独立目標（夢に紐づかない）を返すGoalListNotifier.
class StandaloneGoalListNotifier extends GoalListNotifier {
  @override
  Future<List<Goal>> build() async => [
        Goal(
          id: 'goal-s1',
          dreamId: '',
          whenTarget: '3ヶ月以内',
          whenType: WhenType.period,
          what: '独立目標テスト',
          how: 'テスト方法',
        ),
      ];
}

/// テスト用: サンプルBookを返すBookListNotifier.
class SampleBookListNotifier extends BookListNotifier {
  @override
  Future<List<Book>> build() async => [
        Book(id: 'book-1', title: 'Flutter実践入門'),
        Book(
          id: 'book-2',
          title: 'Dart言語ガイド',
          status: BookStatus.reading,
        ),
      ];
}

/// テスト用: 即座に空リストを返すBookListNotifier.
class ImmediateBookListNotifier extends BookListNotifier {
  @override
  Future<List<Book>> build() async => [];
}

/// テスト用: デフォルトレイアウトを返すDashboardLayoutNotifier.
class ImmediateDashboardLayoutNotifier extends DashboardLayoutNotifier {
  @override
  Future<List<DashboardWidgetConfig>> build() async => const [
        DashboardWidgetConfig(widgetType: 'today_banner', columnSpan: 2),
        DashboardWidgetConfig(widgetType: 'total_time_card', columnSpan: 1),
        DashboardWidgetConfig(widgetType: 'study_days_card', columnSpan: 1),
        DashboardWidgetConfig(widgetType: 'streak_card', columnSpan: 1),
        DashboardWidgetConfig(widgetType: 'goal_count_card', columnSpan: 1),
      ];
}

/// テスト用のProviderScopeでウィジェットをラップする.
Widget wrapWithProviders(
  Widget child, {
  required SharedPreferences prefs,
  required AppDatabase db,
  List<Override> customOverrides = const [],
}) {
  return ProviderScope(
    overrides: createTestOverrides(
      prefs: prefs,
      db: db,
      customOverrides: customOverrides,
    ),
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

/// ドロワー経由でページに遷移するテストヘルパー.
///
/// ドロワーを開き、スクロールして対象のラベルをタップする.
/// ListView内の項目を優先的に検索し、見つからない場合はDrawer全体から検索する.
/// これにより固定領域のウィジェットとの重なりを回避できる.
Future<void> navigateViaDrawerInTest(
  WidgetTester tester,
  String label,
) async {
  await tester.tap(find.byIcon(Icons.menu));
  await tester.pumpAndSettle();

  // まずListView内から探す（スクロール対応）
  final drawerListView = find.descendant(
    of: find.byType(Drawer),
    matching: find.byType(ListView),
  );
  final listViewTarget = find.descendant(
    of: drawerListView,
    matching: find.text(label),
  );

  if (listViewTarget.evaluate().isNotEmpty) {
    // ListView内にある場合はスクロールしてタップ
    await tester.scrollUntilVisible(
      listViewTarget,
      100,
      scrollable: find.descendant(
        of: find.byType(Drawer),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(listViewTarget);
  } else {
    // ListView外（設定など固定領域）の場合はDrawer内から直接タップ
    final drawerTarget = find.descendant(
      of: find.byType(Drawer),
      matching: find.text(label),
    );
    await tester.tap(drawerTarget);
  }
  await tester.pumpAndSettle();
}

/// テスト用のDB/SharedPreferencesセットアップ.
class TestSetup {
  late AppDatabase db;

  /// テスト前のセットアップ.
  void setUp() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    SharedPreferences.setMockInitialValues({'onboarding_completed': true});
    db = AppDatabase(NativeDatabase.memory());
  }

  /// テスト後のクリーンアップ.
  Future<void> tearDown() async {
    await db.close();
  }
}
