/// UIインテグレーションテスト.
///
/// アプリ全体のナビゲーションフローとウィジェット表示を検証する.
library;

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yume_hashi/app.dart';
import 'package:yume_hashi/database/app_database.dart'
    hide Book, Dream, Goal, Task;
import 'package:yume_hashi/models/book.dart';
import 'package:yume_hashi/models/constellation.dart'
    show ConstellationOverallProgress;
import 'package:yume_hashi/models/dream.dart';
import 'package:yume_hashi/models/goal.dart' show Goal, WhenType;
import 'package:yume_hashi/models/task.dart';
import 'package:yume_hashi/pages/stats_page.dart';
import 'package:yume_hashi/providers/book_providers.dart';
import 'package:yume_hashi/providers/constellation_providers.dart';
import 'package:yume_hashi/providers/dashboard_providers.dart';
import 'package:yume_hashi/providers/database_provider.dart';
import 'package:yume_hashi/providers/dream_providers.dart';
import 'package:yume_hashi/providers/gantt_providers.dart';
import 'package:yume_hashi/providers/goal_providers.dart';
import 'package:yume_hashi/providers/service_providers.dart';
import 'package:yume_hashi/providers/theme_provider.dart'
    show sharedPreferencesProvider;
import 'package:yume_hashi/services/remote_config_service.dart';
import 'package:yume_hashi/services/study_stats_types.dart';
import 'package:yume_hashi/services/feedback_service.dart'
    show FeedbackCategory, feedbackUnlockableLevel;
import 'package:yume_hashi/services/inquiry_service.dart'
    show InquiryCategory;
import 'package:yume_hashi/services/trial_limit_service.dart'
    show setTrialModeForTest;
import 'package:yume_hashi/widgets/notification/notification_button.dart'
    show allNotificationsProvider, unreadCountProvider;
import 'package:yume_hashi/widgets/stats/goal_stats_section.dart';

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

/// テスト用に夢1件を返すNotifier.
const _testDreamId = 'test-dream-id-01';

class _SingleDreamListNotifier extends DreamListNotifier {
  @override
  Future<List<Dream>> build() async => [
        Dream(
          id: _testDreamId,
          title: 'テスト夢',
          description: 'テスト説明',
          why: 'テスト理由',
        ),
      ];
}

/// テスト用に目標1件を返すNotifier.
class _SingleGoalListNotifier extends GoalListNotifier {
  @override
  Future<List<Goal>> build() async => [
        Goal(
          id: 'test-goal-id-01',
          dreamId: _testDreamId,
          what: 'テスト目標',
          how: 'テスト方法',
          whenType: WhenType.date,
          whenTarget: '2026-12-31',
        ),
      ];
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
    SharedPreferences.setMockInitialValues({
      'onboarding_completed': true,
    });
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<Widget> buildApp() async {
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
      child: const YumeHashiApp(),
    );
  }

  /// 夢1件・目標1件を持つアプリを構築する（カード操作テスト用）.
  Future<Widget> buildAppWithData() async {
    final prefs = await SharedPreferences.getInstance();
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        databaseProvider.overrideWithValue(db),
        remoteConfigProvider.overrideWithValue(UserConfig.defaultConfig),
        dreamListProvider.overrideWith(() => _SingleDreamListNotifier()),
        goalListProvider.overrideWith(() => _SingleGoalListNotifier()),
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
            totalCount: 0,
            completedCount: 0,
            readingCount: 0,
            recentCompleted: [],
          ),
        ),
        dreamCountProvider.overrideWith((ref) async => 1),
        goalCountProvider.overrideWith((ref) async => 1),
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
      child: const YumeHashiApp(),
    );
  }

  /// 夢/目標/タスクプロバイダーをモックせずにアプリを構築する（CRUD操作テスト用）.
  Future<Widget> buildRealApp() async {
    final prefs = await SharedPreferences.getInstance();
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        databaseProvider.overrideWithValue(db),
        remoteConfigProvider.overrideWithValue(UserConfig.defaultConfig),
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
            thisWeekTotal: 7,
            thisWeekMinutes: 0,
            thisMonthDays: 0,
            thisMonthTotal: 30,
            thisMonthMinutes: 0,
            overallRate: 0,
            overallStudyDays: 0,
            overallTotalDays: 0,
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
        dreamCountProvider.overrideWith((ref) async => 0),
        goalCountProvider.overrideWith((ref) async => 0),
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
      child: const YumeHashiApp(),
    );
  }

  /// ドロワー経由でページに移動するヘルパー.
  ///
  /// GoRouterシングルトンの状態に依存せず、どのページからでも遷移できる.
  /// ボトムナビゲーションが無いページ（スケジュール等）からも安全に遷移可能.
  Future<void> navigateViaDrawer(WidgetTester tester, String label) async {
    // ダイアログが残っている場合は閉じる
    while (find.byType(AlertDialog).evaluate().isNotEmpty) {
      final closeButton = find.text('閉じる');
      if (closeButton.evaluate().isNotEmpty) {
        await tester.tap(closeButton);
        await tester.pumpAndSettle();
      } else {
        // Escキーまたは戻るボタンで閉じる
        await tester.tap(find.byType(AlertDialog), warnIfMissed: false);
        await tester.pumpAndSettle();
        break;
      }
    }
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
      of: find.byType(Drawer),
      matching: find.text(label),
    ));
    await tester.pumpAndSettle();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ヘルパー: ボトムナビゲーションタブをインデックスでタップする.
  // AppDrawerにも同じアイコンが存在するため、アイコン検索ではなく
  // NavigationDestination のインデックスでタップする.
  // 0=ホーム, 1=夢, 2=目標, 3=スケジュール
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> tapBottomNav(WidgetTester tester, int index) async {
    // GoRouterシングルトンの状態でボトムナビがない場合、ドロワー経由でホームに戻る
    if (find.byType(NavigationDestination).evaluate().isEmpty) {
      await navigateViaDrawer(tester, 'ダッシュボード');
    }
    await tester.tap(find.byType(NavigationDestination).at(index));
    await tester.pumpAndSettle();
  }

  /// NavigationBar 内のアイコンを検索するヘルパー（AppDrawerの重複を除外）.
  Finder findNavBarIcon(IconData icon) {
    return find.descendant(
      of: find.byType(NavigationBar),
      matching: find.byIcon(icon),
    );
  }

  // GoRouterはモジュールレベルのシングルトンのため、全ナビゲーションを1テストで実行する.
  testWidgets('アプリ全体のUIナビゲーションフロー', (tester) async {
    await tester.pumpWidget(await buildApp());
    await tester.pumpAndSettle();

    // ─── ダッシュボード ───────────────────────────────
    expect(find.text('ダッシュボード'), findsOneWidget);

    // ボトムナビゲーション4タブが表示される（AppDrawerにも同アイコンがあるため
    // NavigationBar 内に限定して検索）
    expect(findNavBarIcon(Icons.home), findsOneWidget); // active home
    expect(findNavBarIcon(Icons.auto_awesome_outlined), findsOneWidget);
    expect(findNavBarIcon(Icons.flag_outlined), findsOneWidget);
    expect(findNavBarIcon(Icons.view_timeline_outlined), findsOneWidget);

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
    await tapBottomNav(tester, 1);
    expect(find.text('やりたいことを見つけよう'), findsOneWidget);
    // 夢を追加ボタンが表示される
    expect(find.text('夢を追加'), findsOneWidget);

    // ─── 目標ページ ──────────────────────────────────
    await tapBottomNav(tester, 2);
    expect(find.text('最初の目標を設定しよう'), findsOneWidget);
    // 目標を追加ボタンが表示される
    expect(find.text('目標を追加'), findsOneWidget);

    // ─── スケジュールページ ──────────────────────────
    await tapBottomNav(tester, 3);
    // AppBarタイトル + ボトムナビラベルの2件が表示される
    expect(find.text('スケジュール'), findsWidgets);

    // ─── ホームへ戻る ────────────────────────────────
    await tapBottomNav(tester, 0);
    expect(find.text('ダッシュボード'), findsOneWidget);
  });

  testWidgets('ドロワーメニューが開く', (tester) async {
    await tester.pumpWidget(await buildApp());
    await tester.pumpAndSettle();

    // ハンバーガーアイコンをタップ
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    // ドロワーが開く（Drawer内のナビゲーション項目が表示される）
    // 「スケジュール」はドロワー + ボトムナビの2件
    expect(find.text('スケジュール'), findsWidgets);
    expect(find.text('書籍'), findsOneWidget);
    expect(find.text('設定'), findsOneWidget);
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 各種ボタン操作テスト（体験版で操作可能な範囲）
  // ─────────────────────────────────────────────────────────────────────────

  testWidgets('実績ボタンをタップすると実績ポップアップが開く', (tester) async {
    await tester.pumpWidget(await buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.emoji_events_outlined));
    await tester.pumpAndSettle();

    expect(find.text('実績'), findsOneWidget);
  });

  testWidgets('受信ボックスボタンをタップすると受信ボックスが開く', (tester) async {
    await tester.pumpWidget(await buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.inbox_outlined));
    await tester.pumpAndSettle();

    expect(find.text('受信ボックス'), findsOneWidget);
    expect(find.text('受信ボックスは空です'), findsOneWidget);
  });

  testWidgets('夢カードの編集メニューをタップすると編集ダイアログが開く', (tester) async {
    await tester.pumpWidget(await buildAppWithData());
    await tester.pumpAndSettle();

    // 夢ページへ移動
    await tapBottomNav(tester, 1);

    // 夢カードが表示される
    expect(find.text('テスト夢'), findsOneWidget);

    // PopupMenuを開く
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    // 「編集」を選択
    await tester.tap(find.text('編集'));
    await tester.pumpAndSettle();

    // 夢編集ダイアログが開く
    expect(find.text('夢を編集'), findsOneWidget);
    expect(find.text('テスト夢'), findsWidgets); // タイトルフィールドに値が入っている
  });

  testWidgets('夢カードの削除メニューをタップすると削除確認ダイアログが開く', (tester) async {
    await tester.pumpWidget(await buildAppWithData());
    await tester.pumpAndSettle();

    // 夢ページへ移動
    await tapBottomNav(tester, 1);

    // PopupMenuを開く
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    // 「削除」を選択
    await tester.tap(find.text('削除'));
    await tester.pumpAndSettle();

    // 削除確認ダイアログが開く
    expect(find.text('夢を削除'), findsOneWidget);
    expect(find.textContaining('削除しますか'), findsOneWidget);
    expect(find.text('キャンセル'), findsOneWidget);

    // キャンセルで閉じる
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(find.text('夢を削除'), findsNothing);
  });

  testWidgets('目標カードの編集メニューをタップすると編集ダイアログが開く', (tester) async {
    await tester.pumpWidget(await buildAppWithData());
    await tester.pumpAndSettle();

    // 目標ページへ移動
    await tapBottomNav(tester, 2);

    // 目標カードが表示される
    expect(find.text('テスト目標'), findsOneWidget);

    // PopupMenuを開く
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    // 「編集」を選択
    await tester.tap(find.text('編集'));
    await tester.pumpAndSettle();

    // 目標編集ダイアログが開く
    expect(find.text('目標を編集'), findsOneWidget);
    expect(find.text('テスト目標'), findsWidgets); // Whatフィールドに値が入っている
  });

  testWidgets('目標カードの削除メニューをタップすると削除確認ダイアログが開く', (tester) async {
    await tester.pumpWidget(await buildAppWithData());
    await tester.pumpAndSettle();

    // 目標ページへ移動
    await tapBottomNav(tester, 2);

    // PopupMenuを開く
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    // 「削除」を選択
    await tester.tap(find.text('削除'));
    await tester.pumpAndSettle();

    // 削除確認ダイアログが開く
    expect(find.text('目標を削除'), findsOneWidget);
    expect(find.textContaining('削除しますか'), findsOneWidget);

    // キャンセルで閉じる
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(find.text('目標を削除'), findsNothing);
  });

  testWidgets('統計ページのアクティビティ期間切替ボタンが機能する', (tester) async {
    await tester.pumpWidget(await buildApp());
    await tester.pumpAndSettle();

    // 統計ページへ移動（ドロワー経由）
    await navigateViaDrawer(tester, '統計');

    // アクティビティセクションまでスクロール
    await tester.scrollUntilVisible(
      find.byType(SegmentedButton<ActivityPeriodType>),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    // 日次に切替
    await tester.tap(find.text('日'));
    await tester.pumpAndSettle();

    // 週次に切替
    await tester.tap(find.text('週'));
    await tester.pumpAndSettle();

    // 年次に切替
    await tester.tap(find.text('年'));
    await tester.pumpAndSettle();

    // 月次に戻す
    await tester.tap(find.text('月'));
    await tester.pumpAndSettle();

    // セグメントボタン自体が存在し続けることを確認
    expect(find.byType(SegmentedButton<ActivityPeriodType>), findsOneWidget);
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 体験版制限フロー: ?key=dev-reset 相当のシナリオ
  // ─────────────────────────────────────────────────────────────────────────

  /// フィードバックダイアログを操作するヘルパー.
  ///
  /// カテゴリ選択 → テキスト入力 → 送信 の一連操作を行う.
  Future<void> submitFeedback(WidgetTester tester, String feedbackText) async {
    // カテゴリを選択
    await tester.tap(find.byType(DropdownButtonFormField<FeedbackCategory>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('改善要望').last);
    await tester.pumpAndSettle();

    // フィードバックテキストを入力（TextField はフィードバックダイアログ固有）
    await tester.enterText(
      find.byWidgetPredicate(
        (w) =>
            w is TextField &&
            (w.decoration?.hintText?.contains('アプリの改善点') ?? false),
      ),
      feedbackText,
    );
    await tester.pumpAndSettle();

    // 送信
    await tester.tap(find.text('送信する'));
    await tester.pumpAndSettle();
  }

  /// 目標追加ダイアログを操作するヘルパー（夢が登録済みであること）.
  ///
  /// 期間指定モードでWhen/How/Whatを入力して追加する.
  Future<void> addGoal(WidgetTester tester, String what) async {
    await tester.tap(find.text('目標を追加'));
    await tester.pumpAndSettle();

    // 期間指定に切り替え（日付ピッカー不要）
    await tester.tap(find.text('期間指定'));
    await tester.pumpAndSettle();

    // What フィールド（TextFormField内部のTextFieldを検索）
    await tester.enterText(
      find.byWidgetPredicate(
        (w) =>
            w is TextField &&
            (w.decoration?.hintText?.contains('TOEIC') ?? false),
      ),
      what,
    );

    // When フィールド（期間指定）
    await tester.enterText(
      find.byWidgetPredicate(
        (w) =>
            w is TextField &&
            (w.decoration?.hintText?.contains('3ヶ月以内') ?? false),
      ),
      '3ヶ月以内',
    );

    // How フィールド
    await tester.enterText(
      find.byWidgetPredicate(
        (w) =>
            w is TextField &&
            (w.decoration?.hintText?.contains('公式問題集') ?? false),
      ),
      'テスト方法',
    );

    await tester.tap(find.text('追加'));
    await tester.pumpAndSettle();
  }

  /// タスク追加ダイアログを操作するヘルパー（「タスクを追加」ボタンが表示済みであること）.
  Future<void> addTask(WidgetTester tester, String title) async {
    await tester.tap(find.text('タスクを追加'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byWidgetPredicate(
        (w) =>
            w is TextField &&
            (w.decoration?.hintText?.contains('第1章を読む') ?? false),
      ),
      title,
    );

    await tester.tap(find.text('追加'));
    await tester.pumpAndSettle();
  }

  /// 夢追加ダイアログを操作するヘルパー.
  Future<void> addDream(WidgetTester tester, String title) async {
    await tester.tap(find.text('夢を追加'));
    await tester.pumpAndSettle();

    // タイトル入力（最初のTextFormField）
    await tester.enterText(find.byType(TextFormField).first, title);
    await tester.pumpAndSettle();

    // 追加ボタン
    await tester.tap(find.text('追加'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    '体験版: 夢を制限いっぱいまで登録しフィードバックで解除を2回実施し最終制限ポップアップを確認',
    (tester) async {
      // テスト終了時に必ずリセット
      addTearDown(() => setTrialModeForTest(enabled: false));
      setTrialModeForTest(enabled: true);

      // 体験版テスト用: dashboardプロバイダーのみモックし、
      // 夢/目標プロバイダーは実DBを使用してカウントを追跡する
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            databaseProvider.overrideWithValue(db),
            remoteConfigProvider.overrideWithValue(UserConfig.defaultConfig),
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
                thisWeekTotal: 7,
                thisWeekMinutes: 0,
                thisMonthDays: 0,
                thisMonthTotal: 30,
                thisMonthMinutes: 0,
                overallRate: 0,
                overallStudyDays: 0,
                overallTotalDays: 0,
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
            dreamCountProvider.overrideWith((ref) async => 0),
            goalCountProvider.overrideWith((ref) async => 0),
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
          child: const YumeHashiApp(),
        ),
      );
      await tester.pumpAndSettle();

      // 夢ページへ移動（GoRouterシングルトンの状態に依存しないようドロワー経由）
      await navigateViaDrawer(tester, '夢');
      expect(find.text('やりたいことを見つけよう'), findsOneWidget);

      // ── 初期状態（レベル0: 夢1個まで）──────────────────────────────────
      // 夢1個目を追加（制限内）
      await addDream(tester, 'テスト夢1');
      expect(find.text('テスト夢1'), findsOneWidget);

      // ── 1回目: 制限ポップアップ → フィードバック送信 ─────────────────────
      // 夢2個目を追加しようとすると制限ポップアップが表示される（1/1）
      await tester.tap(find.text('夢を追加'));
      await tester.pumpAndSettle();

      expect(find.text('夢の上限に達しました'), findsOneWidget);
      expect(find.text('フィードバックを送信'), findsOneWidget);

      // フィードバックを送信してレベル1に解除
      await tester.tap(find.text('フィードバックを送信'));
      await tester.pumpAndSettle();

      const feedback1 =
          'テスト用フィードバック（1回目）: このアプリは夢の実現を支援するための優れたツールです。'
          '目標管理とタスク管理の連携が特に便利で、日々の学習計画を立てやすくなっています。'
          'さらなる改善として、リマインダー機能の充実や統計グラフの多様化を期待しています。';

      await submitFeedback(tester, feedback1);

      // 送信成功スナックバー確認（レベル1へ解除）
      expect(find.textContaining('レベル1に解除'), findsOneWidget);

      // ── レベル1（夢2個まで）: 夢2個目を追加 ──────────────────────────────
      await addDream(tester, 'テスト夢2');
      expect(find.text('テスト夢2'), findsOneWidget);

      // ── 2回目: 制限ポップアップ → フィードバック送信 ─────────────────────
      // 夢3個目を追加しようとすると制限ポップアップが表示される（2/2）
      await tester.tap(find.text('夢を追加'));
      await tester.pumpAndSettle();

      expect(find.text('夢の上限に達しました'), findsOneWidget);
      expect(find.text('フィードバックを送信'), findsOneWidget);

      await tester.tap(find.text('フィードバックを送信'));
      await tester.pumpAndSettle();

      const feedback2 =
          'テスト用フィードバック（2回目）: ダッシュボードの統計表示が非常に参考になります。'
          '学習時間の推移が一目でわかり、モチベーション維持に役立っています。'
          'スケジュール機能との連携があると学習計画をより効率的に管理できると思います。';

      await submitFeedback(tester, feedback2);

      // 送信成功スナックバー確認（レベル2でフィードバック上限到達）
      expect(find.textContaining('フィードバックを送信しました'), findsOneWidget);

      // ── レベル2（夢3個まで）: 夢3個目を追加 ──────────────────────────────
      await addDream(tester, 'テスト夢3');
      expect(find.text('テスト夢3'), findsOneWidget);

      // ── 最終確認: フィードバック上限到達の制限ポップアップが表示される ────
      // 夢4個目を追加しようとすると制限ポップアップが表示される（3/3、レベル2上限）
      await tester.tap(find.text('夢を追加'));
      await tester.pumpAndSettle();

      expect(find.text('夢の上限に達しました'), findsOneWidget);
      // フィードバック上限到達のため、課金プランへの誘導ボタンが表示される
      expect(find.text('無制限プランを見る'), findsOneWidget);
    },
  );

  // ─────────────────────────────────────────────────────────────────────────
  // 目標 CRUD テスト
  // ─────────────────────────────────────────────────────────────────────────

  testWidgets('目標を追加できる', (tester) async {
    await tester.pumpWidget(await buildRealApp());
    await tester.pumpAndSettle();

    // 夢を先に登録
    await tapBottomNav(tester, 1);
    await addDream(tester, '夢テスト');

    // 目標ページへ移動
    await tapBottomNav(tester, 2);

    // 目標を追加
    await addGoal(tester, 'テスト追加目標');

    // 追加した目標が一覧に表示される
    expect(find.text('テスト追加目標'), findsOneWidget);
  });

  testWidgets('目標を編集できる', (tester) async {
    await tester.pumpWidget(await buildRealApp());
    await tester.pumpAndSettle();

    // 夢と目標を追加
    await tapBottomNav(tester, 1);
    await addDream(tester, '夢テスト');
    await tapBottomNav(tester, 2);
    await addGoal(tester, '編集前の目標');
    expect(find.text('編集前の目標'), findsOneWidget);

    // PopupMenuから編集を選択
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('編集'));
    await tester.pumpAndSettle();
    expect(find.text('目標を編集'), findsOneWidget);

    // Whatフィールドを書き換え（インデックス0: What）
    await tester.enterText(find.byType(TextFormField).first, '編集後の目標');
    await tester.pumpAndSettle();

    // 更新
    await tester.tap(find.text('更新'));
    await tester.pumpAndSettle();

    // 更新後のテキストが表示され、古いテキストが消える
    expect(find.text('編集後の目標'), findsOneWidget);
    expect(find.text('編集前の目標'), findsNothing);
  });

  testWidgets('目標を削除できる', (tester) async {
    await tester.pumpWidget(await buildRealApp());
    await tester.pumpAndSettle();

    // 夢と目標を追加
    await tapBottomNav(tester, 1);
    await addDream(tester, '夢テスト');
    await tapBottomNav(tester, 2);
    await addGoal(tester, '削除対象の目標');
    expect(find.text('削除対象の目標'), findsOneWidget);

    // PopupMenuから削除を選択
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('削除'));
    await tester.pumpAndSettle();
    expect(find.text('目標を削除'), findsOneWidget);

    // 削除を確認
    await tester.tap(
      find.widgetWithText(ElevatedButton, '削除'),
    );
    await tester.pumpAndSettle();

    // 目標が削除されて空状態が表示される
    expect(find.text('削除対象の目標'), findsNothing);
    expect(find.text('最初の目標を設定しよう'), findsOneWidget);
  });

  // ─────────────────────────────────────────────────────────────────────────
  // タスク CRUD テスト（スケジュール経由）
  // ─────────────────────────────────────────────────────────────────────────

  testWidgets('タスクを追加できる', (tester) async {
    await tester.pumpWidget(await buildRealApp());
    await tester.pumpAndSettle();

    // 夢と目標を追加
    await navigateViaDrawer(tester, '夢');
    await addDream(tester, '夢テスト');
    await navigateViaDrawer(tester, '目標');
    await addGoal(tester, 'タスク用目標');

    // ドロワー経由でスケジュールへ移動
    await navigateViaDrawer(tester, 'スケジュール');

    // 目標ドロップダウンで目標を選択
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('タスク用目標').last);
    await tester.pumpAndSettle();

    // 「タスクを追加」ボタンが表示される
    expect(find.text('タスクを追加'), findsOneWidget);

    // タスクを追加
    await addTask(tester, 'テスト追加タスク');

    // スケジュールが表示される（空状態が消える）
    expect(find.text('タスクがありません'), findsNothing);
  });

  testWidgets('タスクを編集できる', (tester) async {
    await tester.pumpWidget(await buildRealApp());
    await tester.pumpAndSettle();

    // 夢・目標・タスクを追加（GoRouterが/ganttに残っている可能性があるため
    // ドロワー経由で遷移する）
    await navigateViaDrawer(tester, '夢');
    await addDream(tester, '夢テスト');
    await navigateViaDrawer(tester, '目標');
    await addGoal(tester, 'タスク用目標');

    await navigateViaDrawer(tester, 'スケジュール');

    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('タスク用目標').last);
    await tester.pumpAndSettle();

    await addTask(tester, '編集前タスク');

    // スケジュール上の行0をタップして編集ダイアログを開く
    final customPaint = find.byType(CustomPaint).last;
    final chartRect = tester.getRect(customPaint);
    // headerHeight=70, rowHeight=40 → 行0中央 y=90
    await tester.tapAt(Offset(chartRect.left + 100, chartRect.top + 90));
    await tester.pumpAndSettle();

    // 編集ダイアログが開く
    expect(find.text('タスクを編集'), findsOneWidget);

    // タスク名フィールドを更新
    await tester.enterText(find.byType(TextFormField).first, '編集後タスク');
    await tester.pumpAndSettle();

    await tester.tap(find.text('更新'));
    await tester.pumpAndSettle();

    // ダイアログが閉じてチャートが再描画される（エラーなく完了）
    expect(find.text('タスクを編集'), findsNothing);
  });

  testWidgets('タスクを削除できる', (tester) async {
    await tester.pumpWidget(await buildRealApp());
    await tester.pumpAndSettle();

    // 夢・目標・タスクを追加（GoRouterが/ganttに残っている可能性があるため
    // ドロワー経由で遷移する）
    await navigateViaDrawer(tester, '夢');
    await addDream(tester, '夢テスト');
    await navigateViaDrawer(tester, '目標');
    await addGoal(tester, 'タスク用目標');

    await navigateViaDrawer(tester, 'スケジュール');

    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('タスク用目標').last);
    await tester.pumpAndSettle();

    await addTask(tester, '削除対象タスク');

    // スケジュール上の行0をタップして編集ダイアログを開く
    final customPaint = find.byType(CustomPaint).last;
    final chartRect = tester.getRect(customPaint);
    await tester.tapAt(Offset(chartRect.left + 100, chartRect.top + 90));
    await tester.pumpAndSettle();

    expect(find.text('タスクを編集'), findsOneWidget);

    // 削除ボタンをタップ
    await tester.tap(find.widgetWithText(TextButton, '削除'));
    await tester.pumpAndSettle();

    // 削除確認ダイアログ
    expect(find.text('タスクを削除'), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, '削除'));
    await tester.pumpAndSettle();

    // タスクが削除されて空状態が表示される
    expect(find.text('タスクがありません'), findsOneWidget);
  });

  // ─────────────────────────────────────────────────────────────────────────
  // ボトムナビ: スケジュールタブ
  // ─────────────────────────────────────────────────────────────────────────

  testWidgets('ボトムナビからスケジュールページに遷移できる', (tester) async {
    await tester.pumpWidget(await buildApp());
    await tester.pumpAndSettle();

    // スケジュールタブ（index=3）をタップ
    await tapBottomNav(tester, 3);

    // スケジュールページが表示される（AppBarタイトル + ボトムナビラベル）
    expect(find.text('スケジュール'), findsWidgets);
    // ボトムナビにスケジュールアイコンがアクティブ
    expect(findNavBarIcon(Icons.view_timeline), findsOneWidget);
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 夢カード: 目標0件バッジ非表示
  // ─────────────────────────────────────────────────────────────────────────

  testWidgets('夢カードに目標0件の場合はバッジが表示されない', (tester) async {
    await tester.pumpWidget(await buildRealApp());
    await tester.pumpAndSettle();

    // 夢ページへ移動して夢を追加
    await tapBottomNav(tester, 1);
    await addDream(tester, '目標なし夢');

    // 夢カードが表示される
    expect(find.text('目標なし夢'), findsOneWidget);
    // 目標バッジ（目標 0）が非表示
    expect(find.text('目標 0'), findsNothing);
  });

  testWidgets('夢カードに目標が紐づく場合はバッジが表示される', (tester) async {
    await tester.pumpWidget(await buildAppWithData());
    await tester.pumpAndSettle();

    // 夢ページへ移動
    await tapBottomNav(tester, 1);

    // 夢カードが表示される
    expect(find.text('テスト夢'), findsOneWidget);
    // 目標バッジ（目標 1）が表示される
    expect(find.text('目標 1'), findsOneWidget);
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 設定画面: お問い合わせ・フィードバック
  // ─────────────────────────────────────────────────────────────────────────

  testWidgets('設定画面にお問い合わせセクションが表示される', (tester) async {
    await tester.pumpWidget(await buildApp());
    await tester.pumpAndSettle();

    // 設定画面へ移動
    await navigateViaDrawer(tester, '設定');

    // お問い合わせセクションまでスクロール
    await tester.scrollUntilVisible(
      find.text('追加開発・案件のご相談など'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    // お問い合わせカードが表示される
    expect(find.text('お問い合わせ'), findsWidgets);
    expect(find.text('追加開発・案件のご相談など'), findsOneWidget);
  });

  testWidgets('お問い合わせダイアログが開きカテゴリが表示される', (tester) async {
    await tester.pumpWidget(await buildApp());
    await tester.pumpAndSettle();

    await navigateViaDrawer(tester, '設定');

    // お問い合わせカードまでスクロールしてタップ
    await tester.scrollUntilVisible(
      find.text('追加開発・案件のご相談など'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('追加開発・案件のご相談など'));
    await tester.pumpAndSettle();

    // お問い合わせダイアログが開く
    expect(find.text('お問い合わせ'), findsWidgets);
    expect(find.text('メールアドレス *'), findsOneWidget);
    expect(find.text('お問い合わせ内容 *'), findsOneWidget);

    // カテゴリドロップダウンを開く
    await tester.tap(find.byType(DropdownButtonFormField<InquiryCategory>));
    await tester.pumpAndSettle();

    // 3つのカテゴリが表示される
    expect(find.text('追加開発の相談'), findsOneWidget);
    expect(find.text('案件のご依頼'), findsOneWidget);
    expect(find.text('その他のお問い合わせ'), findsOneWidget);

    // キャンセルで閉じる
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
  });

  testWidgets('フィードバック送信ボタンがレベル上限後も表示される', (tester) async {
    addTearDown(() => setTrialModeForTest(enabled: false));
    setTrialModeForTest(enabled: true);

    // レベル2（フィードバック上限）の状態で起動
    SharedPreferences.setMockInitialValues({
      'feedback_unlock_level': feedbackUnlockableLevel,
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
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
              thisWeekTotal: 7,
              thisWeekMinutes: 0,
              thisMonthDays: 0,
              thisMonthTotal: 30,
              thisMonthMinutes: 0,
              overallRate: 0,
              overallStudyDays: 0,
              overallTotalDays: 0,
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
          dreamCountProvider.overrideWith((ref) async => 0),
          goalCountProvider.overrideWith((ref) async => 0),
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
        child: const YumeHashiApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 設定画面へ移動
    await navigateViaDrawer(tester, '設定');

    // フィードバックセクションまでスクロール
    await tester.scrollUntilVisible(
      find.text('フィードバックを送信'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    // レベル上限後もフィードバック送信ボタンが表示される
    expect(find.text('フィードバックを送信'), findsOneWidget);
    expect(find.text('ご意見・ご要望をお聞かせください'), findsOneWidget);

    // 無制限プランの案内も併記される
    expect(find.text('無制限プランのご案内'), findsOneWidget);
  });

  testWidgets('フィードバックダイアログのカテゴリが3種類である', (tester) async {
    await tester.pumpWidget(await buildApp());
    await tester.pumpAndSettle();

    await navigateViaDrawer(tester, '設定');

    // フィードバック送信までスクロールしてタップ
    await tester.scrollUntilVisible(
      find.text('フィードバックを送信'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('フィードバックを送信'));
    await tester.pumpAndSettle();

    // カテゴリドロップダウンを開く
    await tester.tap(find.byType(DropdownButtonFormField<FeedbackCategory>));
    await tester.pumpAndSettle();

    // 3つのカテゴリが表示される
    expect(find.text('改善要望'), findsOneWidget);
    expect(find.text('不具合'), findsOneWidget);
    expect(find.text('その他'), findsOneWidget);
    // 旧カテゴリは表示されない
    expect(find.text('使いやすさ'), findsNothing);

    // キャンセルで閉じる
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
  });
}
