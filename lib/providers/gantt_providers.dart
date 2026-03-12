/// ガントチャート関連のProvider定義.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/goal.dart';
import '../models/task.dart';
import '../services/book_gantt_service.dart' show bookGanttGoalId;
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
final ganttTasksProvider = FutureProvider<List<Task>>((ref) async {
  final viewState = ref.watch(ganttViewStateProvider);
  final taskService = ref.watch(taskServiceProvider);
  final bookGanttService = ref.watch(bookGanttServiceProvider);

  switch (viewState.mode) {
    case GanttViewMode.allTasks:
      final tasks = await taskService.getAllTasks();
      final scheduledBooks = await bookGanttService.getScheduledBooks();
      final bookTasks = bookGanttService.booksToTasks(scheduledBooks);
      return [...tasks, ...bookTasks];
    case GanttViewMode.byGoal:
      final goalId = viewState.selectedGoalId;
      if (goalId == null) return [];
      return taskService.getTasksForGoal(goalId);
    case GanttViewMode.allBooks:
      final scheduledBooks = await bookGanttService.getScheduledBooks();
      return bookGanttService.booksToTasks(scheduledBooks);
  }
});

/// 目標一覧Provider（セレクタ用）.
final ganttGoalListProvider = FutureProvider<List<Goal>>((ref) async {
  final goalService = ref.watch(goalServiceProvider);
  return goalService.getAllGoals();
});
