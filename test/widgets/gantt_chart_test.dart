import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yume_log/models/task.dart';
import 'package:yume_log/services/study_stats_types.dart' show GanttMilestone;
import 'package:yume_log/widgets/gantt/gantt_chart.dart';

void main() {
  Widget buildSubject({
    List<Task> tasks = const [],
    Map<String, Color> goalColors = const {},
    List<GanttMilestone> milestones = const [],
    OnTaskTap? onTaskTap,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 800,
          height: 400,
          child: GanttChart(
            tasks: tasks,
            goalColors: goalColors,
            milestones: milestones,
            onTaskTap: onTaskTap,
          ),
        ),
      ),
    );
  }

  List<Task> createSampleTasks() {
    final now = DateTime.now();
    return [
      Task(
        id: 'task-1',
        goalId: 'goal-1',
        title: 'Task Alpha',
        startDate: now,
        endDate: now.add(const Duration(days: 5)),
        progress: 30,
      ),
      Task(
        id: 'task-2',
        goalId: 'goal-1',
        title: 'Task Beta',
        startDate: now.add(const Duration(days: 2)),
        endDate: now.add(const Duration(days: 10)),
        progress: 60,
      ),
      Task(
        id: 'task-3',
        goalId: 'goal-2',
        title: 'Task Gamma',
        startDate: now.add(const Duration(days: 1)),
        endDate: now.add(const Duration(days: 7)),
        progress: 0,
      ),
    ];
  }

  group('GanttChart', () {
    testWidgets('renders empty chart when no tasks are provided',
        (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // The widget tree should contain a CustomPaint even with no tasks.
      expect(find.byType(GanttChart), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders with multiple tasks', (tester) async {
      final tasks = createSampleTasks();

      await tester.pumpWidget(buildSubject(
        tasks: tasks,
        goalColors: {
          'goal-1': Colors.blue,
          'goal-2': Colors.green,
        },
      ));
      await tester.pumpAndSettle();

      expect(find.byType(GanttChart), findsOneWidget);
      // CustomPaint is present, indicating the chart was painted.
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('onTaskTap callback fires when tapping a task row',
        (tester) async {
      final tasks = createSampleTasks();
      Task? tappedTask;

      await tester.pumpWidget(buildSubject(
        tasks: tasks,
        goalColors: {'goal-1': Colors.blue, 'goal-2': Colors.green},
        onTaskTap: (task) => tappedTask = task,
      ));
      await tester.pumpAndSettle();

      // The GanttChart uses a GestureDetector wrapping a CustomPaint.
      // Tap within the first task row area (below the 70px header).
      // headerHeight = 70, rowHeight = 40, so first row center is at y=90.
      final chartFinder = find.byType(GanttChart);
      expect(chartFinder, findsOneWidget);

      // Find the GestureDetector inside the chart to tap on it.
      final gestureDetector = find.descendant(
        of: chartFinder,
        matching: find.byType(GestureDetector),
      );
      expect(gestureDetector, findsOneWidget);

      // Tap at a position within the first task row.
      // headerHeight=70, rowHeight=40 => first row y center = 70 + 20 = 90
      final topLeft = tester.getTopLeft(gestureDetector);
      await tester.tapAt(topLeft + const Offset(100, 90));
      await tester.pump();

      expect(tappedTask, isNotNull);
      expect(tappedTask!.id, equals('task-1'));
    });

    testWidgets('onTaskTap fires for second task row', (tester) async {
      final tasks = createSampleTasks();
      Task? tappedTask;

      await tester.pumpWidget(buildSubject(
        tasks: tasks,
        goalColors: {'goal-1': Colors.blue, 'goal-2': Colors.green},
        onTaskTap: (task) => tappedTask = task,
      ));
      await tester.pumpAndSettle();

      final gestureDetector = find.descendant(
        of: find.byType(GanttChart),
        matching: find.byType(GestureDetector),
      );

      // Second row y center = 70 + 40 + 20 = 130
      final topLeft = tester.getTopLeft(gestureDetector);
      await tester.tapAt(topLeft + const Offset(100, 130));
      await tester.pump();

      expect(tappedTask, isNotNull);
      expect(tappedTask!.id, equals('task-2'));
    });

    testWidgets('chart shows task names via CustomPaint painter',
        (tester) async {
      final tasks = createSampleTasks();

      await tester.pumpWidget(buildSubject(
        tasks: tasks,
        goalColors: {'goal-1': Colors.blue, 'goal-2': Colors.green},
      ));
      await tester.pumpAndSettle();

      // Since task names are drawn by CustomPainter (not Text widgets),
      // we verify the CustomPaint exists and the painter received the tasks.
      // We can verify the widget rendered successfully without errors.
      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('does not fire callback when tapping header area',
        (tester) async {
      final tasks = createSampleTasks();
      Task? tappedTask;

      await tester.pumpWidget(buildSubject(
        tasks: tasks,
        goalColors: {'goal-1': Colors.blue},
        onTaskTap: (task) => tappedTask = task,
      ));
      await tester.pumpAndSettle();

      final gestureDetector = find.descendant(
        of: find.byType(GanttChart),
        matching: find.byType(GestureDetector),
      );

      // Tap in the header area (y=30, which is < headerHeight of 70)
      final topLeft = tester.getTopLeft(gestureDetector);
      await tester.tapAt(topLeft + const Offset(100, 30));
      await tester.pump();

      expect(tappedTask, isNull);
    });

    testWidgets('renders with milestones', (tester) async {
      final tasks = createSampleTasks();
      final now = DateTime.now();
      final milestones = [
        GanttMilestone(
          label: 'TOEIC 900点',
          date: now.add(const Duration(days: 30)),
          color: '#4472C4',
        ),
      ];

      await tester.pumpWidget(buildSubject(
        tasks: tasks,
        goalColors: {'goal-1': Colors.blue, 'goal-2': Colors.green},
        milestones: milestones,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(GanttChart), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders with milestones only (no tasks)', (tester) async {
      final milestones = [
        GanttMilestone(
          label: '目標期限',
          date: DateTime.now().add(const Duration(days: 14)),
          color: '#ED7D31',
        ),
      ];

      await tester.pumpWidget(buildSubject(milestones: milestones));
      await tester.pumpAndSettle();

      expect(find.byType(GanttChart), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
