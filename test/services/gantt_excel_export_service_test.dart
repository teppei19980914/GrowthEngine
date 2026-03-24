import 'dart:convert';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yume_log/models/goal.dart';
import 'package:yume_log/models/task.dart';
import 'package:yume_log/services/gantt_excel_export_service.dart';

void main() {
  late GanttExcelExportService service;

  setUp(() {
    service = GanttExcelExportService();
  });

  List<Goal> createTestGoals() => [
        Goal(
          id: 'goal-1',
          dreamId: 'dream-1',
          whenTarget: '2026-12-31',
          whenType: WhenType.date,
          what: 'TOEIC 900点',
          how: '毎日1時間',
          color: '#4472C4',
        ),
        Goal(
          id: 'goal-2',
          dreamId: 'dream-1',
          whenTarget: '2026-06-30',
          whenType: WhenType.date,
          what: 'AWS資格取得',
          how: '週末に学習',
          color: '#ED7D31',
        ),
      ];

  List<Task> createTestTasks() => [
        Task(
          id: 'task-1',
          goalId: 'goal-1',
          title: '単語帳を覚える',
          startDate: DateTime(2026, 3, 1),
          endDate: DateTime(2026, 3, 31),
          status: TaskStatus.inProgress,
          progress: 45,
          memo: '毎日100語',
        ),
        Task(
          id: 'task-2',
          goalId: 'goal-1',
          title: '公式問題集',
          startDate: DateTime(2026, 4, 1),
          endDate: DateTime(2026, 4, 30),
          progress: 0,
        ),
        Task(
          id: 'task-3',
          goalId: 'goal-2',
          title: '教材学習',
          startDate: DateTime(2026, 3, 15),
          endDate: DateTime(2026, 5, 15),
          status: TaskStatus.completed,
          progress: 100,
        ),
      ];

  group('Excel形式', () {
    test('空のタスクでもエクスポートできる', () {
      final result = service.exportAs(
        tasks: [],
        goals: [],
        format: 'excel',
      );
      expect(result.bytes, isNotEmpty);
      expect(result.fileName, endsWith('.xlsx'));
    });

    test('ファイル名に日付が含まれる', () {
      final result = service.exportAs(
        tasks: [],
        goals: [],
        format: 'excel',
      );
      expect(result.fileName, matches(RegExp(r'gantt_\d{8}\.xlsx')));
    });

    test('ガントチャートシートが作成される', () {
      final tasks = createTestTasks();
      final goals = createTestGoals();
      final result = service.exportAs(
        tasks: tasks,
        goals: goals,
        format: 'excel',
      );

      final excel = Excel.decodeBytes(result.bytes);
      expect(excel.tables.containsKey('ガントチャート'), isTrue);
    });

    test('ヘッダー行に固定列と日付列が含まれる', () {
      final tasks = createTestTasks();
      final goals = createTestGoals();
      final result = service.exportAs(
        tasks: tasks,
        goals: goals,
        format: 'excel',
      );

      final excel = Excel.decodeBytes(result.bytes);
      final sheet = excel.tables['ガントチャート']!;
      final headerRow = sheet.row(0);

      expect(_cellText(headerRow[0]), '目標名');
      expect(_cellText(headerRow[1]), 'タスク名');
      expect(_cellText(headerRow[2]), '進捗(%)');
      expect(_cellText(headerRow[3]), 'ステータス');
      expect(_cellText(headerRow[4]), '開始日');
      expect(_cellText(headerRow[5]), '終了日');
      // 日付列も存在する
      expect(headerRow.length, greaterThan(6));
    });

    test('タスク行が正しく出力される', () {
      final tasks = createTestTasks();
      final goals = createTestGoals();
      final result = service.exportAs(
        tasks: tasks,
        goals: goals,
        format: 'excel',
      );

      final excel = Excel.decodeBytes(result.bytes);
      final sheet = excel.tables['ガントチャート']!;

      // ヘッダー(1) + タスク(3) + マイルストーン(2) = 6行
      expect(sheet.maxRows, 6);
    });

    test('目標が見つからないタスクは「不明」と表示される', () {
      final tasks = [
        Task(
          id: 'task-x',
          goalId: 'unknown-goal',
          title: 'テスト',
          startDate: DateTime(2026, 3, 1),
          endDate: DateTime(2026, 3, 10),
        ),
      ];
      final result = service.exportAs(
        tasks: tasks,
        goals: [],
        format: 'excel',
      );

      final excel = Excel.decodeBytes(result.bytes);
      final sheet = excel.tables['ガントチャート']!;
      expect(_cellText(sheet.row(1)[0]), '不明');
    });
  });

  group('HTML形式', () {
    test('HTMLファイルが生成される', () {
      final result = service.exportAs(
        tasks: createTestTasks(),
        goals: createTestGoals(),
        format: 'html',
      );
      expect(result.fileName, endsWith('.html'));
      expect(result.mimeType, 'text/html');

      final html = utf8.decode(result.bytes);
      expect(html, contains('<!DOCTYPE html>'));
      expect(html, contains('ガントチャート'));
    });

    test('タスク名が含まれる', () {
      final result = service.exportAs(
        tasks: createTestTasks(),
        goals: createTestGoals(),
        format: 'html',
      );
      final html = utf8.decode(result.bytes);
      expect(html, contains('単語帳を覚える'));
      expect(html, contains('公式問題集'));
    });
  });

  group('CSV形式', () {
    test('CSVファイルが生成される', () {
      final result = service.exportAs(
        tasks: createTestTasks(),
        goals: createTestGoals(),
        format: 'csv',
      );
      expect(result.fileName, endsWith('.csv'));

      final csv = utf8.decode(result.bytes);
      expect(csv, contains('目標名'));
      expect(csv, contains('タスク名'));
    });
  });

  group('マイルストーン', () {
    test('HTMLにマイルストーン行が含まれる', () {
      final result = service.exportAs(
        tasks: createTestTasks(),
        goals: createTestGoals(),
        format: 'html',
      );
      final html = utf8.decode(result.bytes);
      // goal-1 has whenType=date, whenTarget='2026-12-31' => milestone
      expect(html, contains('マイルストーン'));
      expect(html, contains('TOEIC 900点'));
    });

    test('CSVにマイルストーン行が含まれる', () {
      final result = service.exportAs(
        tasks: createTestTasks(),
        goals: createTestGoals(),
        format: 'csv',
      );
      final csv = utf8.decode(result.bytes);
      expect(csv, contains('マイルストーン'));
    });

    test('Excelにマイルストーン行が含まれる', () {
      final tasks = createTestTasks();
      final goals = createTestGoals();
      final result = service.exportAs(
        tasks: tasks,
        goals: goals,
        format: 'excel',
      );

      final excel = Excel.decodeBytes(result.bytes);
      final sheet = excel.tables['ガントチャート']!;
      // ヘッダー(1) + タスク(3) + マイルストーン(2) = 6行
      expect(sheet.maxRows, 6);
    });

    test('日付指定でない目標はマイルストーンに含まれない', () {
      final goals = [
        Goal(
          id: 'goal-p',
          dreamId: 'dream-1',
          whenTarget: '3ヶ月以内',
          whenType: WhenType.period,
          what: '期間目標',
          how: 'テスト',
          color: '#4472C4',
        ),
      ];
      final tasks = [
        Task(
          id: 'task-p',
          goalId: 'goal-p',
          title: 'テスト',
          startDate: DateTime(2026, 3, 1),
          endDate: DateTime(2026, 3, 31),
        ),
      ];
      final result = service.exportAs(
        tasks: tasks,
        goals: goals,
        format: 'csv',
      );
      final csv = utf8.decode(result.bytes);
      expect(csv, isNot(contains('マイルストーン')));
    });
  });

  group('後方互換', () {
    test('exportメソッドがExcel形式を返す', () {
      final result = service.export(
        tasks: createTestTasks(),
        goals: createTestGoals(),
      );
      expect(result.fileName, endsWith('.xlsx'));
    });
  });
}

String _cellText(Data? cell) {
  if (cell == null || cell.value == null) return '';
  return cell.value.toString();
}
