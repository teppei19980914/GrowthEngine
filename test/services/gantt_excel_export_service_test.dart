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

  group('GanttExcelExportService', () {
    test('空のタスクでもエクスポートできる', () {
      final result = service.export(tasks: [], goals: []);
      expect(result.bytes, isNotEmpty);
      expect(result.fileName, startsWith('gantt_'));
      expect(result.fileName, endsWith('.xlsx'));
    });

    test('ファイル名に日付が含まれる', () {
      final result = service.export(tasks: [], goals: []);
      // gantt_YYYYMMDD.xlsx 形式
      expect(result.fileName, matches(RegExp(r'gantt_\d{8}\.xlsx')));
    });

    test('データ表シートが作成される', () {
      final tasks = createTestTasks();
      final goals = createTestGoals();
      final result = service.export(tasks: tasks, goals: goals);

      final excel = Excel.decodeBytes(result.bytes);
      expect(excel.tables.containsKey('データ表'), isTrue);
    });

    test('ガントチャートシートが作成される', () {
      final tasks = createTestTasks();
      final goals = createTestGoals();
      final result = service.export(tasks: tasks, goals: goals);

      final excel = Excel.decodeBytes(result.bytes);
      expect(excel.tables.containsKey('ガントチャート'), isTrue);
    });

    test('データ表のヘッダー行が正しい', () {
      final tasks = createTestTasks();
      final goals = createTestGoals();
      final result = service.export(tasks: tasks, goals: goals);

      final excel = Excel.decodeBytes(result.bytes);
      final sheet = excel.tables['データ表']!;
      final headerRow = sheet.row(0);

      expect(_cellText(headerRow[0]), 'task_id');
      expect(_cellText(headerRow[1]), '目標名');
      expect(_cellText(headerRow[2]), 'タスク名');
      expect(_cellText(headerRow[3]), '開始日');
      expect(_cellText(headerRow[4]), '終了日');
      expect(_cellText(headerRow[5]), '進捗(%)');
      expect(_cellText(headerRow[6]), 'ステータス');
      expect(_cellText(headerRow[7]), 'メモ');
    });

    test('データ表にタスクデータが含まれる', () {
      final tasks = createTestTasks();
      final goals = createTestGoals();
      final result = service.export(tasks: tasks, goals: goals);

      final excel = Excel.decodeBytes(result.bytes);
      final sheet = excel.tables['データ表']!;

      // ヘッダー + 3タスク = 4行
      expect(sheet.maxRows, 4);
    });

    test('データ表のタスク行が正しい値を含む', () {
      final tasks = [createTestTasks().first];
      final goals = createTestGoals();
      final result = service.export(tasks: tasks, goals: goals);

      final excel = Excel.decodeBytes(result.bytes);
      final sheet = excel.tables['データ表']!;
      final dataRow = sheet.row(1);

      expect(_cellText(dataRow[0]), 'task-1');
      expect(_cellText(dataRow[1]), 'TOEIC 900点');
      expect(_cellText(dataRow[2]), '単語帳を覚える');
      expect(_cellText(dataRow[3]), '2026/03/01');
      expect(_cellText(dataRow[4]), '2026/03/31');
      expect(_cellInt(dataRow[5]), 45);
      expect(_cellText(dataRow[6]), '進行中');
      expect(_cellText(dataRow[7]), '毎日100語');
    });

    test('ステータスが日本語で表示される', () {
      final goals = createTestGoals();
      final tasks = [
        Task(
          id: 't1',
          goalId: 'goal-1',
          title: 'タスク1',
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 1, 31),
          progress: 0,
        ),
        Task(
          id: 't2',
          goalId: 'goal-1',
          title: 'タスク2',
          startDate: DateTime(2026, 2, 1),
          endDate: DateTime(2026, 2, 28),
          status: TaskStatus.inProgress,
          progress: 50,
        ),
        Task(
          id: 't3',
          goalId: 'goal-1',
          title: 'タスク3',
          startDate: DateTime(2026, 3, 1),
          endDate: DateTime(2026, 3, 31),
          status: TaskStatus.completed,
          progress: 100,
        ),
      ];

      final result = service.export(tasks: tasks, goals: goals);
      final excel = Excel.decodeBytes(result.bytes);
      final sheet = excel.tables['データ表']!;

      expect(_cellText(sheet.row(1)[6]), '未着手');
      expect(_cellText(sheet.row(2)[6]), '進行中');
      expect(_cellText(sheet.row(3)[6]), '完了');
    });

    test('ガントチャートシートに固定列がある', () {
      final tasks = createTestTasks();
      final goals = createTestGoals();
      final result = service.export(tasks: tasks, goals: goals);

      final excel = Excel.decodeBytes(result.bytes);
      final sheet = excel.tables['ガントチャート']!;
      final headerRow = sheet.row(0);

      expect(_cellText(headerRow[0]), '目標名');
      expect(_cellText(headerRow[1]), 'タスク名');
      expect(_cellText(headerRow[2]), '進捗(%)');
    });

    test('ガントチャートシートに日付ヘッダーがある', () {
      final tasks = [
        Task(
          id: 'task-1',
          goalId: 'goal-1',
          title: 'テスト',
          startDate: DateTime(2026, 3, 1),
          endDate: DateTime(2026, 3, 3),
          progress: 0,
        ),
      ];
      final goals = createTestGoals();
      final result = service.export(tasks: tasks, goals: goals);

      final excel = Excel.decodeBytes(result.bytes);
      final sheet = excel.tables['ガントチャート']!;
      final headerRow = sheet.row(0);

      // 固定3列 + 日付列
      expect(_cellText(headerRow[3]), '3/1');
      expect(_cellText(headerRow[4]), '3/2');
      expect(_cellText(headerRow[5]), '3/3');
    });

    test('目標が見つからないタスクは「不明」と表示される', () {
      final tasks = [
        Task(
          id: 'task-x',
          goalId: 'unknown-goal',
          title: 'テスト',
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 1, 31),
          progress: 0,
        ),
      ];
      final result = service.export(tasks: tasks, goals: []);

      final excel = Excel.decodeBytes(result.bytes);
      final sheet = excel.tables['データ表']!;
      expect(_cellText(sheet.row(1)[1]), '不明');
    });

    test('書籍タスクの目標名は「書籍」と表示される', () {
      final tasks = [
        Task(
          id: 'task-book',
          goalId: bookGanttGoalId,
          title: '読書スケジュール',
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 1, 31),
          progress: 30,
        ),
      ];
      final result = service.export(tasks: tasks, goals: []);

      final excel = Excel.decodeBytes(result.bytes);
      final sheet = excel.tables['データ表']!;
      expect(_cellText(sheet.row(1)[1]), '書籍');
    });
  });
}

String _cellText(Data? cell) {
  return cell?.value?.toString() ?? '';
}

int? _cellInt(Data? cell) {
  if (cell?.value is IntCellValue) {
    return (cell!.value! as IntCellValue).value;
  }
  return null;
}
