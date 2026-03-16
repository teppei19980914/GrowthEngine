/// 招待コード管理サービス.
///
/// 開発者が発行した招待コードをもとに、期間限定で全機能を解放する.
/// 招待コードはGitHub Gistで管理し、有効化日時はブラウザに保存する.
library;

import 'package:shared_preferences/shared_preferences.dart';

const _inviteCodeKey = 'invite_code';
const _inviteActivatedAtKey = 'invite_activated_at';
const _inviteNameKey = 'invite_name';
const _inviteDurationDaysKey = 'invite_duration_days';

/// 招待コードの設定（Gist JSONから取得）.
class InviteConfig {
  /// InviteConfigを作成する.
  const InviteConfig({
    required this.name,
    required this.durationDays,
  });

  /// JSONマップからInviteConfigを生成する.
  factory InviteConfig.fromJson(Map<String, dynamic> json) {
    return InviteConfig(
      name: json['name'] as String? ?? '',
      durationDays: json['durationDays'] as int? ?? 60,
    );
  }

  /// 招待先ユーザー名.
  final String name;

  /// 有効期間（日数）.
  final int durationDays;
}

/// 招待コードの有効状態.
class InviteStatus {
  /// InviteStatusを作成する.
  const InviteStatus({
    required this.isActive,
    this.name,
    this.remainingDays,
    this.expiredAt,
  });

  /// 無効（招待コード未使用）.
  static const inactive = InviteStatus(isActive: false);

  /// 招待が有効か.
  final bool isActive;

  /// 招待先ユーザー名.
  final String? name;

  /// 残り日数（0以下で期限切れ）.
  final int? remainingDays;

  /// 期限切れ日時.
  final DateTime? expiredAt;
}

/// 招待コード管理サービス.
class InviteService {
  /// InviteServiceを作成する.
  InviteService(this._prefs);

  final SharedPreferences _prefs;

  /// 保存済みの招待コード.
  String? get savedCode => _prefs.getString(_inviteCodeKey);

  /// 招待コードを有効化する.
  Future<void> activate(String code, InviteConfig config) async {
    // 既に同じコードで有効化済みなら何もしない
    if (savedCode == code && _prefs.getInt(_inviteActivatedAtKey) != null) {
      return;
    }

    await _prefs.setString(_inviteCodeKey, code);
    await _prefs.setInt(
      _inviteActivatedAtKey,
      DateTime.now().millisecondsSinceEpoch,
    );
    await _prefs.setString(_inviteNameKey, config.name);
    await _prefs.setInt(_inviteDurationDaysKey, config.durationDays);
  }

  /// 現在の招待状態を取得する.
  InviteStatus getStatus() {
    final activatedAt = _prefs.getInt(_inviteActivatedAtKey);
    if (activatedAt == null) return InviteStatus.inactive;

    final name = _prefs.getString(_inviteNameKey) ?? '';
    final durationDays = _prefs.getInt(_inviteDurationDaysKey) ?? 60;

    final activatedDate =
        DateTime.fromMillisecondsSinceEpoch(activatedAt);
    final expiryDate = activatedDate.add(Duration(days: durationDays));
    final remaining = expiryDate.difference(DateTime.now()).inDays;

    return InviteStatus(
      isActive: remaining >= 0,
      name: name,
      remainingDays: remaining >= 0 ? remaining : null,
      expiredAt: remaining < 0 ? expiryDate : null,
    );
  }
}
