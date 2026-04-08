/// ガントチャート完了タスク表示トグルの永続化テスト.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yume_hashi/providers/gantt_providers.dart';
import 'package:yume_hashi/providers/theme_provider.dart'
    show sharedPreferencesProvider;

void main() {
  group('ganttShowCompletedProvider', () {
    test('デフォルトは false（完了タスクは非表示）', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      expect(container.read(ganttShowCompletedProvider), isFalse);
    });

    test('SharedPreferences の値が読み込まれる', () async {
      SharedPreferences.setMockInitialValues({
        ganttShowCompletedPrefsKey: true,
      });
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      expect(container.read(ganttShowCompletedProvider), isTrue);
    });

    test('setShowCompleted で変更が永続化される', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      container
          .read(ganttShowCompletedProvider.notifier)
          .setShowCompleted(show: true);

      expect(container.read(ganttShowCompletedProvider), isTrue);
      expect(prefs.getBool(ganttShowCompletedPrefsKey), isTrue);
    });
  });
}
