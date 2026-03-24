/// 目標関連のProvider定義.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/goal.dart';
import 'service_providers.dart';

/// 目標ごとのタスク進捗（goalId → {total, completed}）.
final goalProgressProvider =
    FutureProvider<Map<String, ({int total, int completed})>>((ref) async {
  final taskService = ref.watch(taskServiceProvider);
  final goalService = ref.watch(goalServiceProvider);
  final goals = await goalService.getAllGoals();
  final result = <String, ({int total, int completed})>{};

  for (final goal in goals) {
    final tasks = await taskService.getTasksForGoal(goal.id);
    final completed =
        tasks.where((t) => t.progress >= 100).length;
    result[goal.id] = (total: tasks.length, completed: completed);
  }
  return result;
});

/// 全Goal一覧を取得・管理するProvider.
final goalListProvider =
    AsyncNotifierProvider<GoalListNotifier, List<Goal>>(GoalListNotifier.new);

/// GoalListのNotifier.
class GoalListNotifier extends AsyncNotifier<List<Goal>> {
  @override
  Future<List<Goal>> build() async {
    final service = ref.watch(goalServiceProvider);
    return service.getAllGoals();
  }

  /// Goalを作成し、作成されたGoalのIDを返す.
  Future<String> createGoal({
    String dreamId = '',
    required String whenTarget,
    required WhenType whenType,
    required String what,
    required String how,
  }) async {
    final service = ref.read(goalServiceProvider);
    final goal = await service.createGoal(
      dreamId: dreamId,
      whenTarget: whenTarget,
      whenType: whenType,
      what: what,
      how: how,
    );
    ref.invalidateSelf();
    return goal.id;
  }

  /// Goalを更新する.
  Future<void> updateGoal({
    required String goalId,
    String dreamId = '',
    required String whenTarget,
    required WhenType whenType,
    required String what,
    required String how,
  }) async {
    final service = ref.read(goalServiceProvider);
    await service.updateGoal(
      goalId: goalId,
      dreamId: dreamId,
      whenTarget: whenTarget,
      whenType: whenType,
      what: what,
      how: how,
    );
    ref.invalidateSelf();
  }

  /// Goalを削除する.
  Future<void> deleteGoal(String goalId) async {
    final service = ref.read(goalServiceProvider);
    await service.deleteGoal(goalId);
    ref.invalidateSelf();
  }

  /// 目標の並び順を更新する.
  Future<void> reorderGoals(List<(String goalId, int sortOrder)> orders) async {
    final service = ref.read(goalServiceProvider);
    await service.updateGoalOrders(orders);
    ref.invalidateSelf();
  }
}
