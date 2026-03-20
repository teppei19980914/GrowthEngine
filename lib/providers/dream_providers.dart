/// 夢関連のProvider定義.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/dream.dart';
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
  }

  /// Dreamを削除する.
  Future<void> deleteDream(String dreamId) async {
    final service = ref.read(dreamServiceProvider);
    await service.deleteDream(dreamId);
    ref.invalidateSelf();
  }
}
