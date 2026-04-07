/// ガントチャートのエクスポートサービス.
///
/// HTML / Excel / CSV 形式でガントチャートをエクスポートする.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';

import '../models/goal.dart';
import '../models/task.dart';
import 'study_stats_types.dart' show GanttMilestone;

/// ステータスの日本語マッピング.
const _statusLabels = {
  TaskStatus.notStarted: '未着手',
  TaskStatus.inProgress: '進行中',
  TaskStatus.completed: '完了',
};

/// エクスポート結果.
class GanttExportResult {
  /// GanttExportResultを作成する.
  const GanttExportResult({
    required this.bytes,
    required this.fileName,
    this.mimeType,
  });

  /// ファイルのバイトデータ.
  final Uint8List bytes;

  /// ファイル名.
  final String fileName;

  /// MIMEタイプ.
  final String? mimeType;
}

/// ガントチャートエクスポートサービス.
class GanttExcelExportService {
  /// 指定形式でエクスポートする.
  GanttExportResult exportAs({
    required List<Task> tasks,
    required List<Goal> goals,
    required String format,
  }) {
    final goalMap = {for (final g in goals) g.id: g};
    final milestones = _buildMilestones(goals);
    final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());

    switch (format) {
      case 'html':
        return _exportHtml(tasks, goalMap, milestones, dateStr);
      case 'csv':
        return _exportCsv(tasks, goalMap, milestones, dateStr);
      default:
        return _exportExcel(tasks, goalMap, milestones, dateStr);
    }
  }

  /// 後方互換: 既存の export メソッド.
  GanttExportResult export({
    required List<Task> tasks,
    required List<Goal> goals,
  }) {
    return exportAs(tasks: tasks, goals: goals, format: 'excel');
  }

  // ── マイルストーン構築 ──────────────────────────────────────

  List<GanttMilestone> _buildMilestones(List<Goal> goals) {
    final milestones = <GanttMilestone>[];
    for (final goal in goals) {
      final targetDate = goal.getTargetDate();
      if (targetDate != null) {
        milestones.add(GanttMilestone(
          label: goal.what,
          date: targetDate,
          color: goal.color,
        ));
      }
    }
    return milestones;
  }

  // ── HTML エクスポート ──────────────────────────────────────

  GanttExportResult _exportHtml(
    List<Task> tasks,
    Map<String, Goal> goalMap,
    List<GanttMilestone> milestones,
    String dateStr,
  ) {
    final sorted = _sortTasks(tasks, goalMap);
    final (earliest, latest) = _dateRange(sorted, milestones);
    final totalDays = latest.difference(earliest).inDays + 1;
    final df = DateFormat('yyyy/MM/dd');

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 目標別にタスクをグルーピング
    final goalGroups = <String, List<Task>>{};
    for (final task in sorted) {
      goalGroups.putIfAbsent(task.goalId, () => []).add(task);
    }

    final buf = StringBuffer()
      ..writeln('<!DOCTYPE html>')
      ..writeln('<html lang="ja"><head>')
      ..writeln('<meta charset="UTF-8">')
      ..writeln('<meta name="viewport" content="width=device-width,initial-scale=1">')
      ..writeln('<title>活動予定 - ${df.format(now)}</title>')
      ..writeln('<style>')
      ..writeln('''
* { margin: 0; padding: 0; box-sizing: border-box; }
body { font-family: 'Hiragino Sans', 'Noto Sans JP', -apple-system, sans-serif; background: #1e1e2e; color: #cdd6f4; }
.header { background: linear-gradient(135deg, #1e1e2e 0%, #313244 100%); padding: 32px 24px; border-bottom: 3px solid #89b4fa; }
.header h1 { font-size: 1.4em; margin-bottom: 4px; }
.header-meta { color: #6c7086; font-size: 0.8em; display: flex; gap: 16px; flex-wrap: wrap; margin-top: 8px; }
.header-meta span { background: #313244; padding: 2px 10px; border-radius: 12px; }
.container { max-width: 1200px; margin: 0 auto; padding: 24px; }
.summary { display: grid; grid-template-columns: repeat(auto-fit, minmax(140px, 1fr)); gap: 12px; margin-bottom: 24px; }
.summary-card { background: #313244; border-radius: 10px; padding: 16px; text-align: center; }
.summary-card .num { font-size: 1.6em; font-weight: bold; }
.summary-card .label { font-size: 0.75em; color: #a6adc8; margin-top: 2px; }
.sc-blue .num { color: #89b4fa; }
.sc-green .num { color: #a6e3a1; }
.sc-yellow .num { color: #f9e2af; }
.sc-red .num { color: #f38ba8; }
.goal-section { margin-bottom: 28px; }
.goal-header { display: flex; align-items: center; gap: 10px; margin-bottom: 12px; padding-bottom: 8px; border-bottom: 2px solid #45475a; }
.goal-color { width: 4px; height: 28px; border-radius: 2px; }
.goal-title { font-size: 1.05em; font-weight: 600; }
.goal-progress { margin-left: auto; font-size: 0.8em; color: #a6adc8; }
.task-row { background: #313244; border-radius: 10px; padding: 14px 16px; margin-bottom: 8px; }
.task-top { display: flex; align-items: center; gap: 12px; margin-bottom: 8px; flex-wrap: wrap; }
.task-title { font-weight: 500; font-size: 0.95em; flex: 1; min-width: 120px; }
.badge { padding: 2px 10px; border-radius: 12px; font-size: 0.7em; font-weight: 600; }
.badge-done { background: #a6e3a1; color: #1e1e2e; }
.badge-wip { background: #89b4fa; color: #1e1e2e; }
.badge-todo { background: #45475a; color: #a6adc8; }
.task-dates { font-size: 0.75em; color: #6c7086; }
.progress-bar { height: 8px; background: #45475a; border-radius: 4px; overflow: hidden; }
.progress-fill { height: 100%; border-radius: 4px; transition: width 0.3s; }
.progress-text { font-size: 0.75em; color: #a6adc8; margin-top: 4px; text-align: right; }
.timeline { margin-top: 10px; position: relative; height: 6px; background: #45475a; border-radius: 3px; }
.tl-bar { position: absolute; height: 100%; border-radius: 3px; }
.tl-done { opacity: 1; }
.tl-remain { opacity: 0.3; }
.tl-today { position: absolute; top: -4px; width: 2px; height: 14px; background: #f38ba8; border-radius: 1px; }
.milestone { background: #313244; border-radius: 10px; padding: 12px 16px; margin-bottom: 8px; border-left: 4px solid; display: flex; align-items: center; gap: 12px; }
.ms-diamond { font-size: 1.1em; }
.ms-info { flex: 1; }
.ms-label { font-weight: 600; font-size: 0.9em; }
.ms-date { font-size: 0.75em; color: #a6adc8; }
.footer { text-align: center; padding: 20px; color: #45475a; font-size: 0.75em; border-top: 1px solid #313244; margin-top: 24px; }
@media (max-width: 600px) { .task-top { flex-direction: column; align-items: flex-start; } }
''')
      ..writeln('</style></head><body>');

    // ヘッダー
    final completedCount = sorted.where((t) => t.progress >= 100).length;
    final wipCount =
        sorted.where((t) => t.progress > 0 && t.progress < 100).length;
    final todoCount = sorted.where((t) => t.progress == 0).length;

    buf.writeln('<div class="header">');
    buf.writeln('<h1>活動予定</h1>');
    buf.writeln('<div class="header-meta">');
    buf.writeln('<span>エクスポート: ${df.format(now)}</span>');
    buf.writeln('<span>期間: ${df.format(earliest)} ～ ${df.format(latest)}</span>');
    buf.writeln('<span>タスク数: ${tasks.length}</span>');
    buf.writeln('</div></div>');

    buf.writeln('<div class="container">');

    // サマリーカード
    buf.writeln('<div class="summary">');
    buf.writeln(
        '<div class="summary-card sc-blue"><div class="num">${tasks.length}</div><div class="label">全タスク</div></div>');
    buf.writeln(
        '<div class="summary-card sc-green"><div class="num">$completedCount</div><div class="label">完了</div></div>');
    buf.writeln(
        '<div class="summary-card sc-yellow"><div class="num">$wipCount</div><div class="label">進行中</div></div>');
    buf.writeln(
        '<div class="summary-card sc-red"><div class="num">$todoCount</div><div class="label">未着手</div></div>');
    buf.writeln('</div>');

    // 目標別セクション
    for (final entry in goalGroups.entries) {
      final goalId = entry.key;
      final goalTasks = entry.value;
      final goalName = _goalName(goalId, goalMap);
      final goalColor = _goalHexColor(goalId, goalMap);
      final goalCompleted =
          goalTasks.where((t) => t.progress >= 100).length;

      buf.writeln('<div class="goal-section">');
      buf.writeln('<div class="goal-header">');
      buf.writeln('<div class="goal-color" style="background:#$goalColor;"></div>');
      buf.writeln(
          '<div class="goal-title">${_escapeHtml(goalName)}</div>');
      buf.writeln(
          '<div class="goal-progress">$goalCompleted / ${goalTasks.length} 完了</div>');
      buf.writeln('</div>');

      for (final task in goalTasks) {
        final statusBadge = task.progress >= 100
            ? 'badge-done'
            : task.progress > 0
                ? 'badge-wip'
                : 'badge-todo';
        final statusLabel = _statusLabels[task.status] ?? '未着手';
        final duration = task.endDate.difference(task.startDate).inDays + 1;
        final progressColor = task.progress >= 100
            ? '#a6e3a1'
            : task.progress >= 50
                ? '#f9e2af'
                : task.progress > 0
                    ? '#fab387'
                    : '#45475a';

        buf.writeln('<div class="task-row">');
        buf.writeln('<div class="task-top">');
        buf.writeln(
            '<div class="task-title">${_escapeHtml(task.title)}</div>');
        buf.writeln(
            '<span class="badge $statusBadge">$statusLabel</span>');
        buf.writeln(
            '<div class="task-dates">${df.format(task.startDate)} ～ ${df.format(task.endDate)}（$duration日間）</div>');
        buf.writeln('</div>');

        // プログレスバー
        buf.writeln('<div class="progress-bar">');
        buf.writeln(
            '<div class="progress-fill" style="width:${task.progress}%;background:$progressColor;"></div>');
        buf.writeln('</div>');
        buf.writeln(
            '<div class="progress-text">${task.progress}%</div>');

        // タイムライン（日付位置ベース）
        if (totalDays > 0) {
          final startPct =
              (task.startDate.difference(earliest).inDays / totalDays * 100)
                  .clamp(0.0, 100.0);
          final endPct =
              ((task.endDate.difference(earliest).inDays + 1) /
                      totalDays *
                      100)
                  .clamp(0.0, 100.0);
          final barWidth = endPct - startPct;
          final donePct = barWidth * task.progress / 100;
          final todayPct =
              (today.difference(earliest).inDays / totalDays * 100)
                  .clamp(0.0, 100.0);

          buf.writeln('<div class="timeline">');
          buf.writeln(
              '<div class="tl-bar tl-remain" style="left:${startPct.toStringAsFixed(1)}%;width:${barWidth.toStringAsFixed(1)}%;background:#$goalColor;"></div>');
          buf.writeln(
              '<div class="tl-bar tl-done" style="left:${startPct.toStringAsFixed(1)}%;width:${donePct.toStringAsFixed(1)}%;background:#$goalColor;"></div>');
          buf.writeln(
              '<div class="tl-today" style="left:${todayPct.toStringAsFixed(1)}%;" title="今日"></div>');
          buf.writeln('</div>');
        }

        buf.writeln('</div>');
      }

      buf.writeln('</div>');
    }

    // マイルストーン（タスク範囲内のみ）
    final visibleMs = milestones
        .where(
            (ms) => !ms.date.isBefore(earliest) && !ms.date.isAfter(latest))
        .toList();
    if (visibleMs.isNotEmpty) {
      buf.writeln('<div class="goal-section">');
      buf.writeln('<div class="goal-header">');
      buf.writeln(
          '<div class="goal-color" style="background:#f9e2af;"></div>');
      buf.writeln('<div class="goal-title">目標期限</div>');
      buf.writeln('</div>');
      for (final ms in visibleMs) {
        final msColor = _sanitizeHexColor(ms.color);
        buf.writeln(
            '<div class="milestone" style="border-color:#$msColor;">');
        buf.writeln(
            '<div class="ms-diamond" style="color:#$msColor;">\u{25C6}</div>');
        buf.writeln('<div class="ms-info">');
        buf.writeln(
            '<div class="ms-label">${_escapeHtml(ms.label)}</div>');
        buf.writeln(
            '<div class="ms-date">${df.format(ms.date)}</div>');
        buf.writeln('</div></div>');
      }
      buf.writeln('</div>');
    }

    buf.writeln('</div>');
    buf.writeln(
        '<div class="footer">ユメハシ - 活動予定エクスポート</div>');
    buf.writeln('</body></html>');

    return GanttExportResult(
      bytes: Uint8List.fromList(utf8.encode(buf.toString())),
      fileName: 'gantt_$dateStr.html',
      mimeType: 'text/html',
    );
  }

  // ── Excel エクスポート ─────────────────────────────────────

  GanttExportResult _exportExcel(
    List<Task> tasks,
    Map<String, Goal> goalMap,
    List<GanttMilestone> milestones,
    String dateStr,
  ) {
    final excel = Excel.createExcel();
    _buildGanttSheet(excel, tasks, goalMap, milestones);

    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final bytes = excel.encode();
    if (bytes == null) {
      throw StateError('Excelファイルの生成に失敗しました');
    }

    return GanttExportResult(
      bytes: Uint8List.fromList(bytes),
      fileName: 'gantt_$dateStr.xlsx',
      mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
  }

  // ── CSV エクスポート ──────────────────────────────────────

  GanttExportResult _exportCsv(
    List<Task> tasks,
    Map<String, Goal> goalMap,
    List<GanttMilestone> milestones,
    String dateStr,
  ) {
    final sorted = _sortTasks(tasks, goalMap);
    final df = DateFormat('yyyy/MM/dd');
    final buf = StringBuffer();

    // BOM（Excelで日本語が文字化けしないように）
    buf.write('\uFEFF');

    // ヘッダー
    buf.writeln('目標名,タスク名,開始日,終了日,進捗(%),ステータス,期間(日)');

    // データ行
    for (final task in sorted) {
      final goalName = _goalName(task.goalId, goalMap);
      final duration = task.endDate.difference(task.startDate).inDays + 1;
      buf.writeln(
        '${_csvEscape(goalName)},'
        '${_csvEscape(task.title)},'
        '${df.format(task.startDate)},'
        '${df.format(task.endDate)},'
        '${task.progress},'
        '${_statusLabels[task.status] ?? "未着手"},'
        '$duration',
      );
    }

    // マイルストーン行（タスク範囲内のもののみ）
    if (sorted.isNotEmpty) {
      final (earliest, latest) = _dateRange(sorted);
      for (final ms in milestones) {
        if (ms.date.isBefore(earliest) || ms.date.isAfter(latest)) continue;
        buf.writeln(
          '${_csvEscape('\u{25C6} ${ms.label}')},'
          '目標期限,'
          '${df.format(ms.date)},'
          ','
          ','
          '目標期限,'
          '',
        );
      }
    }

    return GanttExportResult(
      bytes: Uint8List.fromList(utf8.encode(buf.toString())),
      fileName: 'gantt_$dateStr.csv',
      mimeType: 'text/csv',
    );
  }

  // ── Excel ガントチャートシート ────────────────────────────

  void _buildGanttSheet(
    Excel excel,
    List<Task> tasks,
    Map<String, Goal> goalMap,
    List<GanttMilestone> milestones,
  ) {
    final sheet = excel['活動予定'];
    if (tasks.isEmpty) return;

    final sortedTasks = _sortTasks(tasks, goalMap);
    final (earliest, latest) = _dateRange(sortedTasks, milestones);
    final totalDays = latest.difference(earliest).inDays + 1;

    // ヘッダー
    const fixedHeaders = ['目標名', 'タスク名', '進捗(%)', 'ステータス', '開始日', '終了日'];
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#4472C4'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
    );

    for (var col = 0; col < fixedHeaders.length; col++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0),
      );
      cell.value = TextCellValue(fixedHeaders[col]);
      cell.cellStyle = headerStyle;
    }

    // 日付ヘッダー
    final dateHeaderStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Center,
      fontSize: 8,
      backgroundColorHex: ExcelColor.fromHexString('#D6E4F0'),
    );
    final df = DateFormat('M/d');
    for (var d = 0; d < totalDays; d++) {
      final date = earliest.add(Duration(days: d));
      final col = fixedHeaders.length + d;
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0),
      );
      cell.value = TextCellValue(df.format(date));
      cell.cellStyle = dateHeaderStyle;
    }

    // スタイルキャッシュ
    final barStyleCache = <String, (CellStyle, CellStyle)>{};
    final dateFmt = DateFormat('yyyy/MM/dd');

    // タスク行
    for (var i = 0; i < sortedTasks.length; i++) {
      final task = sortedTasks[i];
      final row = i + 1;
      final goalName = _goalName(task.goalId, goalMap);

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = TextCellValue(goalName);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
          .value = TextCellValue(task.title);

      final progressCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row),
      );
      progressCell.value = IntCellValue(task.progress);
      progressCell.cellStyle = _progressStyle(task.progress);

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
          .value = TextCellValue(_statusLabels[task.status] ?? '未着手');
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
          .value = TextCellValue(dateFmt.format(task.startDate));
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
          .value = TextCellValue(dateFmt.format(task.endDate));

      // ガントバー
      final goalHex = _goalHexColor(task.goalId, goalMap);
      final styles = barStyleCache.putIfAbsent(task.goalId, () {
        final barStyle = CellStyle(
          backgroundColorHex: ExcelColor.fromHexString('#$goalHex'),
        );
        final lightStyle = CellStyle(
          backgroundColorHex:
              ExcelColor.fromHexString('#${_lightenHex(goalHex)}'),
        );
        return (barStyle, lightStyle);
      });

      final taskStartDay = task.startDate.difference(earliest).inDays;
      final taskEndDay = task.endDate.difference(earliest).inDays;
      final taskDuration = taskEndDay - taskStartDay + 1;
      final progressDays = (taskDuration * task.progress / 100).round();

      for (var d = taskStartDay; d <= taskEndDay; d++) {
        final col = fixedHeaders.length + d;
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
        );
        cell.cellStyle =
            (d - taskStartDay) < progressDays ? styles.$1 : styles.$2;
      }
    }

    // マイルストーン行（タスク範囲内のもののみ）
    final dateFmtMs = DateFormat('yyyy/MM/dd');
    final filteredMs = milestones.where(
      (ms) => !ms.date.isBefore(earliest) && !ms.date.isAfter(latest),
    ).toList();
    for (var m = 0; m < filteredMs.length; m++) {
      final ms = filteredMs[m];
      final row = sortedTasks.length + 1 + m;
      final msColor = _sanitizeHexColor(ms.color);

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = TextCellValue('\u{25C6} ${ms.label}');
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
          .value = TextCellValue('目標期限');
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
          .value = TextCellValue(dateFmtMs.format(ms.date));

      // ダイヤマーカー
      final msDay = ms.date.difference(earliest).inDays;
      if (msDay >= 0 && msDay < totalDays) {
        final col = fixedHeaders.length + msDay;
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
        );
        cell.value = TextCellValue('\u{25C6}');
        cell.cellStyle = CellStyle(
          backgroundColorHex: ExcelColor.fromHexString('#$msColor'),
          horizontalAlign: HorizontalAlign.Center,
          bold: true,
        );
      }
    }

    // 列幅
    sheet.setColumnWidth(0, 18);
    sheet.setColumnWidth(1, 22);
    sheet.setColumnWidth(2, 8);
    sheet.setColumnWidth(3, 10);
    sheet.setColumnWidth(4, 12);
    sheet.setColumnWidth(5, 12);
    for (var d = 0; d < totalDays; d++) {
      sheet.setColumnWidth(fixedHeaders.length + d, 4);
    }
  }

  // ── ヘルパー ──────────────────────────────────────────────

  List<Task> _sortTasks(List<Task> tasks, Map<String, Goal> goalMap) {
    return List<Task>.from(tasks)
      ..sort((a, b) {
        final goalCmp = _goalName(a.goalId, goalMap)
            .compareTo(_goalName(b.goalId, goalMap));
        if (goalCmp != 0) return goalCmp;
        return a.startDate.compareTo(b.startDate);
      });
  }

  /// タスクの開始日〜終了日のみで日付範囲を計算する.
  ///
  /// マイルストーン（目標期限）は範囲に含めない（アプリ画面と同じ動作）.
  (DateTime, DateTime) _dateRange(
    List<Task> sorted, [
    List<GanttMilestone> milestones = const [],
  ]) {
    var earliest = sorted.first.startDate;
    var latest = sorted.first.endDate;
    for (final task in sorted) {
      if (task.startDate.isBefore(earliest)) earliest = task.startDate;
      if (task.endDate.isAfter(latest)) latest = task.endDate;
    }
    // マイルストーンは範囲内にあれば表示されるが、範囲を引き延ばさない
    return (earliest, latest);
  }

  CellStyle _progressStyle(int progress) {
    final ExcelColor bgColor;
    if (progress >= 100) {
      bgColor = ExcelColor.fromHexString('#C6EFCE');
    } else if (progress >= 50) {
      bgColor = ExcelColor.fromHexString('#FFEB9C');
    } else if (progress > 0) {
      bgColor = ExcelColor.fromHexString('#FDD8B5');
    } else {
      bgColor = ExcelColor.fromHexString('#FFC7CE');
    }
    return CellStyle(
      backgroundColorHex: bgColor,
      horizontalAlign: HorizontalAlign.Center,
    );
  }

  String _goalName(String goalId, Map<String, Goal> goalMap) {
    if (goalId == bookGanttGoalId) return '書籍';
    if (goalId.isEmpty) return '独立タスク';
    return goalMap[goalId]?.what ?? '不明';
  }

  static final _hexColorPattern = RegExp(r'^[0-9a-fA-F]{6}$');

  String _sanitizeHexColor(String raw) {
    final cleaned = raw.replaceFirst('#', '');
    if (_hexColorPattern.hasMatch(cleaned)) return cleaned;
    return '89B4FA';
  }

  String _goalHexColor(String goalId, Map<String, Goal> goalMap) {
    final color = goalMap[goalId]?.color ?? '';
    return _sanitizeHexColor(color);
  }

  String _lightenHex(String hex) {
    final clean = hex.replaceFirst('#', '');
    final r = int.parse(clean.substring(0, 2), radix: 16);
    final g = int.parse(clean.substring(2, 4), radix: 16);
    final b = int.parse(clean.substring(4, 6), radix: 16);
    final lr = r + ((255 - r) * 0.7).round();
    final lg = g + ((255 - g) * 0.7).round();
    final lb = b + ((255 - b) * 0.7).round();
    return '${lr.clamp(0, 255).toRadixString(16).padLeft(2, '0')}'
        '${lg.clamp(0, 255).toRadixString(16).padLeft(2, '0')}'
        '${lb.clamp(0, 255).toRadixString(16).padLeft(2, '0')}';
  }

  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
  }

  String _csvEscape(String text) {
    if (text.contains(',') || text.contains('"') || text.contains('\n')) {
      return '"${text.replaceAll('"', '""')}"';
    }
    return text;
  }
}
