/// 夢のビジネスロジック.
library;

import 'package:drift/drift.dart';

import '../database/app_database.dart' as db;
import '../database/daos/dream_dao.dart';
import '../database/daos/goal_dao.dart';
import '../database/daos/task_dao.dart';
import '../models/dream.dart';

/// DreamのCRUD操作とビジネスロジックを提供するサービス.
class DreamService {
  /// DreamServiceを作成する.
  DreamService({
    required DreamDao dreamDao,
    required GoalDao goalDao,
    required TaskDao taskDao,
  })  : _dreamDao = dreamDao,
        _goalDao = goalDao,
        _taskDao = taskDao;

  final DreamDao _dreamDao;
  final GoalDao _goalDao;
  final TaskDao _taskDao;

  /// 全Dreamを取得する.
  Future<List<Dream>> getAllDreams() async {
    final rows = await _dreamDao.getAll();
    return rows.map(_rowToDream).toList();
  }

  /// IDでDreamを取得する.
  Future<Dream?> getDream(String dreamId) async {
    final row = await _dreamDao.getById(dreamId);
    return row != null ? _rowToDream(row) : null;
  }

  /// Dreamを作成する.
  Future<Dream> createDream({
    required String title,
    String description = '',
    String why = '',
  }) async {
    if (title.trim().isEmpty) {
      throw ArgumentError('タイトルは必須です');
    }
    final dream = Dream(
      title: title.trim(),
      description: description.trim(),
      why: why.trim(),
    );
    await _dreamDao.insertDream(_dreamToCompanion(dream));
    return dream;
  }

  /// Dreamを更新する.
  Future<Dream?> updateDream({
    required String dreamId,
    required String title,
    String description = '',
    String why = '',
  }) async {
    if (title.trim().isEmpty) {
      throw ArgumentError('タイトルは必須です');
    }
    final existing = await _dreamDao.getById(dreamId);
    if (existing == null) return null;

    final updated = _rowToDream(existing).copyWith(
      title: title.trim(),
      description: description.trim(),
      why: why.trim(),
      updatedAt: DateTime.now(),
    );
    await _dreamDao.updateDream(_dreamToCompanion(updated));
    return updated;
  }

  /// Dreamを削除する（紐づくGoal・Taskもカスケード削除）.
  Future<bool> deleteDream(String dreamId) async {
    final goals = await _goalDao.getAll();
    final relatedGoals = goals.where((g) => g.dreamId == dreamId);
    for (final goal in relatedGoals) {
      await _taskDao.deleteByGoalId(goal.id);
      await _goalDao.deleteById(goal.id);
    }
    return _dreamDao.deleteById(dreamId);
  }

  Dream _rowToDream(db.Dream row) {
    return Dream(
      id: row.id,
      title: row.title,
      description: row.description,
      why: row.why,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  db.DreamsCompanion _dreamToCompanion(Dream dream) {
    return db.DreamsCompanion(
      id: Value(dream.id),
      title: Value(dream.title),
      description: Value(dream.description),
      why: Value(dream.why),
      createdAt: Value(dream.createdAt),
      updatedAt: Value(dream.updatedAt),
    );
  }
}
