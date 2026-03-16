/// GitHub Gist ベースのリモートユーザー設定管理.
///
/// Secret Gist に配置したJSONでユーザーごとの設定を管理する.
/// URLパラメータ `?key=xxx` でユーザーを識別し、
/// Gistの設定に基づいて制限解除やリセット動作を制御する.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Gist ID（Secret Gist作成後に設定する）.
///
/// 空文字の場合、リモート設定機能は無効.
const remoteConfigGistId = 'd68bbdb601a9d0e409244c141f25e3fc';

/// データベースリセット保留フラグのキー.
const resetPendingKey = 'remote_config_reset_pending';

const _userKeyPref = 'remote_config_user_key';
const _cachedConfigPref = 'remote_config_cached';
const _cachedTimestampPref = 'remote_config_timestamp';

/// キャッシュの有効期間（5分）.
const _cacheDuration = Duration(minutes: 5);

/// ユーザー設定.
class UserConfig {
  /// UserConfigを作成する.
  const UserConfig({
    required this.name,
    required this.unlimited,
    required this.unlockLevel,
    required this.resetOnAccess,
  });

  /// JSONマップからUserConfigを生成する.
  factory UserConfig.fromJson(Map<String, dynamic> json) {
    return UserConfig(
      name: json['name'] as String? ?? '',
      unlimited: json['unlimited'] as bool? ?? false,
      unlockLevel: json['unlockLevel'] as int? ?? 0,
      resetOnAccess: json['resetOnAccess'] as bool? ?? false,
    );
  }

  /// デフォルト設定（一般ユーザー）.
  static const defaultConfig = UserConfig(
    name: '',
    unlimited: false,
    unlockLevel: 0,
    resetOnAccess: false,
  );

  /// ユーザー名.
  final String name;

  /// 無制限モード.
  final bool unlimited;

  /// 解除レベルの上書き.
  final int unlockLevel;

  /// アクセス時にデータをリセットするか.
  final bool resetOnAccess;

  /// JSONマップに変換する.
  Map<String, dynamic> toJson() => {
        'name': name,
        'unlimited': unlimited,
        'unlockLevel': unlockLevel,
        'resetOnAccess': resetOnAccess,
      };
}

/// リモート設定サービス.
class RemoteConfigService {
  /// RemoteConfigServiceを作成する.
  RemoteConfigService(this._prefs, {http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  final SharedPreferences _prefs;
  final http.Client _httpClient;

  UserConfig? _currentConfig;

  /// 保存済みのユーザーキー.
  String? get savedUserKey => _prefs.getString(_userKeyPref);

  /// 現在のユーザー設定.
  UserConfig get currentConfig => _currentConfig ?? UserConfig.defaultConfig;

  /// ユーザーキーを保存する.
  Future<void> saveUserKey(String key) async {
    await _prefs.setString(_userKeyPref, key);
  }

  /// リモート設定を取得してユーザー設定を適用する.
  ///
  /// [userKey] が指定された場合はそのキーで検索する.
  /// 指定されない場合は保存済みキーを使用する.
  /// Gist ID 未設定またはキーなしの場合はデフォルト設定を返す.
  Future<UserConfig> fetchAndApply({String? userKey}) async {
    final key = userKey ?? savedUserKey;
    if (remoteConfigGistId.isEmpty || key == null || key.isEmpty) {
      _currentConfig = UserConfig.defaultConfig;
      return _currentConfig!;
    }

    // キャッシュを確認
    final cached = _getCachedConfig(key);
    if (cached != null) {
      _currentConfig = cached;
      return cached;
    }

    // Gistから取得
    try {
      final config = await _fetchFromGist(key);
      _currentConfig = config;
      await _cacheConfig(key, config);
      return config;
    } on Exception {
      // 通信エラー時はキャッシュ（期限切れでも）またはデフォルトを使用
      final staleCache = _getStaleCachedConfig(key);
      _currentConfig = staleCache ?? UserConfig.defaultConfig;
      return _currentConfig!;
    }
  }

  /// Gist からユーザー設定を取得する.
  Future<UserConfig> _fetchFromGist(String userKey) async {
    final url =
        Uri.parse('https://api.github.com/gists/$remoteConfigGistId');
    final response = await _httpClient.get(url, headers: {
      'Accept': 'application/vnd.github.v3+json',
    }).timeout(const Duration(seconds: 5));

    if (response.statusCode != 200) {
      throw Exception('Gist取得失敗: ${response.statusCode}');
    }

    final gistJson = jsonDecode(response.body) as Map<String, dynamic>;
    final files = gistJson['files'] as Map<String, dynamic>;

    // 最初のJSONファイルの内容を取得
    String? content;
    for (final file in files.values) {
      final fileMap = file as Map<String, dynamic>;
      final filename = fileMap['filename'] as String? ?? '';
      if (filename.endsWith('.json')) {
        content = fileMap['content'] as String?;
        break;
      }
    }

    if (content == null) {
      throw Exception('Gist内にJSONファイルが見つかりません');
    }

    final configJson = jsonDecode(content) as Map<String, dynamic>;
    final users = configJson['users'] as Map<String, dynamic>?;

    if (users == null || !users.containsKey(userKey)) {
      return UserConfig.defaultConfig;
    }

    return UserConfig.fromJson(users[userKey] as Map<String, dynamic>);
  }

  /// キャッシュから設定を取得する（有効期間内のみ）.
  UserConfig? _getCachedConfig(String userKey) {
    final timestamp = _prefs.getInt(_cachedTimestampPref) ?? 0;
    final elapsed =
        DateTime.now().millisecondsSinceEpoch - timestamp;
    if (elapsed > _cacheDuration.inMilliseconds) return null;

    return _getStaleCachedConfig(userKey);
  }

  /// キャッシュから設定を取得する（期限切れでも可）.
  UserConfig? _getStaleCachedConfig(String userKey) {
    final cached = _prefs.getString(_cachedConfigPref);
    if (cached == null) return null;

    try {
      final json = jsonDecode(cached) as Map<String, dynamic>;
      final cachedKey = json['key'] as String?;
      if (cachedKey != userKey) return null;
      return UserConfig.fromJson(json['config'] as Map<String, dynamic>);
    } on Exception {
      return null;
    }
  }

  /// 設定をキャッシュに保存する.
  Future<void> _cacheConfig(String userKey, UserConfig config) async {
    final json = jsonEncode({
      'key': userKey,
      'config': config.toJson(),
    });
    await _prefs.setString(_cachedConfigPref, json);
    await _prefs.setInt(
      _cachedTimestampPref,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// ユーザーキーと設定をクリアする.
  Future<void> clearConfig() async {
    await _prefs.remove(_userKeyPref);
    await _prefs.remove(_cachedConfigPref);
    await _prefs.remove(_cachedTimestampPref);
    _currentConfig = null;
  }

  /// resetOnAccess用: ユーザーキー以外のSharedPreferencesをクリアする.
  Future<void> clearPreferencesExceptKey() async {
    final key = savedUserKey;
    final cachedConfig = _prefs.getString(_cachedConfigPref);
    final cachedTimestamp = _prefs.getInt(_cachedTimestampPref);

    await _prefs.clear();

    // ユーザーキーとキャッシュは復元
    if (key != null) await _prefs.setString(_userKeyPref, key);
    if (cachedConfig != null) {
      await _prefs.setString(_cachedConfigPref, cachedConfig);
    }
    if (cachedTimestamp != null) {
      await _prefs.setInt(_cachedTimestampPref, cachedTimestamp);
    }
  }
}
