/// ガントチャートのExcelインポートサービス.
library;

import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';

import '../models/goal.dart';
import 'task_service.dart';

/// インポート結果.
class GanttImportResult {
  /// GanttImportResultを作成する.
  const GanttImportResult({
    this.updatedCount = 0,
    this.createdCount = 0,
    this.skippedCount = 0,
    this.errors = const [],
  });

  /// 更新されたタスク数.
  final int updatedCount;

  /// 新規作成されたタスク数.
  final int createdCount;

  /// スキップされた行数.
  final int skippedCount;

  /// エラーメッセージ一覧.
  final List<String> errors;
}

/// Excelファイルからガントチャートデータをインポートするサービス.
class GanttExcelImportService {
  /// GanttExcelImportServiceを作成する.
  GanttExcelImportService({
    required TaskService taskService,
  }) : _taskService = taskService;

  final TaskService _taskService;

  /// Excelファイルのバイトデータからタスクをインポートする.
  Future<GanttImportResult> import({
    required Uint8List bytes,
    required List<Goal> goals,
  }) async {
    final excel = Excel.decodeBytes(bytes);

    // データ表シートを探す
    final sheet = excel.tables['データ表'];
    if (sheet == null) {
      return const GanttImportResult(
        errors: ['「データ表」シートが見つかりません'],
      );
    }

    // ヘッダー行を検証
    if (sheet.maxRows < 2) {
      return const GanttImportResult(
        errors: ['データ行がありません'],
      );
    }

    final headerRow = sheet.row(0);
    if (!_validateHeaders(headerRow)) {
      return const GanttImportResult(
        errors: ['ヘッダー行の形式が正しくありません'],
      );
    }

    // 目標名 → Goal のマップを構築
    final goalByName = <String, Goal>{};
    for (final goal in goals) {
      goalByName[goal.what] = goal;
    }

    // 既存タスクのマップ
    final allTasks = await _taskService.getAllTasks();
    final existingTasks = {for (final t in allTasks) t.id: t};

    var updatedCount = 0;
    var createdCount = 0;
    var skippedCount = 0;
    final errors = <String>[];
    final dateFormat = DateFormat('yyyy/MM/dd');

    // データ行を処理（行1から）
    for (var rowIdx = 1; rowIdx < sheet.maxRows; rowIdx++) {
      final row = sheet.row(rowIdx);
      final lineNum = rowIdx + 1;

      try {
        final taskId = _cellToString(row[0]);
        final goalName = _cellToString(row[1]);
        final taskName = _cellToString(row[2]);
        final startDateStr = _cellToString(row[3]);
        final endDateStr = _cellToString(row[4]);
        final progressValue = _cellToInt(row[5]);
        final memo = row.length > 7 ? _cellToString(row[7]) : '';

        // 必須フィールドの検証
        if (taskName.isEmpty) {
          skippedCount++;
          if (goalName.isNotEmpty) {
            errors.add('行$lineNum: タスク名が空のためスキップしました');
          }
          continue;
        }

        if (goalName.isEmpty || startDateStr.isEmpty || endDateStr.isEmpty) {
          skippedCount++;
          errors.add('行$lineNum: 必須項目（目標名/開始日/終了日）が空のためスキップしました');
          continue;
        }

        // 日付パース
        final DateTime startDate;
        final DateTime endDate;
        try {
          startDate = dateFormat.parse(startDateStr);
          endDate = dateFormat.parse(endDateStr);
        } on FormatException {
          skippedCount++;
          errors.add('行$lineNum: 日付形式が不正です（yyyy/MM/dd形式で入力してください）');
          continue;
        }

        if (endDate.isBefore(startDate)) {
          skippedCount++;
          errors.add('行$lineNum: 終了日が開始日より前です');
          continue;
        }

        // 進捗率の検証
        final progress = progressValue?.clamp(0, 100) ?? 0;

        if (taskId.isNotEmpty && existingTasks.containsKey(taskId)) {
          // 既存タスクの更新
          await _taskService.updateTask(
            taskId: taskId,
            title: taskName,
            startDate: startDate,
            endDate: endDate,
            progress: progress,
            memo: memo,
          );
          updatedCount++;
        } else {
          // 新規作成: 目標名でGoalを検索
          final goal = goalByName[goalName];
          if (goal == null) {
            skippedCount++;
            errors.add(
              '行$lineNum: 目標「$goalName」がアプリに存在しないためスキップしました',
            );
            continue;
          }
          await _taskService.createTask(
            goalId: goal.id,
            title: taskName,
            startDate: startDate,
            endDate: endDate,
            memo: memo,
          );
          // 進捗が0でない場合は更新
          if (progress > 0) {
            final tasks = await _taskService.getTasksForGoal(goal.id);
            final created = tasks.where((t) => t.title == taskName).lastOrNull;
            if (created != null) {
              await _taskService.updateProgress(created.id, progress);
            }
          }
          createdCount++;
        }
      } on Object catch (e) {
        skippedCount++;
        errors.add('行$lineNum: $e');
      }
    }

    return GanttImportResult(
      updatedCount: updatedCount,
      createdCount: createdCount,
      skippedCount: skippedCount,
      errors: errors,
    );
  }

  /// ヘッダー行を検証する.
  bool _validateHeaders(List<Data?> headerRow) {
    if (headerRow.length < 8) return false;
    final expected = [
      'task_id',
      '目標名',
      'タスク名',
      '開始日',
      '終了日',
      '進捗(%)',
      'ステータス',
      'メモ',
    ];
    for (var i = 0; i < expected.length; i++) {
      if (_cellToString(headerRow[i]) != expected[i]) return false;
    }
    return true;
  }

  /// セルの値を文字列として取得する.
  String _cellToString(Data? cell) {
    if (cell == null || cell.value == null) return '';
    final value = cell.value;
    if (value is IntCellValue) return value.value.toString();
    if (value is DoubleCellValue) return value.value.toString();
    return value.toString();
  }

  /// セルの値を整数として取得する.
  int? _cellToInt(Data? cell) {
    if (cell == null || cell.value == null) return null;
    final value = cell.value;
    if (value is IntCellValue) return value.value;
    if (value is DoubleCellValue) return value.value.toInt();
    return int.tryParse(value.toString());
  }
}
