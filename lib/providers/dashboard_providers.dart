/// ダッシュボード関連のProvider定義.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/motivation_calculator.dart';
import '../services/study_stats_calculator.dart';
import '../services/study_stats_types.dart';
import '../widgets/stats/goal_stats_section.dart';
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

/// 今日の活動データProvider.
final todayStudyProvider = FutureProvider<TodayStudyData>((ref) async {
  final logService = ref.watch(studyLogServiceProvider);
  final logs = await logService.getAllLogs();
  return MotivationCalculator.calculateTodayStudy(logs);
});

/// ストリークデータProvider.
final streakProvider = FutureProvider<StreakData>((ref) async {
  final logService = ref.watch(studyLogServiceProvider);
  final logs = await logService.getAllLogs();
  return MotivationCalculator.calculateStreak(logs);
});

/// 自己ベストProvider.
final personalRecordProvider = FutureProvider<PersonalRecordData>((ref) async {
  final logService = ref.watch(studyLogServiceProvider);
  final logs = await logService.getAllLogs();
  return MotivationCalculator.calculatePersonalRecords(logs);
});

/// 活動の実施率Provider.
final consistencyProvider = FutureProvider<ConsistencyData>((ref) async {
  final logService = ref.watch(studyLogServiceProvider);
  final logs = await logService.getAllLogs();
  return MotivationCalculator.calculateConsistency(logs);
});

/// 本棚データProvider.
final bookshelfProvider = FutureProvider<BookshelfData>((ref) async {
  final bookService = ref.watch(bookServiceProvider);
  return bookService.getBookshelfData();
});

/// 夢数Provider.
final dreamCountProvider = FutureProvider<int>((ref) async {
  final dreamService = ref.watch(dreamServiceProvider);
  final dreams = await dreamService.getAllDreams();
  return dreams.length;
});

/// 目標数Provider.
final goalCountProvider = FutureProvider<int>((ref) async {
  final goalService = ref.watch(goalServiceProvider);
  final goals = await goalService.getAllGoals();
  return goals.length;
});

/// アクティビティチャートProvider.
final dailyActivityProvider = FutureProvider<DailyActivityData>((ref) async {
  final logService = ref.watch(studyLogServiceProvider);
  final logs = await logService.getAllLogs();
  return StudyStatsCalculator.calculateDailyActivity(logs);
});

/// 実績データProvider.
final milestoneDataProvider = FutureProvider<MilestoneData>((ref) async {
  final logService = ref.watch(studyLogServiceProvider);
  final logs = await logService.getAllLogs();
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

  final result = <GoalStatsDisplayData>[];
  for (final goal in goals) {
    final tasks = await taskService.getTasksForGoal(goal.id);
    final taskIds = tasks.map((t) => t.id).toList();
    final stats = await logService.getGoalStats(goal.id, taskIds);
    final taskNames = {for (final t in tasks) t.id: t.title};
    result.add(GoalStatsDisplayData(
      name: goal.what,
      color: goal.color,
      stats: stats,
      taskNames: taskNames,
    ));
  }
  return result;
});

/// 読書別統計Provider.
final bookStatsProvider =
    FutureProvider<List<GoalStatsDisplayData>>((ref) async {
  final bookService = ref.watch(bookServiceProvider);
  final taskService = ref.watch(taskServiceProvider);
  final logService = ref.watch(studyLogServiceProvider);
  final books = await bookService.getAllBooks();

  final result = <GoalStatsDisplayData>[];
  for (final book in books) {
    final tasks = await taskService.getTasksForBook(book.id);
    if (tasks.isEmpty) continue;
    final taskIds = tasks.map((t) => t.id).toList();
    final stats = await logService.getGoalStats(book.id, taskIds);
    final taskNames = {for (final t in tasks) t.id: t.title};
    result.add(GoalStatsDisplayData(
      name: book.title,
      color: '#F9E2AF',
      stats: stats,
      taskNames: taskNames,
    ));
  }
  return result;
});
