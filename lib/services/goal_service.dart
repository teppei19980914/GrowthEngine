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
  bool _sortOrderMigrated = false;

  /// sortOrderカラムが存在しない場合に追加する.
  Future<void> _ensureSortOrderColumn() async {
    if (_sortOrderMigrated) return;
    try {
      await _goalDao.attachedDatabase.customStatement(
        'ALTER TABLE goals ADD COLUMN sort_order INTEGER NOT NULL DEFAULT 0',
      );
    } on Object {
      // カラムが既に存在する場合は無視
    }
    _sortOrderMigrated = true;
  }

  /// sortOrderカラム未追加による例外を防御しつつ全Goalを取得する.
  Future<List<db.Goal>> _getAllRowsSafe() async {
    try {
      return await _goalDao.getAll();
    } on Object {
      await _ensureSortOrderColumn();
      return _goalDao.getAll();
    }
  }

  /// 全Goalを取得する.
  Future<List<Goal>> getAllGoals() async {
    final rows = await _getAllRowsSafe();
    return rows.map(_rowToGoal).toList();
  }

  /// IDでGoalを取得する.
  Future<Goal?> getGoal(String goalId) async {
    try {
      final row = await _goalDao.getById(goalId);
      return row != null ? _rowToGoal(row) : null;
    } on Object {
      await _ensureSortOrderColumn();
      final row = await _goalDao.getById(goalId);
      return row != null ? _rowToGoal(row) : null;
    }
  }

  /// 指定した夢に紐づくGoalを取得する.
  Future<List<Goal>> getGoalsForDream(String dreamId) async {
    final all = await _getAllRowsSafe();
    return all.where((g) => g.dreamId == dreamId).map(_rowToGoal).toList();
  }

  /// 夢に紐づかない独立Goalを取得する.
  Future<List<Goal>> getStandaloneGoals() async {
    final all = await _getAllRowsSafe();
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

  /// 目標の並び順を一括更新する.
  Future<void> updateGoalOrders(List<(String goalId, int sortOrder)> orders) async {
    // 全目標を一括取得してN+1を回避
    final allGoals = await _goalDao.getAll();
    final goalMap = {for (final g in allGoals) g.id: g};

    for (final (goalId, sortOrder) in orders) {
      final existing = goalMap[goalId];
      if (existing == null) continue;
      final updated = _rowToGoal(existing).copyWith(sortOrder: sortOrder);
      await _goalDao.updateGoal(_goalToCompanion(updated));
    }
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
      sortOrder: row.sortOrder,
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
      sortOrder: Value(goal.sortOrder),
      createdAt: Value(goal.createdAt),
      updatedAt: Value(goal.updatedAt),
    );
  }
}
