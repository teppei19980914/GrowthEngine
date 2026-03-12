/// ガントチャートのExcelエクスポートサービス.
library;

import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';

import '../models/goal.dart';
import '../models/task.dart';

/// ステータスの日本語マッピング.
const _statusLabels = {
  TaskStatus.notStarted: '未着手',
  TaskStatus.inProgress: '進行中',
  TaskStatus.completed: '完了',
};

/// ステータスの日本語文字列からTaskStatusへの逆マッピング.
TaskStatus? statusFromLabel(String label) {
  for (final entry in _statusLabels.entries) {
    if (entry.value == label) return entry.key;
  }
  return null;
}

/// ガントチャートExcelエクスポート結果.
class GanttExcelExportResult {
  /// GanttExcelExportResultを作成する.
  const GanttExcelExportResult({
    required this.bytes,
    required this.fileName,
  });

  /// Excelファイルのバイトデータ.
  final Uint8List bytes;

  /// ファイル名.
  final String fileName;
}

/// ガントチャートをExcelファイルにエクスポートするサービス.
class GanttExcelExportService {
  /// タスクと目標情報からExcelファイルを生成する.
  GanttExcelExportResult export({
    required List<Task> tasks,
    required List<Goal> goals,
  }) {
    final excel = Excel.createExcel();

    final goalMap = {for (final g in goals) g.id: g};

    // データ表シートを先に作成（編集用）
    _buildDataSheet(excel, tasks, goalMap);

    // ガントチャートシートを作成（読み取り専用）
    _buildGanttSheet(excel, tasks, goalMap);

    // デフォルトの Sheet1 を削除
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final bytes = excel.encode();
    if (bytes == null) {
      throw StateError('Excelファイルの生成に失敗しました');
    }

    final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
    final fileName = 'gantt_$dateStr.xlsx';

    return GanttExcelExportResult(
      bytes: Uint8List.fromList(bytes),
      fileName: fileName,
    );
  }

  /// データ表シートを構築する.
  void _buildDataSheet(
    Excel excel,
    List<Task> tasks,
    Map<String, Goal> goalMap,
  ) {
    final sheet = excel['データ表'];

    // ヘッダー行
    const headers = [
      'task_id',
      '目標名',
      'タスク名',
      '開始日',
      '終了日',
      '進捗(%)',
      'ステータス',
      'メモ',
    ];

    // ヘッダースタイル
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#4472C4'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
    );

    for (var col = 0; col < headers.length; col++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[col]);
      cell.cellStyle = headerStyle;
    }

    // データ行
    final dateFormat = DateFormat('yyyy/MM/dd');
    final sortedTasks = List<Task>.from(tasks)
      ..sort((a, b) {
        final goalCmp =
            _goalName(a.goalId, goalMap).compareTo(
              _goalName(b.goalId, goalMap),
            );
        if (goalCmp != 0) return goalCmp;
        return a.startDate.compareTo(b.startDate);
      });

    for (var i = 0; i < sortedTasks.length; i++) {
      final task = sortedTasks[i];
      final row = i + 1;
      final goalName = _goalName(task.goalId, goalMap);

      final values = <CellValue>[
        TextCellValue(task.id),
        TextCellValue(goalName),
        TextCellValue(task.title),
        TextCellValue(dateFormat.format(task.startDate)),
        TextCellValue(dateFormat.format(task.endDate)),
        IntCellValue(task.progress),
        TextCellValue(_statusLabels[task.status] ?? '未着手'),
        TextCellValue(task.memo),
      ];

      for (var col = 0; col < values.length; col++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
        );
        cell.value = values[col];

        // 進捗セルの色分け
        if (col == 5) {
          cell.cellStyle = _progressStyle(task.progress);
        }
      }
    }

    // 列幅設定
    sheet.setColumnWidth(0, 10); // task_id (非表示に近い幅)
    sheet.setColumnWidth(1, 20); // 目標名
    sheet.setColumnWidth(2, 25); // タスク名
    sheet.setColumnWidth(3, 14); // 開始日
    sheet.setColumnWidth(4, 14); // 終了日
    sheet.setColumnWidth(5, 10); // 進捗
    sheet.setColumnWidth(6, 12); // ステータス
    sheet.setColumnWidth(7, 30); // メモ
  }

  /// ガントチャートシートを構築する.
  void _buildGanttSheet(
    Excel excel,
    List<Task> tasks,
    Map<String, Goal> goalMap,
  ) {
    final sheet = excel['ガントチャート'];

    if (tasks.isEmpty) return;

    // 日付範囲を計算
    final sortedTasks = List<Task>.from(tasks)
      ..sort((a, b) {
        final goalCmp =
            _goalName(a.goalId, goalMap).compareTo(
              _goalName(b.goalId, goalMap),
            );
        if (goalCmp != 0) return goalCmp;
        return a.startDate.compareTo(b.startDate);
      });

    var earliest = sortedTasks.first.startDate;
    var latest = sortedTasks.first.endDate;
    for (final task in sortedTasks) {
      if (task.startDate.isBefore(earliest)) earliest = task.startDate;
      if (task.endDate.isAfter(latest)) latest = task.endDate;
    }

    final totalDays = latest.difference(earliest).inDays + 1;

    // ヘッダー行0: 固定列 + 月ラベル
    const fixedHeaders = ['目標名', 'タスク名', '進捗(%)'];
    final fixedHeaderStyle = CellStyle(
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
      cell.cellStyle = fixedHeaderStyle;
    }

    // ヘッダー行1: 日付番号
    final dateHeaderStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Center,
      fontSize: 8,
      backgroundColorHex: ExcelColor.fromHexString('#D6E4F0'),
    );

    for (var d = 0; d < totalDays; d++) {
      final date = earliest.add(Duration(days: d));
      final col = fixedHeaders.length + d;

      // 行0: 月/日
      final headerCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0),
      );
      headerCell.value = TextCellValue('${date.month}/${date.day}');
      headerCell.cellStyle = dateHeaderStyle;
    }

    // GoalIDごとのバースタイルを事前生成（再利用でスタイル数を削減）
    final barStyleCache = <String, (CellStyle, CellStyle)>{};

    // タスク行
    for (var i = 0; i < sortedTasks.length; i++) {
      final task = sortedTasks[i];
      final row = i + 1;
      final goalName = _goalName(task.goalId, goalMap);

      // 固定列
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

      // ガントバー: 日付セルに色を塗る（スタイルを再利用）
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
      final barStyle = styles.$1;
      final barLightStyle = styles.$2;

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
            (d - taskStartDay) < progressDays ? barStyle : barLightStyle;
      }
    }

    // 列幅設定
    sheet.setColumnWidth(0, 18); // 目標名
    sheet.setColumnWidth(1, 20); // タスク名
    sheet.setColumnWidth(2, 8); // 進捗
    // 日付列は狭く
    for (var d = 0; d < totalDays; d++) {
      sheet.setColumnWidth(fixedHeaders.length + d, 4);
    }
  }

  /// 進捗率に応じたセルスタイルを返す.
  CellStyle _progressStyle(int progress) {
    final ExcelColor bgColor;
    if (progress >= 100) {
      bgColor = ExcelColor.fromHexString('#C6EFCE'); // 緑系
    } else if (progress >= 50) {
      bgColor = ExcelColor.fromHexString('#FFEB9C'); // 黄系
    } else if (progress > 0) {
      bgColor = ExcelColor.fromHexString('#FDD8B5'); // オレンジ系
    } else {
      bgColor = ExcelColor.fromHexString('#FFC7CE'); // 赤系
    }
    return CellStyle(
      backgroundColorHex: bgColor,
      horizontalAlign: HorizontalAlign.Center,
    );
  }

  /// GoalIDから目標名を取得する.
  String _goalName(String goalId, Map<String, Goal> goalMap) {
    if (goalId == bookGanttGoalId) return '書籍';
    return goalMap[goalId]?.what ?? '不明';
  }

  /// GoalIDからカラーHexを取得する.
  String _goalHexColor(String goalId, Map<String, Goal> goalMap) {
    final color = goalMap[goalId]?.color;
    if (color != null) return color.replaceFirst('#', '');
    return '89B4FA'; // デフォルト青
  }

  /// Hex色を薄くする.
  String _lightenHex(String hex) {
    final clean = hex.replaceFirst('#', '');
    final r = int.parse(clean.substring(0, 2), radix: 16);
    final g = int.parse(clean.substring(2, 4), radix: 16);
    final b = int.parse(clean.substring(4, 6), radix: 16);
    // 白に近づける（70%の白ブレンド）
    final lr = r + ((255 - r) * 0.7).round();
    final lg = g + ((255 - g) * 0.7).round();
    final lb = b + ((255 - b) * 0.7).round();
    return '${lr.clamp(0, 255).toRadixString(16).padLeft(2, '0')}'
        '${lg.clamp(0, 255).toRadixString(16).padLeft(2, '0')}'
        '${lb.clamp(0, 255).toRadixString(16).padLeft(2, '0')}';
  }
}
