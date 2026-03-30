/// ガントチャートページ.
///
/// 目標別/書籍別のタスクをガントチャートで表示する.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dialogs/book_schedule_dialog.dart';
import '../l10n/app_labels.dart';
import '../dialogs/reading_log_dialog.dart';
import '../dialogs/task_dialog.dart';
import '../dialogs/task_discovery_dialog.dart';
import '../dialogs/trial_limit_dialog.dart';
import '../models/goal.dart';
import '../models/task.dart' show Task, bookGanttGoalId;
import '../services/book_gantt_service.dart' show bookGanttColor;
import '../services/study_stats_types.dart' show GanttMilestone;
import '../providers/dashboard_providers.dart';
import '../providers/gantt_providers.dart';
import '../providers/service_providers.dart';
import '../services/file_save_service.dart' as file_io;
import '../services/task_study_log_logic.dart';
import '../services/trial_limit_service.dart';
import '../services/tutorial_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gantt/gantt_chart.dart';
import '../widgets/premium/premium_gate.dart';
import '../widgets/tutorial/tutorial_banner.dart';
import '../widgets/tutorial/tutorial_target_keys.dart';

/// ガントチャートページ.
class GanttPage extends ConsumerStatefulWidget {
  /// GanttPageを作成する.
  const GanttPage({super.key});

  @override
  ConsumerState<GanttPage> createState() => _GanttPageState();
}

class _GanttPageState extends ConsumerState<GanttPage> {
  final _chartKey = GlobalKey<GanttChartState>();

  @override
  Widget build(BuildContext context) {
    // プレミアム機能: Web体験版ではゲートを表示
    if (!canUseGanttChart) {
      return const PremiumGate(
        featureName: AppLabels.pageSchedule,
        featureIcon: Icons.view_timeline_outlined,
        premiumPoints: [
          AppLabels.ganttPremiumPoint1,
          AppLabels.ganttPremiumPoint2,
          AppLabels.ganttPremiumPoint3,
          AppLabels.ganttPremiumPoint4,
        ],
      );
    }

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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
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
              // タスク追加ボタン（目標別・全タスク表示時）
              if (viewState.mode == GanttViewMode.allTasks ||
                  (viewState.mode == GanttViewMode.byGoal &&
                      viewState.selectedGoalId != null)) ...[
                OutlinedButton.icon(
                  onPressed: () => _openTaskDiscovery(context, ref),
                  icon: const Icon(Icons.lightbulb_outline, size: 18),
                  label: const Text(AppLabels.ganttDiscoveryGuide),
                ),
                ElevatedButton.icon(
                  key: TutorialTargetKeys.addTaskButton,
                  onPressed: () => _addTask(
                    context,
                    ref,
                    viewState.selectedGoalId ?? '',
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text(AppLabels.taskAdd),
                ),
              ],
              // 読書スケジュール追加ボタン
              if (viewState.mode == GanttViewMode.allBooks)
                ElevatedButton.icon(
                  onPressed: () => _addBookSchedule(context, ref),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text(AppLabels.scheduleAddButton),
                ),
              // エクスポート
              IconButton(
                icon: const Icon(Icons.file_download_outlined),
                tooltip: AppLabels.tooltipExport,
                onPressed: () => _showExportMenu(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 日付範囲セレクタ + ジャンプ
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // 日付範囲セレクタ
              SegmentedButton<GanttDateRange>(
                segments: [
                  for (final range in GanttDateRange.values)
                    ButtonSegment(
                      value: range,
                      label: Text(range.label),
                    ),
                ],
                selected: {viewState.dateRange},
                onSelectionChanged: (selected) {
                  ref
                      .read(ganttViewStateProvider.notifier)
                      .setDateRange(selected.first);
                },
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  textStyle: WidgetStatePropertyAll(
                    theme.textTheme.labelSmall,
                  ),
                ),
              ),
              // 今日ボタン
              OutlinedButton.icon(
                onPressed: () =>
                    _chartKey.currentState?.scrollToDate(DateTime.now()),
                icon: const Icon(Icons.today, size: 16),
                label: const Text(AppLabels.ganttToday),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
              // 日付ジャンプ
              OutlinedButton.icon(
                onPressed: () => _pickJumpDate(context),
                icon: const Icon(Icons.calendar_month, size: 16),
                label: const Text(AppLabels.ganttJumpToDate),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

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
                          AppLabels.ganttEmptyTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLabels.ganttEmptySubtitle,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  );
                }

                // GoalID→カラー / GoalID→名前のマップを構築
                final goalColors = <String, Color>{};
                final goalNames = <String, String>{};
                final goalsData = goalsAsync.valueOrNull ?? [];
                for (final goal in goalsData) {
                  goalColors[goal.id] = _parseColor(goal.color);
                  goalNames[goal.id] = goal.what;
                }
                // 書籍タスク用
                goalColors[bookGanttGoalId] = _parseColor(bookGanttColor);
                goalNames[bookGanttGoalId] = AppLabels.ganttBookLabel;
                // 独立タスク用
                goalColors[''] = _parseColor('#94E2D5');
                goalNames[''] = AppLabels.ganttIndependentTask;

                // マイルストーン構築（日付指定の目標）
                final milestones = <GanttMilestone>[];
                for (final goal in goalsData) {
                  final targetDate = goal.getTargetDate();
                  if (targetDate != null) {
                    milestones.add(GanttMilestone(
                      label: goal.what,
                      date: targetDate,
                      color: goal.color,
                    ));
                  }
                }

                return GanttChart(
                  key: _chartKey,
                  tasks: tasks,
                  goalColors: goalColors,
                  goalNames: goalNames,
                  milestones: milestones,
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
                child: Text(AppLabels.errorWithDetail('$error')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickJumpDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2050),
    );
    if (picked != null) {
      _chartKey.currentState?.scrollToDate(picked);
    }
  }

  Color _parseColor(String hex) {
    final code = hex.replaceFirst('#', '');
    return Color(int.parse('FF$code', radix: 16));
  }

  Future<void> _openTaskDiscovery(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final goals = await ref.read(goalServiceProvider).getAllGoals();
    final dreamService = ref.read(dreamServiceProvider);

    // GoalID → DreamCategory のマップを構築
    final categoryMap = <String, String>{};
    for (final goal in goals) {
      if (goal.dreamId.isNotEmpty) {
        final dream = await dreamService.getDream(goal.dreamId);
        if (dream != null) {
          categoryMap[goal.id] = dream.category;
        }
      }
    }

    if (!context.mounted) return;
    final result = await showTaskDiscoveryDialog(
      context,
      goals: goals,
      goalDreamCategoryMap: categoryMap,
    );
    if (result == null) return;

    await ref.read(taskServiceProvider).createTask(
          goalId: result.goalId,
          title: result.title,
          startDate: result.startDate,
          endDate: result.endDate,
        );
    ref.invalidate(ganttTasksProvider);
  }

  Future<void> _addTask(
    BuildContext context,
    WidgetRef ref,
    String goalId,
  ) async {
    // チュートリアル中はタスク制限をバイパス
    final tutorialState = ref.read(tutorialStateProvider);
    final isTutorial = tutorialState.isActive &&
        tutorialState.step == TutorialStep.addTask;

    // 体験版: タスク数の制限チェック
    if (!isTutorial && goalId.isNotEmpty) {
      final allTasks = await ref.read(ganttTasksProvider.future);
      final tasksForGoal = allTasks.where((t) => t.goalId == goalId).length;
      final level = ref.read(unlockLevelProvider);
      if (!canAddTask(
          currentTaskCountForGoal: tasksForGoal, unlockLevel: level)) {
        if (!context.mounted) return;
        await showTrialLimitDialog(
          context,
          itemName: AppLabels.ganttTrialLimitTask(tasksForGoal),
          currentCount: tasksForGoal,
          maxCount: maxTasksPerGoal(level),
          feedbackService: ref.read(feedbackServiceProvider),
        );
        ref.invalidate(feedbackServiceProvider);
        return;
      }
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

    // チュートリアル: タスク追加後にステップを進める
    if (isTutorial) {
      await ref.read(tutorialStateProvider.notifier).advanceStep();
    }
    ref.invalidate(ganttTasksProvider);
  }

  Future<void> _editTask(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) async {
    while (true) {
      if (!context.mounted) return;
      final action = await showDialog<String>(
        context: context,
        builder: (context) => SimpleDialog(
          title: Text(task.title),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop('edit'),
              child: const ListTile(
                leading: Icon(Icons.edit_outlined),
                title: Text(AppLabels.ganttEditTaskOption),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop('log'),
              child: const ListTile(
                leading: Icon(Icons.timer_outlined),
                title: Text(AppLabels.ganttRecordActivity),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      );

      if (action == null || !context.mounted) return;

      if (action == 'log') {
        final logic = TaskStudyLogLogic(
          studyLogService: ref.read(studyLogServiceProvider),
          taskId: task.id,
          taskName: task.title,
        );
        final result = await showReadingLogDialog(
          context,
          logic: logic,
          bookTitle: task.title,
          dialogTitle: AppLabels.ganttActivityTitle(task.title),
        );
        ref.invalidate(allLogsProvider);
        if (result != 'back') return;
        continue; // 選択肢画面に戻る
      }

      // タスク編集
      final books = await ref.read(bookServiceProvider).getAllBooks();
      final goals = await ref.read(goalServiceProvider).getAllGoals();
      if (!context.mounted) return;

      final result = await showTaskDialog(
        context,
        task: task,
        books: books,
        goals: goals,
      );
      if (result == null) {
        continue; // 戻る → 選択肢画面に戻る
      }
      if (result.closeRequested) {
        return; // 閉じる → 完全に閉じる
      }

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
            goalId: result.goalId,
          );
      ref.invalidate(ganttTasksProvider);
      return;
    }
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
    final bookService = ref.read(bookServiceProvider);
    final bookId = task.bookId.isNotEmpty ? task.bookId : task.id;
    final book = await bookService.getBook(bookId);
    if (book == null || !context.mounted) return;

    while (true) {
      if (!context.mounted) return;
      final action = await showDialog<String>(
        context: context,
        builder: (context) => SimpleDialog(
          title: Text('📖 ${book.title}'),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop('schedule'),
              child: const ListTile(
                leading: Icon(Icons.calendar_month_outlined),
                title: Text(AppLabels.ganttEditScheduleOption),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop('reading_log'),
              child: const ListTile(
                leading: Icon(Icons.timer_outlined),
                title: Text(AppLabels.ganttRecordReading),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      );

      if (action == null || !context.mounted) return;

      if (action == 'reading_log') {
        final logic = TaskStudyLogLogic(
          studyLogService: ref.read(studyLogServiceProvider),
          taskId: bookLogTaskId(bookId),
          taskName: '📖 ${book.title}',
        );
        final result = await showReadingLogDialog(
          context,
          logic: logic,
          bookTitle: book.title,
        );
        ref.invalidate(allLogsProvider);
        if (result != 'back') return;
        continue; // 選択肢画面に戻る
      }

      // スケジュール編集
      final ganttService = ref.read(bookGanttServiceProvider);
      final result = await showBookScheduleDialog(context, book: book);
      if (result == null) {
        continue; // 選択肢画面に戻る
      }

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
      return;
    }
  }

  Future<void> _showExportMenu(BuildContext context, WidgetRef ref) async {
    final tasks = ref.read(ganttTasksProvider).valueOrNull ?? [];
    if (tasks.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppLabels.exportNoTasks)),
      );
      return;
    }

    final format = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text(AppLabels.exportSelectFormat),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'html'),
            child: const ListTile(
              leading: Icon(Icons.language),
              title: Text('HTML'),
              subtitle: Text(AppLabels.exportHtmlDesc),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'excel'),
            child: const ListTile(
              leading: Icon(Icons.table_chart),
              title: Text('Excel (.xlsx)'),
              subtitle: Text(AppLabels.exportExcelDesc),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'csv'),
            child: const ListTile(
              leading: Icon(Icons.grid_on),
              title: Text('CSV'),
              subtitle: Text(AppLabels.exportCsvDesc),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );

    if (format == null || !context.mounted) return;

    // 画面に表示されているタスクに関連する目標のみに絞る
    final allGoals = await ref.read(goalServiceProvider).getAllGoals();
    final visibleGoalIds = tasks.map((t) => t.goalId).toSet();
    final goals = allGoals.where((g) => visibleGoalIds.contains(g.id)).toList();
    final exportService = ref.read(ganttExcelExportServiceProvider);

    try {
      final result = exportService.exportAs(
        tasks: tasks,
        goals: goals,
        format: format,
      );
      final ext = result.fileName.split('.').last;
      final saved = await file_io.saveFile(
        bytes: result.bytes,
        fileName: result.fileName,
        mimeType: result.mimeType ?? 'application/octet-stream',
        allowedExtensions: [ext],
      );
      if (!context.mounted) return;
      if (saved) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLabels.exportSuccess(result.fileName))),
        );
      }
    } on Object catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLabels.exportError('$e'))),
      );
    }
  }


  Future<bool?> _confirmDelete(BuildContext context, String title) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppLabels.taskDialogDelete),
        content: Text(AppLabels.ganttDeleteConfirm(title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppLabels.btnCancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(AppLabels.btnDelete),
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
        child: Text(AppLabels.ganttViewAllTasks),
      ),
      const DropdownMenuItem(
        value: 'books',
        child: Text(AppLabels.ganttViewBooks),
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
      key: TutorialTargetKeys.ganttDropdown,
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
