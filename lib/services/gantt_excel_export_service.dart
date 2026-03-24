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

    final buf = StringBuffer()
      ..writeln('<!DOCTYPE html>')
      ..writeln('<html lang="ja"><head>')
      ..writeln('<meta charset="UTF-8">')
      ..writeln('<meta name="viewport" content="width=device-width,initial-scale=1">')
      ..writeln('<title>ガントチャート - ${df.format(DateTime.now())}</title>')
      ..writeln('<style>')
      ..writeln('* { margin: 0; padding: 0; box-sizing: border-box; }')
      ..writeln('body { font-family: -apple-system, "Segoe UI", sans-serif; background: #1e1e2e; color: #cdd6f4; padding: 20px; }')
      ..writeln('h1 { font-size: 18px; margin-bottom: 4px; }')
      ..writeln('.subtitle { color: #6c7086; font-size: 12px; margin-bottom: 16px; }')
      ..writeln('.gantt-container { overflow-x: auto; }')
      ..writeln('table { border-collapse: collapse; min-width: 100%; }')
      ..writeln('th, td { padding: 6px 8px; font-size: 12px; white-space: nowrap; border: 1px solid #313244; }')
      ..writeln('th { background: #313244; color: #cdd6f4; font-weight: 600; position: sticky; top: 0; }')
      ..writeln('.goal-name { color: #89b4fa; font-weight: 600; }')
      ..writeln('.progress-cell { text-align: center; font-weight: 600; border-radius: 4px; }')
      ..writeln('.p100 { background: #a6e3a1; color: #1e1e2e; }')
      ..writeln('.p50 { background: #f9e2af; color: #1e1e2e; }')
      ..writeln('.p1 { background: #fab387; color: #1e1e2e; }')
      ..writeln('.p0 { background: #f38ba8; color: #1e1e2e; }')
      ..writeln('.bar { min-width: 18px; height: 100%; }')
      ..writeln('.bar-done { opacity: 1.0; }')
      ..writeln('.bar-remain { opacity: 0.3; }')
      ..writeln('.date-header { font-size: 10px; text-align: center; min-width: 24px; padding: 4px 2px; }')
      ..writeln('.weekend { background: #1e1e2e; }')
      ..writeln('.legend { margin-top: 16px; font-size: 11px; color: #6c7086; }')
      ..writeln('</style></head><body>')
      ..writeln('<h1>ガントチャート</h1>')
      ..writeln('<div class="subtitle">エクスポート日: ${df.format(DateTime.now())} | '
          'タスク数: ${tasks.length} | '
          '期間: ${df.format(earliest)} ～ ${df.format(latest)}</div>')
      ..writeln('<div class="gantt-container"><table>');

    // ヘッダー行
    buf.write('<tr><th>目標</th><th>タスク</th><th>進捗</th>'
        '<th>ステータス</th><th>開始日</th><th>終了日</th>');
    for (var d = 0; d < totalDays; d++) {
      final date = earliest.add(Duration(days: d));
      final isWeekend = date.weekday == 6 || date.weekday == 7;
      buf.write('<th class="date-header${isWeekend ? ' weekend' : ''}">'
          '${date.month}/${date.day}</th>');
    }
    buf.writeln('</tr>');

    // タスク行
    for (final task in sorted) {
      final goalName = _goalName(task.goalId, goalMap);
      final goalColor = _goalHexColor(task.goalId, goalMap);
      final pClass = task.progress >= 100
          ? 'p100'
          : task.progress >= 50
              ? 'p50'
              : task.progress > 0
                  ? 'p1'
                  : 'p0';

      buf.write('<tr>');
      buf.write('<td class="goal-name">${_escapeHtml(goalName)}</td>');
      buf.write('<td>${_escapeHtml(task.title)}</td>');
      buf.write('<td class="progress-cell $pClass">${task.progress}%</td>');
      buf.write('<td>${_statusLabels[task.status] ?? "未着手"}</td>');
      buf.write('<td>${df.format(task.startDate)}</td>');
      buf.write('<td>${df.format(task.endDate)}</td>');

      final taskStartDay = task.startDate.difference(earliest).inDays;
      final taskEndDay = task.endDate.difference(earliest).inDays;
      final taskDuration = taskEndDay - taskStartDay + 1;
      final progressDays = (taskDuration * task.progress / 100).round();

      for (var d = 0; d < totalDays; d++) {
        if (d >= taskStartDay && d <= taskEndDay) {
          final isDone = (d - taskStartDay) < progressDays;
          buf.write('<td class="bar ${isDone ? 'bar-done' : 'bar-remain'}" '
              'style="background:#$goalColor;"></td>');
        } else {
          final date = earliest.add(Duration(days: d));
          final isWeekend = date.weekday == 6 || date.weekday == 7;
          buf.write('<td${isWeekend ? ' class="weekend"' : ''}></td>');
        }
      }
      buf.writeln('</tr>');
    }

    // マイルストーン行
    for (final ms in milestones) {
      final msDay = ms.date.difference(earliest).inDays;
      final msColor = ms.color.replaceFirst('#', '');
      buf.write('<tr>');
      buf.write('<td class="goal-name" style="color:#$msColor;">'
          '\u{25C6} ${_escapeHtml(ms.label)}</td>');
      buf.write('<td>マイルストーン</td>');
      buf.write('<td></td><td></td>');
      buf.write('<td>${df.format(ms.date)}</td>');
      buf.write('<td></td>');
      for (var d = 0; d < totalDays; d++) {
        if (d == msDay) {
          buf.write('<td style="background:#$msColor;text-align:center;'
              'color:#fff;font-weight:bold;">\u{25C6}</td>');
        } else {
          final date = earliest.add(Duration(days: d));
          final isWeekend = date.weekday == 6 || date.weekday == 7;
          buf.write('<td${isWeekend ? ' class="weekend"' : ''}></td>');
        }
      }
      buf.writeln('</tr>');
    }

    buf
      ..writeln('</table></div>')
      ..writeln('<div class="legend">ユメログ - ガントチャートエクスポート</div>')
      ..writeln('</body></html>');

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

    // マイルストーン行
    for (final ms in milestones) {
      buf.writeln(
        '${_csvEscape('\u{25C6} ${ms.label}')},'
        'マイルストーン,'
        '${df.format(ms.date)},'
        ','
        ','
        'マイルストーン,'
        '',
      );
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
    final sheet = excel['ガントチャート'];
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

    // マイルストーン行
    final dateFmtMs = DateFormat('yyyy/MM/dd');
    for (var m = 0; m < milestones.length; m++) {
      final ms = milestones[m];
      final row = sortedTasks.length + 1 + m;
      final msColor = ms.color.replaceFirst('#', '');

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = TextCellValue('\u{25C6} ${ms.label}');
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
          .value = TextCellValue('マイルストーン');
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
    for (final ms in milestones) {
      if (ms.date.isBefore(earliest)) earliest = ms.date;
      if (ms.date.isAfter(latest)) latest = ms.date;
    }
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

  String _goalHexColor(String goalId, Map<String, Goal> goalMap) {
    final color = goalMap[goalId]?.color;
    if (color != null) return color.replaceFirst('#', '');
    return '89B4FA';
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
