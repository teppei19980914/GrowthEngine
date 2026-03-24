/// ガントチャート関連のProvider定義.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/goal.dart';
import '../models/task.dart' show Task, bookGanttGoalId;
import 'service_providers.dart';

/// ガントチャートの表示モード.
enum GanttViewMode {
  /// 全タスク.
  allTasks,

  /// 目標別.
  byGoal,

  /// 書籍別.
  allBooks,
}

/// ガントチャートの表示状態.
class GanttViewState {
  /// GanttViewStateを作成する.
  const GanttViewState({
    this.mode = GanttViewMode.allTasks,
    this.selectedGoalId,
  });

  /// 表示モード.
  final GanttViewMode mode;

  /// 選択中のGoal ID（byGoalモード時）.
  final String? selectedGoalId;

  /// コピーを作成する.
  GanttViewState copyWith({
    GanttViewMode? mode,
    String? selectedGoalId,
  }) {
    return GanttViewState(
      mode: mode ?? this.mode,
      selectedGoalId: selectedGoalId ?? this.selectedGoalId,
    );
  }
}

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
    state = const GanttViewState(mode: GanttViewMode.allTasks);
  }

  /// 目標別表示に切り替える.
  void showByGoal(String goalId) {
    state = GanttViewState(
      mode: GanttViewMode.byGoal,
      selectedGoalId: goalId,
    );
  }

  /// 書籍別表示に切り替える.
  void showAllBooks() {
    state = const GanttViewState(mode: GanttViewMode.allBooks);
  }
}

/// ガントチャート用タスク一覧Provider.
///
/// 目標名でグルーピングし、各グループ内は開始日の昇順でソートする.
final ganttTasksProvider = FutureProvider<List<Task>>((ref) async {
  final viewState = ref.watch(ganttViewStateProvider);
  final taskService = ref.watch(taskServiceProvider);
  final bookGanttService = ref.watch(bookGanttServiceProvider);

  List<Task> tasks;
  switch (viewState.mode) {
    case GanttViewMode.allTasks:
      final allTasks = await taskService.getAllTasks();
      final scheduledBooks = await bookGanttService.getScheduledBooks();
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
