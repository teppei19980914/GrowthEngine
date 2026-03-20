/// マイルストーン（実績）ボタン.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/dashboard_providers.dart';
import '../../providers/theme_provider.dart';
import 'milestone_popup.dart';

/// 前回確認した実績数の保存キー.
const _seenCountKey = 'milestone_seen_count';

/// AppBarに表示するマイルストーンボタン（未確認バッジ付き）.
class MilestoneButton extends ConsumerWidget {
  /// MilestoneButtonを作成する.
  const MilestoneButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final milestoneAsync = ref.watch(milestoneDataProvider);
    final prefs = ref.watch(sharedPreferencesProvider);
    final seenCount = prefs.getInt(_seenCountKey) ?? 0;
    final achievedCount = milestoneAsync.valueOrNull?.achieved.length ?? 0;
    final unseenCount = (achievedCount - seenCount).clamp(0, 99);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.emoji_events_outlined),
          tooltip: '実績',
          onPressed: () async {
            final data = milestoneAsync.valueOrNull;
            if (data == null) return;

            // 確認済みとして保存
            await prefs.setInt(_seenCountKey, data.achieved.length);
            // ignore: unused_result
            ref.refresh(milestoneDataProvider);

            if (!context.mounted) return;
            await showDialog(
              context: context,
              builder: (_) => MilestonePopup(data: data),
            );
          },
        ),
        if (unseenCount > 0)
          Positioned(
            right: 4,
            top: 4,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(
                  '$unseenCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
