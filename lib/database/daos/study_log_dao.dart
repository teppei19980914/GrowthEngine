/// 活動ログDAO.
library;

import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/study_logs_table.dart';

part 'study_log_dao.g.dart';

/// StudyLogのCRUD操作を提供するDAO.
@DriftAccessor(tables: [StudyLogs])
class StudyLogDao extends DatabaseAccessor<AppDatabase>
    with _$StudyLogDaoMixin {
  /// StudyLogDaoを作成する.
  StudyLogDao(super.db);

  /// 全StudyLogを取得する.
  Future<List<StudyLog>> getAll() => select(studyLogs).get();

  /// Task IDでStudyLogをフィルタ取得する（日付順）.
  Future<List<StudyLog>> getByTaskId(String taskId) =>
      (select(studyLogs)
            ..where((t) => t.taskId.equals(taskId))
            ..orderBy([(t) => OrderingTerm.asc(t.studyDate)]))
          .get();

  /// 複数のTask IDでStudyLogを一括取得する（日付順）.
  Future<List<StudyLog>> getByTaskIds(List<String> taskIds) =>
      (select(studyLogs)
            ..where((t) => t.taskId.isIn(taskIds))
            ..orderBy([(t) => OrderingTerm.asc(t.studyDate)]))
          .get();

  /// StudyLogを追加する.
  Future<void> insertStudyLog(StudyLogsCompanion log) =>
      into(studyLogs).insert(log);

  /// StudyLogを更新する.
  Future<bool> updateStudyLog(StudyLogsCompanion log) async {
    final count = await (update(studyLogs)
          ..where((t) => t.id.equals(log.id.value)))
        .write(log);
    return count > 0;
  }

  /// StudyLogを削除する.
  Future<bool> deleteById(String logId) async {
    final count =
        await (delete(studyLogs)..where((t) => t.id.equals(logId))).go();
    return count > 0;
  }

  /// Task IDに紐づくStudyLogを全削除する.
  Future<int> deleteByTaskId(String taskId) =>
      (delete(studyLogs)..where((t) => t.taskId.equals(taskId))).go();

  /// 全活動ログの合計時間（分）を取得する.
  Future<int> getTotalMinutes() async {
    final sum = studyLogs.durationMinutes.sum();
    final query = selectOnly(studyLogs)..addColumns([sum]);
    final result = await query.getSingle();
    return result.read(sum) ?? 0;
  }
}
