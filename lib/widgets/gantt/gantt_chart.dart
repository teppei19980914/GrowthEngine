/// ガントチャートウィジェット.
///
/// CustomPainterでタスクバー、タイムライン、今日線を描画する.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../models/task.dart';
import '../../services/gantt_calculator.dart';
import '../../services/study_stats_types.dart';
import '../../theme/app_theme.dart';

/// タスクバーがタップされた時のコールバック.
typedef OnTaskTap = void Function(Task task);

/// ガントチャートウィジェット.
class GanttChart extends StatefulWidget {
  /// GanttChartを作成する.
  const GanttChart({
    required this.tasks,
    required this.goalColors,
    this.milestones = const [],
    this.onTaskTap,
    super.key,
  });

  /// 表示するタスク一覧.
  final List<Task> tasks;

  /// GoalID→カラーのマップ.
  final Map<String, Color> goalColors;

  /// マイルストーン一覧（夢・目標の期限）.
  final List<GanttMilestone> milestones;

  /// タスクタップ時のコールバック.
  final OnTaskTap? onTaskTap;

  @override
  State<GanttChart> createState() => _GanttChartState();
}

class _GanttChartState extends State<GanttChart> {
  final _calculator = GanttCalculator();
  late TimelineRange _timeline;
  int? _hoveredRow;

  @override
  void initState() {
    super.initState();
    _updateTimeline();
  }

  @override
  void didUpdateWidget(GanttChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tasks != widget.tasks ||
        oldWidget.milestones != widget.milestones) {
      _updateTimeline();
    }
  }

  void _updateTimeline() {
    final dates = widget.tasks
        .map((t) => (t.startDate, t.endDate))
        .toList();
    // マイルストーン日付もタイムライン計算に含める
    for (final m in widget.milestones) {
      dates.add((m.date, m.date));
    }
    _timeline = _calculator.calculateTimeline(dates);
  }

  int? _hitTestRow(Offset localPosition) {
    final y = localPosition.dy - _calculator.headerHeight;
    if (y < 0) return null;
    final row = y ~/ _calculator.rowHeight;
    if (row >= widget.tasks.length) return null;
    return row;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final sceneWidth = _calculator.calculateSceneWidth(_timeline);
    final sceneHeight = _calculator.calculateSceneHeight(widget.tasks.length);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: MouseRegion(
              onHover: (event) {
                final row = _hitTestRow(event.localPosition);
                if (row != _hoveredRow) {
                  setState(() => _hoveredRow = row);
                }
              },
              onExit: (_) {
                if (_hoveredRow != null) {
                  setState(() => _hoveredRow = null);
                }
              },
              child: GestureDetector(
                onTapUp: (details) {
                  final row = _hitTestRow(details.localPosition);
                  if (row != null && widget.onTaskTap != null) {
                    widget.onTaskTap!(widget.tasks[row]);
                  }
                },
                child: CustomPaint(
                  size: Size(sceneWidth, sceneHeight),
                  painter: _GanttPainter(
                    tasks: widget.tasks,
                    goalColors: widget.goalColors,
                    milestones: widget.milestones,
                    calculator: _calculator,
                    timeline: _timeline,
                    hoveredRow: _hoveredRow,
                    bgColor: colors.bgPrimary,
                    gridColor: colors.border,
                    textColor: colors.textPrimary,
                    mutedColor: colors.textMuted,
                    todayColor: colors.error,
                    hoverColor: colors.bgHover,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GanttPainter extends CustomPainter {
  _GanttPainter({
    required this.tasks,
    required this.goalColors,
    required this.milestones,
    required this.calculator,
    required this.timeline,
    required this.hoveredRow,
    required this.bgColor,
    required this.gridColor,
    required this.textColor,
    required this.mutedColor,
    required this.todayColor,
    required this.hoverColor,
  });

  final List<Task> tasks;
  final Map<String, Color> goalColors;
  final List<GanttMilestone> milestones;
  final GanttCalculator calculator;
  final TimelineRange timeline;
  final int? hoveredRow;
  final Color bgColor;
  final Color gridColor;
  final Color textColor;
  final Color mutedColor;
  final Color todayColor;
  final Color hoverColor;

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);
    _drawHeader(canvas, size);
    _drawMilestones(canvas, size);
    _drawTodayLine(canvas, size);
    _drawBars(canvas);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor.withAlpha(40)
      ..strokeWidth = 0.5;

    // 水平線
    for (var i = 0; i <= tasks.length; i++) {
      final y =
          calculator.headerHeight + i * calculator.rowHeight.toDouble();
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // ホバー行のハイライト
    if (hoveredRow != null && hoveredRow! < tasks.length) {
      final y = calculator.headerHeight +
          hoveredRow! * calculator.rowHeight.toDouble();
      canvas.drawRect(
        Rect.fromLTWH(0, y, size.width, calculator.rowHeight.toDouble()),
        Paint()..color = hoverColor.withAlpha(60),
      );
    }

    // 垂直線（日付）
    final dayPositions = calculator.getDayPositions(timeline);
    for (final (date, x) in dayPositions) {
      final isWeekend = date.weekday == DateTime.saturday ||
          date.weekday == DateTime.sunday;
      if (isWeekend) {
        canvas.drawRect(
          Rect.fromLTWH(
            x,
            calculator.headerHeight.toDouble(),
            calculator.pixelsPerDay,
            size.height - calculator.headerHeight,
          ),
          Paint()..color = gridColor.withAlpha(15),
        );
      }
      canvas.drawLine(
        Offset(x, calculator.headerHeight.toDouble()),
        Offset(x, size.height),
        paint,
      );
    }
  }

  void _drawHeader(Canvas canvas, Size size) {
    // ヘッダー背景
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, calculator.headerHeight.toDouble()),
      Paint()..color = bgColor,
    );

    // 月ラベル
    final monthBoundaries = calculator.getMonthBoundaries(timeline);
    final monthFormat = DateFormat('yyyy/MM');
    for (final (date, x) in monthBoundaries) {
      _drawText(
        canvas,
        monthFormat.format(date),
        Offset(x + 4, 8),
        textColor,
        12,
        fontWeight: FontWeight.w600,
      );

      // 月の区切り線
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, calculator.headerHeight.toDouble()),
        Paint()
          ..color = gridColor
          ..strokeWidth = 1,
      );
    }

    // 日付ラベル
    final dayPositions = calculator.getDayPositions(timeline);
    for (final (date, x) in dayPositions) {
      _drawText(
        canvas,
        '${date.day}',
        Offset(x + calculator.pixelsPerDay / 2 - 6, 32),
        mutedColor,
        10,
      );

      // 曜日
      const weekDays = ['月', '火', '水', '木', '金', '土', '日'];
      final weekDay = weekDays[date.weekday - 1];
      final isWeekend = date.weekday == DateTime.saturday ||
          date.weekday == DateTime.sunday;
      _drawText(
        canvas,
        weekDay,
        Offset(x + calculator.pixelsPerDay / 2 - 5, 48),
        isWeekend ? todayColor.withAlpha(150) : mutedColor,
        9,
      );
    }

    // ヘッダー下線
    canvas.drawLine(
      Offset(0, calculator.headerHeight.toDouble()),
      Offset(size.width, calculator.headerHeight.toDouble()),
      Paint()
        ..color = gridColor
        ..strokeWidth = 1,
    );
  }

  void _drawTodayLine(Canvas canvas, Size size) {
    final todayX = calculator.calculateTodayX(timeline);
    canvas.drawLine(
      Offset(todayX, 0),
      Offset(todayX, size.height),
      Paint()
        ..color = todayColor
        ..strokeWidth = 2,
    );
  }

  void _drawBars(Canvas canvas) {
    for (var i = 0; i < tasks.length; i++) {
      final task = tasks[i];
      final geo = calculator.calculateBarGeometry(
        task.startDate,
        task.endDate,
        task.progress,
        timeline,
      );
      final y = calculator.calculateBarY(i);
      final barColor =
          goalColors[task.goalId] ?? const Color(0xFF89B4FA);

      // 背景バー
      final bgRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(geo.x, y, geo.width, calculator.barHeight.toDouble()),
        const Radius.circular(4),
      );
      canvas.drawRRect(bgRect, Paint()..color = barColor.withAlpha(60));

      // 進捗バー
      if (geo.progressWidth > 0) {
        final progressRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            geo.x,
            y,
            geo.progressWidth,
            calculator.barHeight.toDouble(),
          ),
          const Radius.circular(4),
        );
        canvas.drawRRect(progressRect, Paint()..color = barColor);
      }

      // タスク名
      _drawText(
        canvas,
        '${task.title} (${task.progress}%)',
        Offset(geo.x + 6, y + 5),
        textColor,
        11,
      );
    }
  }

  void _drawMilestones(Canvas canvas, Size size) {
    for (final milestone in milestones) {
      final x = calculator.dateToX(milestone.date, timeline) +
          calculator.pixelsPerDay / 2;
      final colorHex = milestone.color.replaceFirst('#', '');
      final color = Color(int.parse('FF$colorHex', radix: 16));

      // 縦の破線
      final linePaint = Paint()
        ..color = color.withAlpha(100)
        ..strokeWidth = 1.5;
      const dashHeight = 6.0;
      const gapHeight = 4.0;
      var y = calculator.headerHeight.toDouble();
      while (y < size.height) {
        canvas.drawLine(
          Offset(x, y),
          Offset(x, (y + dashHeight).clamp(0, size.height)),
          linePaint,
        );
        y += dashHeight + gapHeight;
      }

      // ダイヤモンドマーカー（ヘッダー下部）
      const diamondSize = 8.0;
      final markerY = calculator.headerHeight.toDouble() - diamondSize - 4;
      final path = Path()
        ..moveTo(x, markerY - diamondSize)
        ..lineTo(x + diamondSize, markerY)
        ..lineTo(x, markerY + diamondSize)
        ..lineTo(x - diamondSize, markerY)
        ..close();
      canvas.drawPath(path, Paint()..color = color);

      // ラベル
      _drawText(
        canvas,
        milestone.label,
        Offset(x + diamondSize + 2, markerY - 6),
        color,
        9,
        fontWeight: FontWeight.w600,
      );
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    Color color,
    double fontSize, {
    FontWeight fontWeight = FontWeight.normal,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(_GanttPainter oldDelegate) {
    return oldDelegate.tasks != tasks ||
        oldDelegate.milestones != milestones ||
        oldDelegate.hoveredRow != hoveredRow ||
        oldDelegate.timeline != timeline;
  }
}
