/// 目標のビジネスロジック.
library;

import 'package:drift/drift.dart';

import '../database/app_database.dart' as db;
import '../database/daos/goal_dao.dart';
import '../database/daos/task_dao.dart';
import '../models/goal.dart';

/// GoalのCRUD操作とビジネスロジックを提供するサービス.
class GoalService {
  /// GoalServiceを作成する.
  GoalService({required GoalDao goalDao, required TaskDao taskDao})
      : _goalDao = goalDao,
        _taskDao = taskDao;

  final GoalDao _goalDao;
  final TaskDao _taskDao;

  /// 全Goalを取得する.
  Future<List<Goal>> getAllGoals() async {
    final rows = await _goalDao.getAll();
    return rows.map(_rowToGoal).toList();
  }

  /// IDでGoalを取得する.
  Future<Goal?> getGoal(String goalId) async {
    final row = await _goalDao.getById(goalId);
    return row != null ? _rowToGoal(row) : null;
  }

  /// 指定した夢に紐づくGoalを取得する.
  Future<List<Goal>> getGoalsForDream(String dreamId) async {
    final all = await _goalDao.getAll();
    return all.where((g) => g.dreamId == dreamId).map(_rowToGoal).toList();
  }

  /// 夢に紐づかない独立Goalを取得する.
  Future<List<Goal>> getStandaloneGoals() async {
    final all = await _goalDao.getAll();
    return all.where((g) => g.dreamId.isEmpty).map(_rowToGoal).toList();
  }

  /// Goalを作成する.
  ///
  /// [dreamId]を省略すると独立した目標（夢に紐づかない目標）になる.
  Future<Goal> createGoal({
    String dreamId = '',
    required String whenTarget,
    required WhenType whenType,
    required String what,
    required String how,
  }) async {
    _validateFields({
      'whenTarget': whenTarget,
      'what': what,
      'how': how,
    });
    final color = await _assignColor();
    final goal = Goal(
      dreamId: dreamId,
      whenTarget: whenTarget,
      whenType: whenType,
      what: what,
      how: how,
      color: color,
    );
    await _goalDao.insertGoal(_goalToCompanion(goal));
    return goal;
  }

  /// Goalを更新する.
  Future<Goal?> updateGoal({
    required String goalId,
    String dreamId = '',
    required String whenTarget,
    required WhenType whenType,
    required String what,
    required String how,
  }) async {
    _validateFields({
      'whenTarget': whenTarget,
      'what': what,
      'how': how,
    });
    final existing = await _goalDao.getById(goalId);
    if (existing == null) return null;

    final updated = _rowToGoal(existing).copyWith(
      dreamId: dreamId,
      whenTarget: whenTarget,
      whenType: whenType,
      what: what,
      how: how,
      updatedAt: DateTime.now(),
    );
    await _goalDao.updateGoal(_goalToCompanion(updated));
    return updated;
  }

  /// Goalを削除する（紐づくTaskもカスケード削除）.
  Future<bool> deleteGoal(String goalId) async {
    await _taskDao.deleteByGoalId(goalId);
    return _goalDao.deleteById(goalId);
  }

  void _validateFields(Map<String, String> fields) {
    for (final entry in fields.entries) {
      if (entry.value.trim().isEmpty) {
        throw ArgumentError('${entry.key}は必須です');
      }
    }
  }

  Future<String> _assignColor() async {
    final goals = await _goalDao.getAll();
    final usedColors = goals.map((g) => g.color).toSet();
    for (final color in goalColors) {
      if (!usedColors.contains(color)) return color;
    }
    return goalColors[goals.length % goalColors.length];
  }

  Goal _rowToGoal(db.Goal row) {
    return Goal(
      id: row.id,
      dreamId: row.dreamId,
      why: row.why,
      whenTarget: row.whenTarget,
      whenType: WhenType.fromValue(row.whenType),
      what: row.what,
      how: row.how,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      color: row.color,
    );
  }

  db.GoalsCompanion _goalToCompanion(Goal goal) {
    return db.GoalsCompanion(
      id: Value(goal.id),
      dreamId: Value(goal.dreamId),
      why: Value(goal.why),
      whenTarget: Value(goal.whenTarget),
      whenType: Value(goal.whenType.value),
      what: Value(goal.what),
      how: Value(goal.how),
      color: Value(goal.color),
      createdAt: Value(goal.createdAt),
      updatedAt: Value(goal.updatedAt),
    );
  }
}
