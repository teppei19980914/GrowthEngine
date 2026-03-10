import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yume_log/database/app_database.dart';
import 'package:yume_log/models/goal.dart';
import 'package:yume_log/providers/book_providers.dart';
import 'package:yume_log/providers/constellation_providers.dart';
import 'package:yume_log/providers/dashboard_providers.dart';
import 'package:yume_log/providers/database_provider.dart';
import 'package:yume_log/providers/dream_providers.dart';
import 'package:yume_log/providers/gantt_providers.dart';
import 'package:yume_log/providers/goal_providers.dart';
import 'package:yume_log/models/book.dart';
import 'package:yume_log/providers/service_providers.dart';
import 'package:yume_log/providers/theme_provider.dart';
import 'package:yume_log/theme/app_theme.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('ServiceProviders', () {
    test('dreamServiceProvider を取得できる', () {
      final service = container.read(dreamServiceProvider);
      expect(service, isNotNull);
    });

    test('goalServiceProvider を取得できる', () {
      final service = container.read(goalServiceProvider);
      expect(service, isNotNull);
    });

    test('taskServiceProvider を取得できる', () {
      final service = container.read(taskServiceProvider);
      expect(service, isNotNull);
    });

    test('bookServiceProvider を取得できる', () {
      final service = container.read(bookServiceProvider);
      expect(service, isNotNull);
    });

    test('studyLogServiceProvider を取得できる', () {
      final service = container.read(studyLogServiceProvider);
      expect(service, isNotNull);
    });

    test('bookGanttServiceProvider を取得できる', () {
      final service = container.read(bookGanttServiceProvider);
      expect(service, isNotNull);
    });

    test('notificationServiceProvider を取得できる', () {
      final service = container.read(notificationServiceProvider);
      expect(service, isNotNull);
    });

    test('dataExportServiceProvider を取得できる', () {
      final service = container.read(dataExportServiceProvider);
      expect(service, isNotNull);
    });

    test('dashboardLayoutServiceProvider を取得できる', () {
      final service = container.read(dashboardLayoutServiceProvider);
      expect(service, isNotNull);
    });
  });

  group('ThemeProvider', () {
    test('デフォルトはダークテーマ', () {
      final theme = container.read(themeProvider);
      expect(theme, ThemeType.dark);
    });

    test('テーマを切り替えできる', () {
      container.read(themeProvider.notifier).toggleTheme();
      expect(container.read(themeProvider), ThemeType.light);
      container.read(themeProvider.notifier).toggleTheme();
      expect(container.read(themeProvider), ThemeType.dark);
    });

    test('テーマを直接設定できる', () {
      container.read(themeProvider.notifier).setTheme(ThemeType.light);
      expect(container.read(themeProvider), ThemeType.light);
    });

    test('保存されたテーマを復元する', () async {
      SharedPreferences.setMockInitialValues({'theme_type': 'light'});
      final prefs = await SharedPreferences.getInstance();
      final c2 = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      expect(c2.read(themeProvider), ThemeType.light);
      c2.dispose();
    });
  });

  group('DreamListProvider', () {
    test('初期状態は空リスト', () async {
      final dreams = await container.read(dreamListProvider.future);
      expect(dreams, isEmpty);
    });

    test('Dreamを作成できる', () async {
      await container
          .read(dreamListProvider.notifier)
          .createDream(title: 'テスト夢');
      final dreams = await container.read(dreamListProvider.future);
      expect(dreams.length, 1);
      expect(dreams.first.title, 'テスト夢');
    });

    test('Dreamを更新できる', () async {
      await container
          .read(dreamListProvider.notifier)
          .createDream(title: '元のタイトル');
      var dreams = await container.read(dreamListProvider.future);
      final id = dreams.first.id;

      await container
          .read(dreamListProvider.notifier)
          .updateDream(dreamId: id, title: '新しいタイトル');
      dreams = await container.read(dreamListProvider.future);
      expect(dreams.first.title, '新しいタイトル');
    });

    test('Dreamを削除できる', () async {
      await container
          .read(dreamListProvider.notifier)
          .createDream(title: '削除テスト');
      var dreams = await container.read(dreamListProvider.future);
      expect(dreams.length, 1);

      await container
          .read(dreamListProvider.notifier)
          .deleteDream(dreams.first.id);
      dreams = await container.read(dreamListProvider.future);
      expect(dreams, isEmpty);
    });
  });

  group('GoalListProvider', () {
    test('初期状態は空リスト', () async {
      final goals = await container.read(goalListProvider.future);
      expect(goals, isEmpty);
    });

    test('Goalを作成・削除できる', () async {
      // 先にDreamを作成
      await container
          .read(dreamListProvider.notifier)
          .createDream(title: 'テスト夢');
      final dreams = await container.read(dreamListProvider.future);
      final dreamId = dreams.first.id;

      await container.read(goalListProvider.notifier).createGoal(
            dreamId: dreamId,
            whenTarget: '2026-12-31',
            whenType: WhenType.date,
            what: 'テスト目標',
            how: 'テスト方法',
          );
      var goals = await container.read(goalListProvider.future);
      expect(goals.length, 1);
      expect(goals.first.what, 'テスト目標');

      await container
          .read(goalListProvider.notifier)
          .deleteGoal(goals.first.id);
      goals = await container.read(goalListProvider.future);
      expect(goals, isEmpty);
    });
  });

  group('BookListProvider', () {
    test('初期状態は空リスト', () async {
      final books = await container.read(bookListProvider.future);
      expect(books, isEmpty);
    });

    test('Bookを作成・削除できる', () async {
      await container
          .read(bookListProvider.notifier)
          .createBook('テスト書籍');
      var books = await container.read(bookListProvider.future);
      expect(books.length, 1);
      expect(books.first.title, 'テスト書籍');

      await container
          .read(bookListProvider.notifier)
          .deleteBook(books.first.id);
      books = await container.read(bookListProvider.future);
      expect(books, isEmpty);
    });

    test('Bookのステータスを更新できる', () async {
      await container
          .read(bookListProvider.notifier)
          .createBook('ステータステスト');
      var books = await container.read(bookListProvider.future);
      final id = books.first.id;

      await container
          .read(bookListProvider.notifier)
          .updateStatus(id, BookStatus.reading);
      books = await container.read(bookListProvider.future);
      expect(books.first.status, BookStatus.reading);
    });

    test('Bookを読了にできる', () async {
      await container
          .read(bookListProvider.notifier)
          .createBook('読了テスト');
      var books = await container.read(bookListProvider.future);
      final id = books.first.id;

      await container.read(bookListProvider.notifier).completeBook(
            bookId: id,
            summary: '要約',
            impressions: '感想',
          );
      books = await container.read(bookListProvider.future);
      expect(books.first.status, BookStatus.completed);
      expect(books.first.summary, '要約');
    });
  });

  group('GanttProviders', () {
    test('GanttViewState初期値', () {
      final state = container.read(ganttViewStateProvider);
      expect(state.mode, GanttViewMode.allTasks);
      expect(state.selectedGoalId, isNull);
    });

    test('表示モードを切り替え', () {
      container.read(ganttViewStateProvider.notifier).showAllBooks();
      expect(
        container.read(ganttViewStateProvider).mode,
        GanttViewMode.allBooks,
      );

      container.read(ganttViewStateProvider.notifier).showByGoal('goal-1');
      expect(
        container.read(ganttViewStateProvider).mode,
        GanttViewMode.byGoal,
      );
      expect(
        container.read(ganttViewStateProvider).selectedGoalId,
        'goal-1',
      );

      container.read(ganttViewStateProvider.notifier).showAllTasks();
      expect(
        container.read(ganttViewStateProvider).mode,
        GanttViewMode.allTasks,
      );
    });

    test('GanttViewState.copyWith', () {
      const state = GanttViewState();
      final copied = state.copyWith(mode: GanttViewMode.allBooks);
      expect(copied.mode, GanttViewMode.allBooks);
      expect(copied.selectedGoalId, isNull);
    });

    test('ganttTasksProviderはタスク一覧を返す', () async {
      final tasks = await container.read(ganttTasksProvider.future);
      expect(tasks, isEmpty);
    });

    test('ganttGoalListProviderは目標一覧を返す', () async {
      final goals = await container.read(ganttGoalListProvider.future);
      expect(goals, isEmpty);
    });
  });

  group('DashboardProviders', () {
    test('todayStudyProvider', () async {
      final data = await container.read(todayStudyProvider.future);
      expect(data.totalMinutes, 0);
      expect(data.sessionCount, 0);
    });

    test('streakProvider', () async {
      final data = await container.read(streakProvider.future);
      expect(data.currentStreak, 0);
    });

    test('personalRecordProvider', () async {
      final data = await container.read(personalRecordProvider.future);
      expect(data.totalHours, 0);
    });

    test('consistencyProvider', () async {
      final data = await container.read(consistencyProvider.future);
      expect(data.overallStudyDays, 0);
    });

    test('bookshelfProvider', () async {
      final data = await container.read(bookshelfProvider.future);
      expect(data.totalCount, 0);
    });

    test('dreamCountProvider', () async {
      final count = await container.read(dreamCountProvider.future);
      expect(count, 0);
    });

    test('goalCountProvider', () async {
      final count = await container.read(goalCountProvider.future);
      expect(count, 0);
    });

    test('dailyActivityProvider', () async {
      final data = await container.read(dailyActivityProvider.future);
      expect(data.maxMinutes, 0);
    });

    test('milestoneDataProvider', () async {
      final data = await container.read(milestoneDataProvider.future);
      expect(data.achieved, isEmpty);
    });

    test('goalStatsProvider', () async {
      final data = await container.read(goalStatsProvider.future);
      expect(data, isEmpty);
    });

    test('bookStatsProvider', () async {
      final data = await container.read(bookStatsProvider.future);
      expect(data, isEmpty);
    });
  });

  group('ConstellationProviders', () {
    test('constellationServiceProvider を取得できる', () {
      final service = container.read(constellationServiceProvider);
      expect(service, isNotNull);
    });

    test('constellationProgressProvider は全星座の進捗を返す', () async {
      // 活動ログがないので全星座0個
      final progress =
          await container.read(constellationProgressProvider.future);
      expect(progress.constellations.length, 36);
      expect(progress.totalLitStars, 0);
    });
  });

  group('DashboardLayoutNotifier', () {
    test('レイアウトを取得できる', () async {
      final layout =
          await container.read(dashboardLayoutProvider.future);
      expect(layout, isNotEmpty);
    });
  });
}
