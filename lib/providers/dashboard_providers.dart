/// ダッシュボード関連のProvider定義.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/study_log.dart';
import '../services/motivation_calculator.dart';
import '../services/study_stats_calculator.dart';
import '../services/study_stats_types.dart';
import '../widgets/stats/goal_stats_section.dart';
import 'dream_providers.dart';
import 'goal_providers.dart';
import 'service_providers.dart';

/// ダッシュボードレイアウトProvider.
final dashboardLayoutProvider = AsyncNotifierProvider<
    DashboardLayoutNotifier, List<DashboardWidgetConfig>>(
  DashboardLayoutNotifier.new,
);

/// DashboardLayoutのNotifier.
class DashboardLayoutNotifier
    extends AsyncNotifier<List<DashboardWidgetConfig>> {
  @override
  Future<List<DashboardWidgetConfig>> build() async {
    final service = ref.watch(dashboardLayoutServiceProvider);
    return service.getLayout();
  }

  /// ウィジェットの順序を変更する.
  Future<void> reorder(int fromIndex, int toIndex) async {
    final service = ref.read(dashboardLayoutServiceProvider);
    final current = state.valueOrNull ?? [];
    final updated = service.reorder(current, fromIndex, toIndex);
    state = AsyncData(updated);
    await service.saveLayout(updated);
  }

  /// ウィジェットを追加する.
  Future<void> addWidget(String widgetType) async {
    final service = ref.read(dashboardLayoutServiceProvider);
    final current = state.valueOrNull ?? [];
    final updated = service.addWidget(current, widgetType);
    state = AsyncData(updated);
    await service.saveLayout(updated);
  }

  /// ウィジェットを削除する.
  Future<void> removeWidget(int index) async {
    final service = ref.read(dashboardLayoutServiceProvider);
    final current = state.valueOrNull ?? [];
    final updated = service.removeWidget(current, index);
    state = AsyncData(updated);
    await service.saveLayout(updated);
  }

  /// ウィジェットのサイズを切り替える.
  Future<void> resizeWidget(int index) async {
    final service = ref.read(dashboardLayoutServiceProvider);
    final current = state.valueOrNull ?? [];
    final updated = service.resizeWidget(current, index);
    state = AsyncData(updated);
    await service.saveLayout(updated);
  }

  /// レイアウトをデフォルトにリセットする.
  Future<void> resetToDefault() async {
    final service = ref.read(dashboardLayoutServiceProvider);
    final defaultLayout = service.getDefaultLayout();
    state = AsyncData(defaultLayout);
    await service.saveLayout(defaultLayout);
  }
}

/// 全学習ログの共有キャッシュProvider.
///
/// 複数のダッシュボードプロバイダが共有し、DBクエリを1回に集約する.
final allLogsProvider = FutureProvider<List<StudyLog>>((ref) async {
  final logService = ref.watch(studyLogServiceProvider);
  return logService.getAllLogs();
});

/// 今日の活動データProvider.
final todayStudyProvider = FutureProvider<TodayStudyData>((ref) async {
  final logs = await ref.watch(allLogsProvider.future);
  return MotivationCalculator.calculateTodayStudy(logs);
});

/// ストリークデータProvider.
final streakProvider = FutureProvider<StreakData>((ref) async {
  final logs = await ref.watch(allLogsProvider.future);
  return MotivationCalculator.calculateStreak(logs);
});

/// 自己ベストProvider.
final personalRecordProvider = FutureProvider<PersonalRecordData>((ref) async {
  final logs = await ref.watch(allLogsProvider.future);
  return MotivationCalculator.calculatePersonalRecords(logs);
});

/// 活動の実施率Provider.
final consistencyProvider = FutureProvider<ConsistencyData>((ref) async {
  final logs = await ref.watch(allLogsProvider.future);
  return MotivationCalculator.calculateConsistency(logs);
});

/// 本棚データProvider.
final bookshelfProvider = FutureProvider<BookshelfData>((ref) async {
  final bookService = ref.watch(bookServiceProvider);
  return bookService.getBookshelfData();
});

/// 夢数Provider.
final dreamCountProvider = FutureProvider<int>((ref) async {
  final dreams = await ref.watch(dreamListProvider.future);
  return dreams.length;
});

/// 目標数Provider.
final goalCountProvider = FutureProvider<int>((ref) async {
  final goals = await ref.watch(goalListProvider.future);
  return goals.length;
});

/// アクティビティチャートProvider.
final dailyActivityProvider = FutureProvider<DailyActivityData>((ref) async {
  final logs = await ref.watch(allLogsProvider.future);
  return StudyStatsCalculator.calculateDailyActivity(logs);
});

/// 実績データProvider.
final milestoneDataProvider = FutureProvider<MilestoneData>((ref) async {
  final logs = await ref.watch(allLogsProvider.future);
  final streak = MotivationCalculator.calculateStreak(logs);
  return MotivationCalculator.calculateMilestones(
    logs,
    currentStreak: streak.currentStreak,
  );
});

/// 目標別統計Provider.
final goalStatsProvider =
    FutureProvider<List<GoalStatsDisplayData>>((ref) async {
  final goalService = ref.watch(goalServiceProvider);
  final taskService = ref.watch(taskServiceProvider);
  final logService = ref.watch(studyLogServiceProvider);
  final goals = await goalService.getAllGoals();

  // 全目標のタスク取得を並列実行
  final taskFutures = goals.map((g) => taskService.getTasksForGoal(g.id));
  final allTasks = await Future.wait(taskFutures);

  // 統計計算を並列実行
  final statFutures = <Future<GoalStatsDisplayData>>[];
  for (var i = 0; i < goals.length; i++) {
    final goal = goals[i];
    final tasks = allTasks[i];
    final taskIds = tasks.map((t) => t.id).toList();
    statFutures.add(
      logService.getGoalStats(goal.id, taskIds).then((stats) =>
          GoalStatsDisplayData(
            name: goal.what,
            color: goal.color,
            stats: stats,
            taskNames: {for (final t in tasks) t.id: t.title},
          )),
    );
  }
  return Future.wait(statFutures);
});

/// 読書別統計Provider.
final bookStatsProvider =
    FutureProvider<List<GoalStatsDisplayData>>((ref) async {
  final bookService = ref.watch(bookServiceProvider);
  final taskService = ref.watch(taskServiceProvider);
  final logService = ref.watch(studyLogServiceProvider);
  final books = await bookService.getAllBooks();

  // 全書籍のタスク取得を並列実行
  final taskFutures = books.map((b) => taskService.getTasksForBook(b.id));
  final allTasks = await Future.wait(taskFutures);

  // タスクありの書籍のみ統計計算を並列実行
  final statFutures = <Future<GoalStatsDisplayData>>[];
  for (var i = 0; i < books.length; i++) {
    final tasks = allTasks[i];
    if (tasks.isEmpty) continue;
    final book = books[i];
    final taskIds = tasks.map((t) => t.id).toList();
    statFutures.add(
      logService.getGoalStats(book.id, taskIds).then((stats) =>
          GoalStatsDisplayData(
            name: book.title,
            color: '#F9E2AF',
            stats: stats,
            taskNames: {for (final t in tasks) t.id: t.title},
          )),
    );
  }
  return Future.wait(statFutures);
});
