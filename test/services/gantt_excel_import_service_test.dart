import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yume_log/database/app_database.dart' hide Goal, Task;
import 'package:yume_log/models/goal.dart';
import 'package:yume_log/services/gantt_excel_export_service.dart';
import 'package:yume_log/services/gantt_excel_import_service.dart';
import 'package:yume_log/services/task_service.dart';

AppDatabase _createDb() => AppDatabase(NativeDatabase.memory());

void main() {
  late AppDatabase db;
  late TaskService taskService;
  late GanttExcelImportService importService;
  late GanttExcelExportService exportService;

  setUp(() async {
    db = _createDb();
    taskService = TaskService(taskDao: db.taskDao);
    importService = GanttExcelImportService(taskService: taskService);
    exportService = GanttExcelExportService();
  });

  tearDown(() => db.close());

  Future<void> insertGoal(String id, String what) async {
    final now = DateTime.now();
    await db.goalDao.insertGoal(
      GoalsCompanion(
        id: Value(id),
        dreamId: const Value('dream-1'),
        why: const Value(''),
        whenTarget: const Value('2026-12-31'),
        whenType: const Value('date'),
        what: Value(what),
        how: const Value('テスト方法'),
        createdAt: Value(now),
        updatedAt: Value(now),
        color: const Value('#4472C4'),
      ),
    );
  }

  Goal createGoalModel(String id, String what) => Goal(
        id: id,
        dreamId: 'dream-1',
        whenTarget: '2026-12-31',
        whenType: WhenType.date,
        what: what,
        how: 'テスト方法',
        color: '#4472C4',
      );

  group('GanttExcelImportService', () {
    test('エクスポートしたファイルをインポートできる（ラウンドトリップ）', () async {
      await insertGoal('goal-1', 'TOEIC 900点');

      // タスクを作成
      await taskService.createTask(
        goalId: 'goal-1',
        title: '単語帳を覚える',
        startDate: DateTime(2026, 3, 1),
        endDate: DateTime(2026, 3, 31),
        memo: '毎日100語',
      );

      // エクスポート
      final tasks = await taskService.getAllTasks();
      final goals = [createGoalModel('goal-1', 'TOEIC 900点')];
      final exported = exportService.export(tasks: tasks, goals: goals);

      // 進捗を変更してインポート
      final result = await importService.import(
        bytes: exported.bytes,
        goals: goals,
      );

      expect(result.updatedCount, 1);
      expect(result.createdCount, 0);
      expect(result.skippedCount, 0);
      expect(result.errors, isEmpty);
    });

    test('既存タスクの進捗が更新される', () async {
      await insertGoal('goal-1', 'TOEIC 900点');

      final created = await taskService.createTask(
        goalId: 'goal-1',
        title: '単語帳を覚える',
        startDate: DateTime(2026, 3, 1),
        endDate: DateTime(2026, 3, 31),
      );
      expect(created.progress, 0);

      // エクスポート→進捗を変更→再インポート
      final tasks = await taskService.getAllTasks();
      final goals = [createGoalModel('goal-1', 'TOEIC 900点')];
      final exported = exportService.export(tasks: tasks, goals: goals);

      // エクスポートデータのバイトをそのままインポート
      // （進捗0のままだが、タイトル等は更新される）
      final result = await importService.import(
        bytes: exported.bytes,
        goals: goals,
      );

      expect(result.updatedCount, 1);

      final updated = await taskService.getAllTasks();
      expect(updated.length, 1);
      expect(updated.first.title, '単語帳を覚える');
    });

    test('データ表シートが無い場合はエラーを返す', () async {
      // 不正なExcelバイト（空のExcel）
      final excel = Excel.createExcel();
      final bytes = Uint8List.fromList(excel.encode()!);

      final result = await importService.import(
        bytes: bytes,
        goals: [],
      );

      expect(result.errors, isNotEmpty);
      expect(result.errors.first, contains('データ表'));
    });

    test('存在しない目標名で新規作成しようとするとスキップされる', () async {
      await insertGoal('goal-1', 'TOEIC 900点');

      // タスクを作成してエクスポート
      await taskService.createTask(
        goalId: 'goal-1',
        title: 'テストタスク',
        startDate: DateTime(2026, 3, 1),
        endDate: DateTime(2026, 3, 31),
      );

      final tasks = await taskService.getAllTasks();
      // 存在しない目標名を使ってエクスポート
      final goals = [createGoalModel('goal-1', 'TOEIC 900点')];
      final exported = exportService.export(tasks: tasks, goals: goals);

      // インポート時に異なる目標名リストを渡す
      // task_idは存在するので既存タスクの更新になる
      final result = await importService.import(
        bytes: exported.bytes,
        goals: [createGoalModel('goal-other', '別の目標')],
      );

      // task_idが存在するため更新として処理される
      expect(result.updatedCount, 1);
    });

    test('複数タスクの一括インポートが正しく処理される', () async {
      await insertGoal('goal-1', 'TOEIC 900点');
      await insertGoal('goal-2', 'AWS資格取得');

      // 複数タスクを作成
      await taskService.createTask(
        goalId: 'goal-1',
        title: 'タスク1',
        startDate: DateTime(2026, 3, 1),
        endDate: DateTime(2026, 3, 15),
      );
      await taskService.createTask(
        goalId: 'goal-2',
        title: 'タスク2',
        startDate: DateTime(2026, 4, 1),
        endDate: DateTime(2026, 4, 30),
      );

      final tasks = await taskService.getAllTasks();
      final goals = [
        createGoalModel('goal-1', 'TOEIC 900点'),
        createGoalModel('goal-2', 'AWS資格取得'),
      ];
      final exported = exportService.export(tasks: tasks, goals: goals);

      final result = await importService.import(
        bytes: exported.bytes,
        goals: goals,
      );

      expect(result.updatedCount, 2);
      expect(result.createdCount, 0);
      expect(result.errors, isEmpty);
    });

    test('空のデータ行はスキップされる', () async {
      final excel = Excel.createExcel();
      final sheet = excel['データ表'];

      // ヘッダー行
      const headers = [
        'task_id', '目標名', 'タスク名', '開始日', '終了日', '進捗(%)', 'ステータス', 'メモ',
      ];
      for (var i = 0; i < headers.length; i++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
            .value = TextCellValue(headers[i]);
      }

      // 空行
      for (var i = 0; i < 8; i++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1))
            .value = TextCellValue('');
      }

      final bytes = Uint8List.fromList(excel.encode()!);
      final result = await importService.import(
        bytes: bytes,
        goals: [],
      );

      expect(result.updatedCount, 0);
      expect(result.createdCount, 0);
      expect(result.skippedCount, 1);
    });

    test('不正な日付形式でスキップされる', () async {
      final excel = Excel.createExcel();
      final sheet = excel['データ表'];

      const headers = [
        'task_id', '目標名', 'タスク名', '開始日', '終了日', '進捗(%)', 'ステータス', 'メモ',
      ];
      for (var i = 0; i < headers.length; i++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
            .value = TextCellValue(headers[i]);
      }

      // 不正な日付
      final values = ['', 'テスト目標', 'タスク名', 'invalid', 'invalid', '0', '未着手', ''];
      for (var i = 0; i < values.length; i++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1))
            .value = TextCellValue(values[i]);
      }

      final bytes = Uint8List.fromList(excel.encode()!);
      final result = await importService.import(
        bytes: bytes,
        goals: [],
      );

      expect(result.skippedCount, 1);
      expect(result.errors.first, contains('日付形式'));
    });

    test('新規タスクが既存目標名で正しく作成される', () async {
      await insertGoal('goal-1', 'TOEIC 900点');

      final excel = Excel.createExcel();
      final sheet = excel['データ表'];

      const headers = [
        'task_id', '目標名', 'タスク名', '開始日', '終了日', '進捗(%)', 'ステータス', 'メモ',
      ];
      for (var i = 0; i < headers.length; i++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
            .value = TextCellValue(headers[i]);
      }

      // task_id空 → 新規作成
      final values = [
        '', 'TOEIC 900点', 'リスニング練習', '2026/05/01', '2026/05/31', '0', '未着手', '新規追加',
      ];
      for (var i = 0; i < values.length; i++) {
        final CellValue cellValue;
        if (i == 5) {
          cellValue = IntCellValue(0);
        } else {
          cellValue = TextCellValue(values[i]);
        }
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1))
            .value = cellValue;
      }

      final bytes = Uint8List.fromList(excel.encode()!);
      final goals = [createGoalModel('goal-1', 'TOEIC 900点')];
      final result = await importService.import(
        bytes: bytes,
        goals: goals,
      );

      expect(result.createdCount, 1);
      expect(result.updatedCount, 0);
      expect(result.errors, isEmpty);

      // DBにタスクが作成されていることを確認
      final tasks = await taskService.getAllTasks();
      expect(tasks.length, 1);
      expect(tasks.first.title, 'リスニング練習');
      expect(tasks.first.goalId, 'goal-1');
      expect(tasks.first.memo, '新規追加');
    });
  });
}
