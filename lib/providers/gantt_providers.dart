/// ガントチャート関連のProvider定義.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/goal.dart';
import '../models/task.dart' show Task, TaskStatus, bookGanttGoalId;
import 'service_providers.dart';
import 'theme_provider.dart' show sharedPreferencesProvider;

/// 完了タスクの表示状態を保存する SharedPreferences キー.
const ganttShowCompletedPrefsKey = 'gantt_show_completed';

/// ガントチャートの表示モード.
enum GanttViewMode {
  /// 全タスク.
  allTasks,

  /// 目標別.
  byGoal,

  /// 書籍別.
  allBooks,
}

/// ガントチャートの日付範囲プリセット.
enum GanttDateRange {
  /// 直近3ヶ月.
  months3('直近3ヶ月', 3),

  /// 直近6ヶ月.
  months6('直近6ヶ月', 6),

  /// 直近1年.
  year1('直近1年', 12),

  /// 全期間.
  all('全期間', 0);

  const GanttDateRange(this.label, this.months);

  /// 表示ラベル.
  final String label;

  /// 月数（0は全期間）.
  final int months;
}

/// ガントチャートの表示状態.
class GanttViewState {
  /// GanttViewStateを作成する.
  const GanttViewState({
    this.mode = GanttViewMode.allTasks,
    this.selectedGoalId,
    this.dateRange = GanttDateRange.months3,
  });

  /// 表示モード.
  final GanttViewMode mode;

  /// 選択中のGoal ID（byGoalモード時）.
  final String? selectedGoalId;

  /// 日付範囲フィルタ.
  final GanttDateRange dateRange;

  /// コピーを作成する.
  GanttViewState copyWith({
    GanttViewMode? mode,
    String? selectedGoalId,
    GanttDateRange? dateRange,
  }) {
    return GanttViewState(
      mode: mode ?? this.mode,
      selectedGoalId: selectedGoalId ?? this.selectedGoalId,
      dateRange: dateRange ?? this.dateRange,
    );
  }
}

/// 完了タスクを表示するかどうかを管理するNotifier.
///
/// デフォルトは `false`（完了タスクは非表示）. ユーザーが増えてタスク数が
/// 増大しても描画パフォーマンスが劣化しないようにするための設計.
/// SharedPreferences の `gantt_show_completed` キーで永続化される.
class GanttShowCompletedNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(ganttShowCompletedPrefsKey) ?? false;
  }

  /// 完了タスクの表示状態を切り替えて永続化する.
  void setShowCompleted({required bool show}) {
    state = show;
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setBool(ganttShowCompletedPrefsKey, show);
  }
}

/// 完了タスクを表示するかどうかのProvider.
final ganttShowCompletedProvider =
    NotifierProvider<GanttShowCompletedNotifier, bool>(
  GanttShowCompletedNotifier.new,
);

/// ガントチャートの表示状態Provider.
final ganttViewStateProvider =
    NotifierProvider<GanttViewStateNotifier, GanttViewState>(
  GanttViewStateNotifier.new,
);

/// GanttViewStateのNotifier.
class GanttViewStateNotifier extends Notifier<GanttViewState> {
  @override
  GanttViewState build() => const GanttViewState();

  /// 全タスク表示に切り替える.
  void showAllTasks() {
    state = GanttViewState(
      mode: GanttViewMode.allTasks,
      dateRange: state.dateRange,
    );
  }

  /// 目標別表示に切り替える.
  void showByGoal(String goalId) {
    state = GanttViewState(
      mode: GanttViewMode.byGoal,
      selectedGoalId: goalId,
      dateRange: state.dateRange,
    );
  }

  /// 書籍別表示に切り替える.
  void showAllBooks() {
    state = GanttViewState(
      mode: GanttViewMode.allBooks,
      dateRange: state.dateRange,
    );
  }

  /// 日付範囲を変更する.
  void setDateRange(GanttDateRange range) {
    state = state.copyWith(dateRange: range);
  }
}

/// ガントチャート用タスク一覧Provider.
///
/// 目標名でグルーピングし、各グループ内は開始日の昇順でソートする.
/// デフォルトでは完了タスクを除外する（[ganttShowCompletedProvider] で切替可）.
final ganttTasksProvider = FutureProvider<List<Task>>((ref) async {
  final viewState = ref.watch(ganttViewStateProvider);
  final showCompleted = ref.watch(ganttShowCompletedProvider);
  final taskService = ref.watch(taskServiceProvider);
  final bookGanttService = ref.watch(bookGanttServiceProvider);

  List<Task> tasks;
  switch (viewState.mode) {
    case GanttViewMode.allTasks:
      final tasksFuture = taskService.getAllTasks();
      final booksFuture = bookGanttService.getScheduledBooks();
      final allTasks = await tasksFuture;
      final scheduledBooks = await booksFuture;
      final bookTasks = bookGanttService.booksToTasks(scheduledBooks);
      tasks = [...allTasks, ...bookTasks];
    case GanttViewMode.byGoal:
      final goalId = viewState.selectedGoalId;
      if (goalId == null) return [];
      tasks = await taskService.getTasksForGoal(goalId);
    case GanttViewMode.allBooks:
      final scheduledBooks = await bookGanttService.getScheduledBooks();
      tasks = bookGanttService.booksToTasks(scheduledBooks);
  }

  // 完了タスクフィルタ適用（デフォルトでは非表示）.
  // 書籍ガントは現状「完了」状態を持たないので影響しない.
  if (!showCompleted) {
    tasks = tasks
        .where((t) => t.status != TaskStatus.completed && t.progress < 100)
        .toList();
  }

  // 日付範囲フィルタ適用
  if (viewState.dateRange != GanttDateRange.all) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final rangeStart = DateTime(
      today.year,
      today.month - viewState.dateRange.months,
      today.day,
    );
    final rangeEnd = today.add(
      Duration(days: viewState.dateRange.months * 30),
    );
    tasks = tasks.where((t) =>
        !t.endDate.isBefore(rangeStart) && !t.startDate.isAfter(rangeEnd),
    ).toList();
  }

  // 目標名でグルーピング→開始日の昇順でソート
  final goalService = ref.watch(goalServiceProvider);
  final goals = await goalService.getAllGoals();
  final goalNameMap = <String, String>{
    for (final g in goals) g.id: g.what,
  };

  String goalSortKey(String goalId) {
    if (goalId == bookGanttGoalId) return '\uFFFF書籍'; // 書籍は末尾
    if (goalId.isEmpty) return '\uFFFF独立タスク'; // 独立タスクも末尾寄り
    return goalNameMap[goalId] ?? '\uFFFF不明';
  }

  tasks.sort((a, b) {
    final goalCmp = goalSortKey(a.goalId).compareTo(goalSortKey(b.goalId));
    if (goalCmp != 0) return goalCmp;
    return a.startDate.compareTo(b.startDate);
  });

  return tasks;
});

/// 目標一覧Provider（セレクタ用）.
final ganttGoalListProvider = FutureProvider<List<Goal>>((ref) async {
  final goalService = ref.watch(goalServiceProvider);
  return goalService.getAllGoals();
});
