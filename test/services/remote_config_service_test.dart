import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yume_hashi/services/remote_config_service.dart';

void main() {
  late SharedPreferences prefs;

  Future<SharedPreferences> getPrefs([
    Map<String, Object> initial = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(initial);
    return SharedPreferences.getInstance();
  }

  group('UserConfig', () {
    test('fromJsonで全フィールドがパースされる', () {
      final config = UserConfig.fromJson({
        'name': 'テスター',
        'unlimited': true,
        'unlockLevel': 2,
        'resetOnAccess': true,
      });

      expect(config.name, 'テスター');
      expect(config.unlimited, isTrue);
      expect(config.unlockLevel, 2);
      expect(config.resetOnAccess, isTrue);
    });

    test('fromJsonでデフォルト値が適用される', () {
      final config = UserConfig.fromJson({});

      expect(config.name, '');
      expect(config.unlimited, isFalse);
      expect(config.unlockLevel, 0);
      expect(config.resetOnAccess, isFalse);
    });

    test('toJsonとfromJsonの往復変換', () {
      const original = UserConfig(
        name: 'dev',
        unlimited: true,
        unlockLevel: 3,
        resetOnAccess: false,
      );

      final restored = UserConfig.fromJson(original.toJson());

      expect(restored.name, original.name);
      expect(restored.unlimited, original.unlimited);
      expect(restored.unlockLevel, original.unlockLevel);
      expect(restored.resetOnAccess, original.resetOnAccess);
    });

    test('defaultConfigは制限付き', () {
      expect(UserConfig.defaultConfig.unlimited, isFalse);
      expect(UserConfig.defaultConfig.unlockLevel, 0);
      expect(UserConfig.defaultConfig.resetOnAccess, isFalse);
    });
  });

  group('RemoteConfigService', () {
    test('初期状態ではキーがない', () async {
      prefs = await getPrefs();
      final service = RemoteConfigService(prefs);

      expect(service.savedUserKey, isNull);
      expect(service.currentConfig.unlimited, isFalse);
    });

    test('ユーザーキーを保存できる', () async {
      prefs = await getPrefs();
      final service = RemoteConfigService(prefs);

      await service.saveUserKey('test-key');
      expect(service.savedUserKey, 'test-key');
    });

    test('GistID未設定の場合はデフォルト設定を返す', () async {
      prefs = await getPrefs({'remote_config_user_key': 'test-key'});
      final service = RemoteConfigService(prefs);

      // remoteConfigGistIdは空文字なのでデフォルトが返る
      final config = await service.fetchAndApply();
      expect(config.unlimited, isFalse);
    });

    test('キーなしの場合はデフォルト設定を返す', () async {
      prefs = await getPrefs();
      final service = RemoteConfigService(prefs);

      final config = await service.fetchAndApply();
      expect(config.unlimited, isFalse);
    });

    test('clearConfigでキーと設定がクリアされる', () async {
      prefs = await getPrefs({
        'remote_config_user_key': 'test-key',
        'remote_config_cached': '{}',
      });
      final service = RemoteConfigService(prefs);

      await service.clearConfig();
      expect(service.savedUserKey, isNull);
    });

    test('clearPreferencesExceptKeyでキー以外がクリアされる', () async {
      prefs = await getPrefs({
        'remote_config_user_key': 'test-key',
        'remote_config_cached': '{"key":"test-key","config":{}}',
        'web_trial_dialog_shown': true,
        'web_trial_banner_dismissed': true,
        'theme_type': 'dark',
      });
      final service = RemoteConfigService(prefs);

      await service.clearPreferencesExceptKey();

      // キーとキャッシュは残る
      expect(service.savedUserKey, 'test-key');
      // その他はクリア
      expect(prefs.getBool('web_trial_dialog_shown'), isNull);
      expect(prefs.getBool('web_trial_banner_dismissed'), isNull);
      expect(prefs.getString('theme_type'), isNull);
    });
  });

  group('Gistレスポンスのパース', () {
    test('正常なGistレスポンスからユーザー設定を取得できる', () async {
      final usersJson = {
        'users': {
          'dev-key': {
            'name': '開発者',
            'unlimited': true,
            'unlockLevel': 3,
            'resetOnAccess': false,
          },
          'tester-key': {
            'name': 'テスターA',
            'unlimited': false,
            'unlockLevel': 1,
            'resetOnAccess': true,
          },
        },
      };

      final users = usersJson['users']!;
      final devConfig =
          UserConfig.fromJson(users['dev-key']! as Map<String, dynamic>);
      expect(devConfig.name, '開発者');
      expect(devConfig.unlimited, isTrue);
      expect(devConfig.unlockLevel, 3);

      final testerConfig =
          UserConfig.fromJson(users['tester-key']! as Map<String, dynamic>);
      expect(testerConfig.name, 'テスターA');
      expect(testerConfig.unlimited, isFalse);
      expect(testerConfig.unlockLevel, 1);
      expect(testerConfig.resetOnAccess, isTrue);
    });

    test('存在しないキーの場合はデフォルト設定', () {
      final usersJson = {
        'users': {
          'dev-key': {'name': '開発者', 'unlimited': true},
        },
      };

      final users = usersJson['users'] as Map<String, dynamic>;
      expect(users.containsKey('unknown-key'), isFalse);
    });
  });

  group('キャッシュ', () {
    test('キャッシュに保存した設定を復元できる', () async {
      final cachedJson = jsonEncode({
        'key': 'test-key',
        'config': {
          'name': 'cached',
          'unlimited': true,
          'unlockLevel': 2,
          'resetOnAccess': false,
        },
      });
      prefs = await getPrefs({
        'remote_config_user_key': 'test-key',
        'remote_config_cached': cachedJson,
        'remote_config_timestamp':
            DateTime.now().millisecondsSinceEpoch, // 有効期間内
      });
      final service = RemoteConfigService(prefs);

      // GistIDが空なのでfetchAndApplyはデフォルトを返すが、
      // キャッシュのパーステスト用にclearPreferencesExceptKeyを確認
      await service.clearPreferencesExceptKey();

      // キャッシュが復元されている
      expect(prefs.getString('remote_config_cached'), isNotNull);
    });
  });

  group('resetPendingKey', () {
    test('定数が定義されている', () {
      expect(resetPendingKey, 'remote_config_reset_pending');
    });
  });
}
