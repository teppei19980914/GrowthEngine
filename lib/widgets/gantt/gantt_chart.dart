/// ガントチャートウィジェット.
///
/// 左に固定の目標ラベル列、右にスクロール可能なタイムラインを表示する.
/// タスクは目標ごとにグルーピングされ、グループ帯で視覚的に分類される.
/// 目標列・ヘッダー行は常時固定表示される.
/// 横スクロールは共有ScrollControllerで同期し、指追従を実現する.
library;

import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HardwareKeyboard, LogicalKeyboardKey;
import 'package:intl/intl.dart' hide TextDirection;

import '../../l10n/app_labels.dart';
import '../../models/task.dart';
import '../../services/gantt_calculator.dart';
import '../../services/study_stats_types.dart';
import '../../theme/app_theme.dart';

/// タスクバーがタップされた時のコールバック.
typedef OnTaskTap = void Function(Task task);

/// 目標グループ情報（内部計算用）.
class _GoalGroup {
  _GoalGroup({
    required this.goalId,
    required this.name,
    required this.color,
    required this.startRow,
    required this.taskCount,
  });

  final String goalId;
  final String name;
  final Color color;
  final int startRow;
  final int taskCount;
  int get endRow => startRow + taskCount - 1;
}

/// ガントチャートウィジェット.
class GanttChart extends StatefulWidget {
  /// GanttChartを作成する.
  const GanttChart({
    required this.tasks,
    required this.goalColors,
    this.goalNames = const {},
    this.milestones = const [],
    this.onTaskTap,
    super.key,
  });

  /// 表示するタスク一覧（目標別にソート済みであること）.
  final List<Task> tasks;

  /// GoalID→カラーのマップ.
  final Map<String, Color> goalColors;

  /// GoalID→表示名のマップ.
  final Map<String, String> goalNames;

  /// マイルストーン一覧（夢・目標の期限）.
  final List<GanttMilestone> milestones;

  /// タスクタップ時のコールバック.
  final OnTaskTap? onTaskTap;

  @override
  State<GanttChart> createState() => GanttChartState();
}

/// GanttChartの外部操作インターフェース.
///
/// [GlobalKey] 経由で [scrollToDate] を呼び出し、指定日付にスクロールできる.
class GanttChartState extends State<GanttChart> {
  final _calculator = GanttCalculator();
  late TimelineRange _timeline;
  late List<_GoalGroup> _groups;
  int? _hoveredRow;

  // 共有ScrollController方式: 横スクロール（ヘッダー・ボディ同期）
  final _horizontalController = ScrollController();
  // 共有ScrollController方式: 縦スクロール（左列・ボディ同期）
  final _verticalController = ScrollController();
  // ヘッダー横スクロールはbodyに追従する（手動同期）
  final _headerHorizontalController = ScrollController();
  // 左列縦スクロールはbodyに追従する（手動同期）
  final _labelVerticalController = ScrollController();

  static const double _labelColumnWidth = 140;

  @override
  void initState() {
    super.initState();
    _rebuild();
    _horizontalController.addListener(_syncHeaderHorizontal);
    _verticalController.addListener(_syncLabelVertical);
    _scrollToToday();
  }

  void _syncHeaderHorizontal() {
    if (_headerHorizontalController.hasClients &&
        _headerHorizontalController.offset != _horizontalController.offset) {
      _headerHorizontalController.jumpTo(_horizontalController.offset);
    }
  }

  void _syncLabelVertical() {
    if (_labelVerticalController.hasClients &&
        _labelVerticalController.offset != _verticalController.offset) {
      _labelVerticalController.jumpTo(_verticalController.offset);
    }
  }

  /// 指定日付の位置にスクロールする.
  void scrollToDate(DateTime date) {
    if (!mounted || !_horizontalController.hasClients) return;
    final targetX = _calculator.dateToX(
      DateTime(date.year, date.month, date.day),
      _timeline,
    );
    final viewWidth = (context.size?.width ?? 400) - _labelColumnWidth;
    final offset = (targetX - viewWidth / 3).clamp(
      0.0,
      _horizontalController.position.maxScrollExtent,
    );
    _horizontalController.animateTo(
      offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollToToday() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_horizontalController.hasClients) return;
      final todayX = _calculator.calculateTodayX(_timeline);
      final viewWidth = (context.size?.width ?? 400) - _labelColumnWidth;
      final targetOffset = (todayX - viewWidth / 3).clamp(
        0.0,
        _horizontalController.position.maxScrollExtent,
      );
      _horizontalController.jumpTo(targetOffset);
    });
  }

  @override
  void dispose() {
    _horizontalController.removeListener(_syncHeaderHorizontal);
    _verticalController.removeListener(_syncLabelVertical);
    _horizontalController.dispose();
    _verticalController.dispose();
    _headerHorizontalController.dispose();
    _labelVerticalController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(GanttChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tasks != widget.tasks ||
        oldWidget.milestones != widget.milestones ||
        oldWidget.goalNames != widget.goalNames) {
      _rebuild();
    }
  }

  void _rebuild() {
    // タイムライン範囲はタスクの開始日〜終了日のみで決定する.
    // マイルストーンは範囲内にあれば表示されるが、範囲を引き延ばさない.
    final dates = widget.tasks
        .map((t) => (t.startDate, t.endDate))
        .toList();
    _timeline = _calculator.calculateTimeline(dates);
    _groups = _buildGroups();
  }

  List<_GoalGroup> _buildGroups() {
    final groups = <_GoalGroup>[];
    if (widget.tasks.isEmpty) return groups;

    var currentGoalId = widget.tasks.first.goalId;
    var startRow = 0;
    var count = 0;

    for (var i = 0; i < widget.tasks.length; i++) {
      if (widget.tasks[i].goalId != currentGoalId) {
        groups.add(_GoalGroup(
          goalId: currentGoalId,
          name: _goalName(currentGoalId),
          color: widget.goalColors[currentGoalId] ??
              const Color(0xFF89B4FA),
          startRow: startRow,
          taskCount: count,
        ));
        currentGoalId = widget.tasks[i].goalId;
        startRow = i;
        count = 0;
      }
      count++;
    }
    groups.add(_GoalGroup(
      goalId: currentGoalId,
      name: _goalName(currentGoalId),
      color: widget.goalColors[currentGoalId] ??
          const Color(0xFF89B4FA),
      startRow: startRow,
      taskCount: count,
    ));
    return groups;
  }

  String _goalName(String goalId) {
    if (widget.goalNames.containsKey(goalId)) {
      return widget.goalNames[goalId]!;
    }
    if (goalId.isEmpty) return AppLabels.ganttIndependentTask;
    return goalId;
  }

  int? _hitTestRow(Offset localPosition) {
    final y = localPosition.dy;
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
    final bodyHeight =
        widget.tasks.length * _calculator.rowHeight.toDouble();
    final effectiveBodyHeight =
        math.max(bodyHeight, _calculator.rowHeight.toDouble());
    final headerH = _calculator.headerHeight.toDouble();

    return Column(
      children: [
        // ── ヘッダー行（縦方向に固定） ──
        SizedBox(
          height: headerH,
          child: Row(
            children: [
              // 左上: 目標ヘッダー（完全固定）
              _FixedLabelHeader(
                width: _labelColumnWidth,
                bgColor: colors.bgPrimary,
                gridColor: colors.border,
                textColor: colors.textPrimary,
              ),
              // 右上: タイムラインヘッダー（横スクロール追従）
              Expanded(
                child: IgnorePointer(
                  child: SingleChildScrollView(
                    controller: _headerHorizontalController,
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    child: RepaintBoundary(
                      child: CustomPaint(
                        size: Size(sceneWidth, headerH),
                        painter: _TimelineHeaderPainter(
                          calculator: _calculator,
                          timeline: _timeline,
                          milestones: widget.milestones,
                          bgColor: colors.bgPrimary,
                          gridColor: colors.border,
                          textColor: colors.textPrimary,
                          mutedColor: colors.textMuted,
                          todayColor: colors.error,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── ボディ行 ──
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 左列: 目標ラベル（縦スクロール追従、横は固定）
              SizedBox(
                width: _labelColumnWidth,
                child: IgnorePointer(
                  child: SingleChildScrollView(
                    controller: _labelVerticalController,
                    physics: const NeverScrollableScrollPhysics(),
                    child: RepaintBoundary(
                      child: CustomPaint(
                        size: Size(_labelColumnWidth, effectiveBodyHeight),
                        painter: _LabelBodyPainter(
                          groups: _groups,
                          tasks: widget.tasks,
                          calculator: _calculator,
                          taskCount: widget.tasks.length,
                          bgColor: colors.bgPrimary,
                          gridColor: colors.border,
                          textColor: colors.textPrimary,
                          hoveredRow: _hoveredRow,
                          hoverColor: colors.bgHover,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 右列: タイムラインボディ
              // マウスホイールは _onPointerSignal で横/縦を制御する.
              // タッチ操作はそれぞれの ScrollView が処理する.
              Expanded(
                child: Listener(
                  onPointerSignal: _onPointerSignal,
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context)
                        .copyWith(scrollbars: false),
                    child: SingleChildScrollView(
                      controller: _verticalController,
                      physics: const NeverScrollableScrollPhysics(),
                      child: SingleChildScrollView(
                        controller: _horizontalController,
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
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
                        behavior: HitTestBehavior.opaque,
                        onTapUp: (details) {
                          final row = _hitTestRow(details.localPosition);
                          if (row != null && widget.onTaskTap != null) {
                            widget.onTaskTap!(widget.tasks[row]);
                          }
                        },
                        onPanUpdate: (details) {
                          _applyPanDelta(-details.delta.dx, -details.delta.dy);
                        },
                        child: RepaintBoundary(
                          child: CustomPaint(
                            size: Size(sceneWidth, effectiveBodyHeight),
                            painter: _TimelineBodyPainter(
                              tasks: widget.tasks,
                              groups: _groups,
                              goalColors: widget.goalColors,
                              milestones: widget.milestones,
                              calculator: _calculator,
                              timeline: _timeline,
                              hoveredRow: _hoveredRow,
                              gridColor: colors.border,
                              textColor: colors.textPrimary,
                              todayColor: colors.error,
                              hoverColor: colors.bgHover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  ),
                ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// タッチ/ドラッグ操作によるスクロール.
  void _applyPanDelta(double dx, double dy) {
    if (_horizontalController.hasClients) {
      final hMax = _horizontalController.position.maxScrollExtent;
      _horizontalController.jumpTo(
        (_horizontalController.offset + dx).clamp(0.0, hMax),
      );
    }
    if (_verticalController.hasClients) {
      final vMax = _verticalController.position.maxScrollExtent;
      _verticalController.jumpTo(
        (_verticalController.offset + dy).clamp(0.0, vMax),
      );
    }
  }

  /// マウスホイールでのスクロール制御.
  ///
  /// マウスホイールでのスクロール制御.
  ///
  /// - 通常ホイール → 縦スクロール
  /// - Shift+ホイール → 横スクロール
  ///
  /// Web ブラウザは Shift+ホイールを横スクロールとして扱い、
  /// scrollDelta.dx にデルタを格納するため、dx も考慮する.
  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;

    final dy = event.scrollDelta.dy;
    final dx = event.scrollDelta.dx;

    final isShift = HardwareKeyboard.instance.logicalKeysPressed.any(
      (key) =>
          key == LogicalKeyboardKey.shiftLeft ||
          key == LogicalKeyboardKey.shiftRight,
    );

    // Shift+ホイール → 横スクロール（dy または dx のどちらにデルタが来ても対応）
    if (isShift || (dx != 0 && dy == 0)) {
      final delta = dx != 0 ? dx : dy;
      final current = _horizontalController.offset;
      final max = _horizontalController.position.maxScrollExtent;
      _horizontalController.jumpTo((current + delta).clamp(0.0, max));
      return;
    }

    // 通常ホイール → 縦スクロール
    if (dy != 0) {
      final current = _verticalController.offset;
      final max = _verticalController.position.maxScrollExtent;
      _verticalController.jumpTo((current + dy).clamp(0.0, max));
    }
  }
}

// ── 左上: 固定ヘッダーラベル ──────────────────────────────────

class _FixedLabelHeader extends StatelessWidget {
  const _FixedLabelHeader({
    required this.width,
    required this.bgColor,
    required this.gridColor,
    required this.textColor,
  });

  final double width;
  final Color bgColor;
  final Color gridColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          bottom: BorderSide(color: gridColor),
          right: BorderSide(color: gridColor),
        ),
      ),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        AppLabels.ganttHeaderGoal,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── 左列ボディ: 目標ラベル ────────────────────────────────────

class _LabelBodyPainter extends CustomPainter {
  _LabelBodyPainter({
    required this.groups,
    required this.tasks,
    required this.calculator,
    required this.taskCount,
    required this.bgColor,
    required this.gridColor,
    required this.textColor,
    required this.hoveredRow,
    required this.hoverColor,
  });

  final List<_GoalGroup> groups;
  final List<Task> tasks;
  final GanttCalculator calculator;
  final int taskCount;
  final Color bgColor;
  final Color gridColor;
  final Color textColor;
  final int? hoveredRow;
  final Color hoverColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rowH = calculator.rowHeight.toDouble();

    for (final group in groups) {
      final topY = group.startRow * rowH;
      final groupHeight = group.taskCount * rowH;

      // グループ背景帯
      canvas.drawRect(
        Rect.fromLTWH(0, topY, size.width, groupHeight),
        Paint()..color = group.color.withAlpha(12),
      );
      // 左カラーバー
      canvas.drawRect(
        Rect.fromLTWH(0, topY, 4, groupHeight),
        Paint()..color = group.color,
      );
      // グループ上境界線
      canvas.drawLine(
        Offset(0, topY), Offset(size.width, topY),
        Paint()..color = group.color.withAlpha(60)..strokeWidth = 1,
      );
      // 各行にタスク名を表示（先頭行は目標名+タスク名の2段表示）
      for (var r = group.startRow; r <= group.endRow; r++) {
        if (r >= tasks.length) continue;
        final y = r * rowH;

        if (r == group.startRow) {
          // 先頭行: 上段に目標名（小さく）、下段にタスク名
          _drawText(canvas, group.name,
              Offset(10, y + 1),
              group.color, 8,
              fontWeight: FontWeight.w600, maxWidth: size.width - 16);
          _drawText(canvas, tasks[r].title,
              Offset(10, y + 14),
              textColor, 9,
              maxWidth: size.width - 16);
        } else {
          // 2行目以降: タスク名のみ
          _drawText(canvas, tasks[r].title,
              Offset(10, y + 4),
              textColor, 9,
              maxWidth: size.width - 16);
        }
      }

      // ホバーハイライト
      if (hoveredRow != null &&
          hoveredRow! >= group.startRow &&
          hoveredRow! <= group.endRow) {
        canvas.drawRect(
          Rect.fromLTWH(0, hoveredRow! * rowH, size.width, rowH),
          Paint()..color = hoverColor.withAlpha(60),
        );
      }
    }

    // 最終下線
    if (groups.isNotEmpty) {
      final bottomY = (groups.last.endRow + 1) * rowH;
      canvas.drawLine(
        Offset(0, bottomY), Offset(size.width, bottomY),
        Paint()..color = gridColor.withAlpha(60)..strokeWidth = 1,
      );
    }
    // 右区切り線
    canvas.drawLine(
      Offset(size.width - 1, 0), Offset(size.width - 1, size.height),
      Paint()..color = gridColor..strokeWidth = 1,
    );
  }

  void _drawText(Canvas canvas, String text, Offset offset, Color color,
      double fontSize,
      {FontWeight fontWeight = FontWeight.normal, double? maxWidth}) {
    TextPainter(
      text: TextSpan(text: text, style: TextStyle(
          color: color, fontSize: fontSize, fontWeight: fontWeight)),
      textDirection: TextDirection.ltr, maxLines: 1, ellipsis: '...',
    )..layout(maxWidth: maxWidth ?? double.infinity)..paint(canvas, offset);
  }

  @override
  bool shouldRepaint(_LabelBodyPainter old) =>
      old.groups != groups || old.tasks != tasks ||
      old.hoveredRow != hoveredRow;
}

// ── 右上: タイムラインヘッダー ──────────────────────────────────

class _TimelineHeaderPainter extends CustomPainter {
  _TimelineHeaderPainter({
    required this.calculator,
    required this.timeline,
    required this.milestones,
    required this.bgColor,
    required this.gridColor,
    required this.textColor,
    required this.mutedColor,
    required this.todayColor,
  }) : _todayFillPaint = Paint()..color = todayColor.withAlpha(25);

  final GanttCalculator calculator;
  final TimelineRange timeline;
  final List<GanttMilestone> milestones;
  final Color bgColor;
  final Color gridColor;
  final Color textColor;
  final Color mutedColor;
  final Color todayColor;
  final Paint _todayFillPaint;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = bgColor);

    // 月ラベル + 区切り線
    final monthFormat = DateFormat('yyyy/MM');
    for (final (date, x) in calculator.getMonthBoundaries(timeline)) {
      _drawText(canvas, monthFormat.format(date), Offset(x + 4, 8),
          textColor, 12, fontWeight: FontWeight.w600);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height),
          Paint()..color = gridColor..strokeWidth = 1);
    }

    // 日付 + 曜日
    const weekDays = AppLabels.weekDays;
    for (final (date, x) in calculator.getDayPositions(timeline)) {
      final cx = x + calculator.pixelsPerDay / 2;
      _drawText(canvas, '${date.day}', Offset(cx - 6, 32), mutedColor, 10);
      final isWeekend = date.weekday >= 6;
      _drawText(canvas, weekDays[date.weekday - 1], Offset(cx - 5, 48),
          isWeekend ? todayColor.withAlpha(150) : mutedColor, 9);
    }

    // 下線
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height),
        Paint()..color = gridColor..strokeWidth = 1);

    // 今日の帯
    final todayX = calculator.calculateTodayX(timeline);
    canvas.drawRect(
      Rect.fromLTWH(todayX, 0, calculator.pixelsPerDay, size.height),
      _todayFillPaint,
    );

    // マイルストーン
    for (final ms in milestones) {
      final mx = calculator.dateToX(ms.date, timeline) +
          calculator.pixelsPerDay / 2;
      final hex = ms.color.replaceFirst('#', '');
      final c = Color(int.parse('FF$hex', radix: 16));
      const ds = 8.0;
      final my = size.height - ds - 4;
      canvas.drawPath(
        Path()..moveTo(mx, my - ds)..lineTo(mx + ds, my)
            ..lineTo(mx, my + ds)..lineTo(mx - ds, my)..close(),
        Paint()..color = c);
      _drawText(canvas, ms.label, Offset(mx + ds + 2, my - 6), c, 9,
          fontWeight: FontWeight.w600);
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset, Color color,
      double fontSize, {FontWeight fontWeight = FontWeight.normal}) {
    TextPainter(
      text: TextSpan(text: text, style: TextStyle(
          color: color, fontSize: fontSize, fontWeight: fontWeight)),
      textDirection: TextDirection.ltr,
    )..layout()..paint(canvas, offset);
  }

  @override
  bool shouldRepaint(_TimelineHeaderPainter old) =>
      old.timeline != timeline || old.milestones != milestones;
}

// ── 右列ボディ: タイムライン ──────────────────────────────────

class _TimelineBodyPainter extends CustomPainter {
  _TimelineBodyPainter({
    required this.tasks,
    required this.groups,
    required this.goalColors,
    required this.milestones,
    required this.calculator,
    required this.timeline,
    required this.hoveredRow,
    required this.gridColor,
    required this.textColor,
    required this.todayColor,
    required this.hoverColor,
  })  : _gridPaint = Paint()..color = gridColor.withAlpha(30)..strokeWidth = 0.5,
        _todayFillPaint = Paint()..color = todayColor.withAlpha(25);

  final List<Task> tasks;
  final List<_GoalGroup> groups;
  final Map<String, Color> goalColors;
  final List<GanttMilestone> milestones;
  final GanttCalculator calculator;
  final TimelineRange timeline;
  final int? hoveredRow;
  final Color gridColor;
  final Color textColor;
  final Color todayColor;
  final Color hoverColor;

  final Paint _gridPaint;
  final Paint _todayFillPaint;

  @override
  void paint(Canvas canvas, Size size) {
    final rowH = calculator.rowHeight.toDouble();

    // グループ背景 + 境界線
    for (final g in groups) {
      final topY = g.startRow * rowH;
      final gh = g.taskCount * rowH;
      canvas.drawRect(Rect.fromLTWH(0, topY, size.width, gh),
          Paint()..color = g.color.withAlpha(8));
      canvas.drawLine(Offset(0, topY), Offset(size.width, topY),
          Paint()..color = g.color.withAlpha(40)..strokeWidth = 0.5);
      if (hoveredRow != null && hoveredRow! >= g.startRow &&
          hoveredRow! <= g.endRow) {
        canvas.drawRect(
            Rect.fromLTWH(0, hoveredRow! * rowH, size.width, rowH),
            Paint()..color = hoverColor.withAlpha(60));
      }
    }
    if (groups.isNotEmpty) {
      final bottomY = (groups.last.endRow + 1) * rowH;
      canvas.drawLine(Offset(0, bottomY), Offset(size.width, bottomY),
          Paint()..color = gridColor.withAlpha(60)..strokeWidth = 0.5);
    }

    // グリッド
    for (var i = 0; i <= tasks.length; i++) {
      final y = i * rowH;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), _gridPaint);
    }
    final weekendPaint = Paint()..color = gridColor.withAlpha(15);
    for (final (date, x) in calculator.getDayPositions(timeline)) {
      if (date.weekday >= 6) {
        canvas.drawRect(
            Rect.fromLTWH(x, 0, calculator.pixelsPerDay, size.height),
            weekendPaint);
      }
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), _gridPaint);
    }

    // マイルストーン破線
    for (final ms in milestones) {
      final x = calculator.dateToX(ms.date, timeline) +
          calculator.pixelsPerDay / 2;
      final hex = ms.color.replaceFirst('#', '');
      final c = Color(int.parse('FF$hex', radix: 16));
      final lp = Paint()..color = c.withAlpha(100)..strokeWidth = 1.5;
      var y = 0.0;
      while (y < size.height) {
        canvas.drawLine(
            Offset(x, y), Offset(x, math.min(y + 6, size.height)), lp);
        y += 10;
      }
    }

    // 今日の帯
    final todayX = calculator.calculateTodayX(timeline);
    canvas.drawRect(
      Rect.fromLTWH(todayX, 0, calculator.pixelsPerDay, size.height),
      _todayFillPaint,
    );

    // タスクバー
    for (var i = 0; i < tasks.length; i++) {
      final task = tasks[i];
      final geo = calculator.calculateBarGeometry(
          task.startDate, task.endDate, task.progress, timeline);
      final y = i * rowH + calculator.barMargin.toDouble();
      final barColor = goalColors[task.goalId] ?? const Color(0xFF89B4FA);
      final bh = calculator.barHeight.toDouble();

      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(geo.x, y, geo.width, bh), const Radius.circular(4)),
          Paint()..color = barColor.withAlpha(60));
      if (geo.progressWidth > 0) {
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(geo.x, y, geo.progressWidth, bh),
                const Radius.circular(4)),
            Paint()..color = barColor);
      }
      // タスク名・進捗率は左列で確認するためバー上には表示しない
    }
  }

  @override
  bool shouldRepaint(_TimelineBodyPainter old) =>
      old.tasks != tasks || old.groups != groups ||
      old.milestones != milestones || old.hoveredRow != hoveredRow ||
      old.timeline != timeline;
}
