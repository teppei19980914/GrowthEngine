/// 目標関連のProvider定義.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/goal.dart';
import 'service_providers.dart';

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
    required String dreamId,
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
    required String dreamId,
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
}
