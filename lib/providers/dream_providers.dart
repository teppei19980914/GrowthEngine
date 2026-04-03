/// 夢関連のProvider定義.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/dream.dart';
import '../services/sync_manager.dart';
import 'service_providers.dart';

/// 全Dream一覧を取得・管理するProvider.
final dreamListProvider =
    AsyncNotifierProvider<DreamListNotifier, List<Dream>>(
        DreamListNotifier.new);

/// DreamListのNotifier.
class DreamListNotifier extends AsyncNotifier<List<Dream>> {
  @override
  Future<List<Dream>> build() async {
    final service = ref.watch(dreamServiceProvider);
    return service.getAllDreams();
  }

  /// Dreamを作成し、作成されたDreamのIDを返す.
  Future<String> createDream({
    required String title,
    String description = '',
    String why = '',
    String category = 'other',
  }) async {
    final service = ref.read(dreamServiceProvider);
    final dream = await service.createDream(
      title: title,
      description: description,
      why: why,
      category: category,
    );
    ref.invalidateSelf();
    SyncManager().requestSync();
    return dream.id;
  }

  /// Dreamを更新する.
  Future<void> updateDream({
    required String dreamId,
    required String title,
    String description = '',
    String why = '',
    String category = 'other',
  }) async {
    final service = ref.read(dreamServiceProvider);
    await service.updateDream(
      dreamId: dreamId,
      title: title,
      description: description,
      why: why,
      category: category,
    );
    ref.invalidateSelf();
    SyncManager().requestSync();
  }

  /// Dreamを削除する.
  Future<void> deleteDream(String dreamId) async {
    final service = ref.read(dreamServiceProvider);
    await service.deleteDream(dreamId);
    ref.invalidateSelf();
    SyncManager().requestSync();
  }

  /// 夢の並び順を更新する.
  Future<void> reorderDreams(
      List<(String dreamId, int sortOrder)> orders) async {
    final service = ref.read(dreamServiceProvider);
    await service.updateDreamOrders(orders);
    ref.invalidateSelf();
    SyncManager().requestSync();
  }
}
