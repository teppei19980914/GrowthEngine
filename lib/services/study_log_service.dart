/// 活動ログのビジネスロジック.
library;

import 'package:drift/drift.dart';

import '../database/app_database.dart' as db;
import '../database/daos/study_log_dao.dart';
import '../models/study_log.dart';
import 'study_stats_types.dart';

/// StudyLogのCRUD操作とビジネスロジックを提供するサービス.
class StudyLogService {
  /// StudyLogServiceを作成する.
  StudyLogService({required StudyLogDao studyLogDao})
      : _studyLogDao = studyLogDao;

  final StudyLogDao _studyLogDao;

  /// 活動ログを追加する.
  Future<StudyLog> addStudyLog({
    required String taskId,
    required DateTime studyDate,
    required int durationMinutes,
    String memo = '',
    String taskName = '',
  }) async {
    final log = StudyLog(
      taskId: taskId,
      studyDate: studyDate,
      durationMinutes: durationMinutes,
      memo: memo,
      taskName: taskName,
    );
    await _studyLogDao.insertStudyLog(_logToCompanion(log));
    return log;
  }

  /// Task IDに紐づくログを取得する.
  Future<List<StudyLog>> getLogsForTask(String taskId) async {
    final rows = await _studyLogDao.getByTaskId(taskId);
    return rows.map(_rowToLog).toList();
  }

  /// 全ログを取得する.
  Future<List<StudyLog>> getAllLogs() async {
    final rows = await _studyLogDao.getAll();
    return rows.map(_rowToLog).toList();
  }

  /// ログを削除する.
  Future<bool> deleteLog(String logId) => _studyLogDao.deleteById(logId);

  /// タスク別統計を計算する.
  Future<TaskStudyStats> getTaskStats(String taskId) async {
    final logs = await _studyLogDao.getByTaskId(taskId);
    return _calculateTaskStats(taskId, logs);
  }

  /// 目標別統計を計算する.
  Future<GoalStudyStats> getGoalStats(
    String goalId,
    List<String> taskIds,
  ) async {
    final logs = await _studyLogDao.getByTaskIds(taskIds);
    final taskGroups = <String, List<db.StudyLog>>{};
    for (final log in logs) {
      taskGroups.putIfAbsent(log.taskId, () => []).add(log);
    }

    final taskStats = <TaskStudyStats>[];
    for (final taskId in taskIds) {
      final taskLogs = taskGroups[taskId] ?? [];
      taskStats.add(_calculateTaskStats(taskId, taskLogs));
    }

    final totalMinutes = taskStats.fold<int>(
      0,
      (sum, s) => sum + s.totalMinutes,
    );
    final allDates = <DateTime>{};
    for (final log in logs) {
      allDates.add(
        DateTime(log.studyDate.year, log.studyDate.month, log.studyDate.day),
      );
    }

    return GoalStudyStats(
      goalId: goalId,
      taskStats: taskStats,
      totalMinutes: totalMinutes,
      totalStudyDays: allDates.length,
    );
  }

  /// 空のtaskNameを埋めるバックフィル処理.
  Future<int> backfillTaskNames(Map<String, String> taskNameMap) async {
    final allLogs = await _studyLogDao.getAll();
    var count = 0;
    for (final log in allLogs) {
      if (log.taskName.isEmpty && taskNameMap.containsKey(log.taskId)) {
        await _studyLogDao.updateStudyLog(
          db.StudyLogsCompanion(
            id: Value(log.id),
            taskName: Value(taskNameMap[log.taskId]!),
          ),
        );
        count++;
      }
    }
    return count;
  }

  TaskStudyStats _calculateTaskStats(String taskId, List<db.StudyLog> logs) {
    final totalMinutes = logs.fold<int>(0, (sum, l) => sum + l.durationMinutes);
    final uniqueDates = <DateTime>{};
    for (final log in logs) {
      uniqueDates.add(
        DateTime(log.studyDate.year, log.studyDate.month, log.studyDate.day),
      );
    }
    return TaskStudyStats(
      taskId: taskId,
      totalMinutes: totalMinutes,
      studyDays: uniqueDates.length,
      logCount: logs.length,
    );
  }

  StudyLog _rowToLog(db.StudyLog row) {
    return StudyLog(
      id: row.id,
      taskId: row.taskId,
      studyDate: row.studyDate,
      durationMinutes: row.durationMinutes,
      memo: row.memo,
      taskName: row.taskName,
      createdAt: row.createdAt,
    );
  }

  db.StudyLogsCompanion _logToCompanion(StudyLog log) {
    return db.StudyLogsCompanion(
      id: Value(log.id),
      taskId: Value(log.taskId),
      studyDate: Value(log.studyDate),
      durationMinutes: Value(log.durationMinutes),
      memo: Value(log.memo),
      taskName: Value(log.taskName),
      createdAt: Value(log.createdAt),
    );
  }
}
