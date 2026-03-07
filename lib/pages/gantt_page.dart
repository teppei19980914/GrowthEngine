/// ガントチャートページ.
///
/// 目標別/書籍別のタスクをガントチャートで表示する.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dialogs/book_schedule_dialog.dart';
import '../dialogs/task_dialog.dart';
import '../dialogs/trial_limit_dialog.dart';
import '../models/goal.dart';
import '../models/task.dart';
import '../providers/gantt_providers.dart';
import '../providers/service_providers.dart';
import '../services/trial_limit_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gantt/gantt_chart.dart';

/// ガントチャートページ.
class GanttPage extends ConsumerWidget {
  /// GanttPageを作成する.
  const GanttPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewState = ref.watch(ganttViewStateProvider);
    final tasksAsync = ref.watch(ganttTasksProvider);
    final goalsAsync = ref.watch(ganttGoalListProvider);
    final theme = Theme.of(context);
    final colors = theme.appColors;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // セレクタ行
          Row(
            children: [
              // 表示モードセレクタ
              goalsAsync.when(
                data: (goals) => _ViewSelector(
                  viewState: viewState,
                  goals: goals,
                  onChanged: (mode, goalId) {
                    final notifier =
                        ref.read(ganttViewStateProvider.notifier);
                    switch (mode) {
                      case GanttViewMode.allTasks:
                        notifier.showAllTasks();
                      case GanttViewMode.byGoal:
                        if (goalId != null) notifier.showByGoal(goalId);
                      case GanttViewMode.allBooks:
                        notifier.showAllBooks();
                    }
                  },
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
              const Spacer(),
              // タスク追加ボタン
              if (viewState.mode == GanttViewMode.byGoal &&
                  viewState.selectedGoalId != null)
                ElevatedButton.icon(
                  onPressed: () => _addTask(
                    context,
                    ref,
                    viewState.selectedGoalId!,
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('タスクを追加'),
                ),
              // 読書スケジュール追加ボタン
              if (viewState.mode == GanttViewMode.allBooks)
                ElevatedButton.icon(
                  onPressed: () => _addBookSchedule(context, ref),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('読書スケジュールを追加'),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // ガントチャート
          Expanded(
            child: tasksAsync.when(
              data: (tasks) {
                if (tasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.view_timeline_outlined,
                          size: 64,
                          color: colors.textMuted,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'タスクがありません',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '目標を選択してタスクを追加しましょう',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  );
                }

                // GoalID→カラーのマップを構築
                final goalColors = <String, Color>{};
                final goalsData = goalsAsync.valueOrNull ?? [];
                for (final goal in goalsData) {
                  goalColors[goal.id] = _parseColor(goal.color);
                }

                return GanttChart(
                  tasks: tasks,
                  goalColors: goalColors,
                  onTaskTap: (task) {
                    if (task.goalId == bookGanttGoalId) {
                      _editBookSchedule(context, ref, task);
                    } else {
                      _editTask(context, ref, task);
                    }
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text('エラーが発生しました: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hex) {
    final code = hex.replaceFirst('#', '');
    return Color(int.parse('FF$code', radix: 16));
  }

  Future<void> _addTask(
    BuildContext context,
    WidgetRef ref,
    String goalId,
  ) async {
    // 体験版: タスク数の制限チェック
    final allTasks = ref.read(ganttTasksProvider).valueOrNull ?? [];
    final tasksForGoal = allTasks.where((t) => t.goalId == goalId).length;
    final level = ref.read(unlockLevelProvider);
    if (!canAddTask(
        currentTaskCountForGoal: tasksForGoal, unlockLevel: level)) {
      await showTrialLimitDialog(
        context,
        itemName: 'タスク（この目標）',
        currentCount: tasksForGoal,
        maxCount: maxTasksPerGoal(level),
        feedbackService: ref.read(feedbackServiceProvider),
      );
      return;
    }

    final books = await ref.read(bookServiceProvider).getAllBooks();
    if (!context.mounted) return;

    final result = await showTaskDialog(context, books: books);
    if (result == null) return;

    await ref.read(taskServiceProvider).createTask(
          goalId: goalId,
          title: result.title,
          startDate: result.startDate,
          endDate: result.endDate,
          memo: result.memo,
          bookId: result.bookId,
        );
    ref.invalidate(ganttTasksProvider);
  }

  Future<void> _editTask(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) async {
    final books = await ref.read(bookServiceProvider).getAllBooks();
    if (!context.mounted) return;

    final result = await showTaskDialog(
      context,
      task: task,
      books: books,
      studyLogService: ref.read(studyLogServiceProvider),
    );
    if (result == null) return;

    if (result.deleteRequested) {
      if (!context.mounted) return;
      final confirmed = await _confirmDelete(context, task.title);
      if (confirmed != true) return;
      await ref.read(taskServiceProvider).deleteTask(task.id);
      ref.invalidate(ganttTasksProvider);
      return;
    }

    await ref.read(taskServiceProvider).updateTask(
          taskId: task.id,
          title: result.title,
          startDate: result.startDate,
          endDate: result.endDate,
          progress: result.progress,
          memo: result.memo,
          bookId: result.bookId,
        );
    ref.invalidate(ganttTasksProvider);
  }

  Future<void> _addBookSchedule(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final ganttService = ref.read(bookGanttServiceProvider);
    final unscheduled = await ganttService.getUnscheduledBooks();
    if (!context.mounted) return;

    final result = await showBookScheduleDialog(
      context,
      unscheduledBooks: unscheduled,
    );
    if (result == null) return;

    if (result.bookSource == '__new__') {
      await ganttService.createBookWithSchedule(
        title: result.title,
        startDate: result.startDate,
        endDate: result.endDate,
      );
    } else if (result.bookSource != null) {
      await ganttService.setBookSchedule(
        bookId: result.bookSource!,
        startDate: result.startDate,
        endDate: result.endDate,
      );
    }
    ref.invalidate(ganttTasksProvider);
  }

  Future<void> _editBookSchedule(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) async {
    final ganttService = ref.read(bookGanttServiceProvider);
    final bookService = ref.read(bookServiceProvider);
    final bookId = task.bookId.isNotEmpty ? task.bookId : task.id;
    final book = await bookService.getBook(bookId);
    if (book == null || !context.mounted) return;

    final result = await showBookScheduleDialog(context, book: book);
    if (result == null) return;

    if (result.deleteRequested) {
      await ganttService.clearBookSchedule(bookId);
    } else {
      await ganttService.updateBookSchedule(
        bookId: bookId,
        title: result.title,
        startDate: result.startDate,
        endDate: result.endDate,
        progress: result.progress,
      );
    }
    ref.invalidate(ganttTasksProvider);
  }

  Future<bool?> _confirmDelete(BuildContext context, String title) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('タスクを削除'),
        content: Text('「$title」を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }
}

/// 表示モードセレクタ.
class _ViewSelector extends StatelessWidget {
  const _ViewSelector({
    required this.viewState,
    required this.goals,
    required this.onChanged,
  });

  final GanttViewState viewState;
  final List<Goal> goals;
  final void Function(GanttViewMode mode, String? goalId) onChanged;

  @override
  Widget build(BuildContext context) {
    // ドロップダウンのアイテムを構築
    final items = <DropdownMenuItem<String>>[
      const DropdownMenuItem(
        value: 'all',
        child: Text('全タスク'),
      ),
      const DropdownMenuItem(
        value: 'books',
        child: Text('書籍タスク'),
      ),
      ...goals.map(
        (g) => DropdownMenuItem(
          value: 'goal:${g.id}',
          child: Text(g.what),
        ),
      ),
    ];

    // 現在の選択値
    String currentValue;
    switch (viewState.mode) {
      case GanttViewMode.allTasks:
        currentValue = 'all';
      case GanttViewMode.allBooks:
        currentValue = 'books';
      case GanttViewMode.byGoal:
        currentValue = 'goal:${viewState.selectedGoalId}';
    }

    return DropdownButton<String>(
      value: currentValue,
      items: items,
      onChanged: (value) {
        if (value == null) return;
        if (value == 'all') {
          onChanged(GanttViewMode.allTasks, null);
        } else if (value == 'books') {
          onChanged(GanttViewMode.allBooks, null);
        } else if (value.startsWith('goal:')) {
          onChanged(GanttViewMode.byGoal, value.substring(5));
        }
      },
    );
  }
}
