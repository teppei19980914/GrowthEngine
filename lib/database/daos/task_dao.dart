/// タスクDAO.
library;

import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tasks_table.dart';

part 'task_dao.g.dart';

/// TaskのCRUD操作を提供するDAO.
@DriftAccessor(tables: [Tasks])
class TaskDao extends DatabaseAccessor<AppDatabase> with _$TaskDaoMixin {
  /// TaskDaoを作成する.
  TaskDao(super.db);

  /// 全Taskを取得する.
  Future<List<Task>> getAll() => select(tasks).get();

  /// IDでTaskを取得する.
  Future<Task?> getById(String taskId) =>
      (select(tasks)..where((t) => t.id.equals(taskId))).getSingleOrNull();

  /// Goal IDでTaskをフィルタ取得する（order順）.
  Future<List<Task>> getByGoalId(String goalId) =>
      (select(tasks)
            ..where((t) => t.goalId.equals(goalId))
            ..orderBy([(t) => OrderingTerm.asc(t.order)]))
          .get();

  /// Book IDでTaskをフィルタ取得する（order順）.
  Future<List<Task>> getByBookId(String bookId) =>
      (select(tasks)
            ..where((t) => t.bookId.equals(bookId))
            ..orderBy([(t) => OrderingTerm.asc(t.order)]))
          .get();

  /// Taskを追加する.
  Future<void> insertTask(TasksCompanion task) => into(tasks).insert(task);

  /// Taskを更新する.
  Future<bool> updateTask(TasksCompanion task) async {
    final count = await (update(tasks)
          ..where((t) => t.id.equals(task.id.value)))
        .write(task);
    return count > 0;
  }

  /// Taskを削除する.
  Future<bool> deleteById(String taskId) async {
    final count =
        await (delete(tasks)..where((t) => t.id.equals(taskId))).go();
    return count > 0;
  }

  /// Goal IDに紐づくTaskを全削除する.
  Future<int> deleteByGoalId(String goalId) =>
      (delete(tasks)..where((t) => t.goalId.equals(goalId))).go();

  /// 完了済みかつ [threshold] より古い更新日時のタスクを物理削除する.
  ///
  /// タスクデータの肥大化を防ぐためのクリーンアップ処理.
  /// `status == 'completed'` のタスクのうち `updatedAt < threshold` のものを削除する.
  /// 未完了タスクは期間にかかわらず削除されない.
  /// ユーザーが残したい完了タスクは事前にエクスポートする運用（FAQに記載）.
  Future<int> deleteCompletedOlderThan(DateTime threshold) {
    return (delete(tasks)
          ..where((t) => t.status.equals('completed'))
          ..where((t) => t.updatedAt.isSmallerThanValue(threshold)))
        .go();
  }
}
