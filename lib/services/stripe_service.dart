/// Stripe決済連携サービス.
///
/// Google Apps Script 経由で Stripe Checkout Session を作成し、
/// サブスクリプションの状態を管理する.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Stripe Checkout Session 作成用の Apps Script URL.
const stripeEndpointUrl =
    'https://script.google.com/macros/s/AKfycbzwtQ0hmI3aUeZPz95fJV7l4amSaXxRH87NTLAdk0sp1IQRQsSZ7sKjVAm3W1NuVEnq/exec';

const _subscriptionActiveKey = 'stripe_subscription_active';
const _subscriptionActivatedAtKey = 'stripe_subscription_activated_at';
const _trialStartedAtKey = 'premium_trial_started_at';

/// 無料トライアル期間（日数）.
const trialDurationDays = 7;

/// Customer Portal を開いたことを示すフラグ.
///
/// Portal からタブ復帰時にサブスク状態を再検証するために使用する.
/// Portal を開く前に true にし、検証完了後に false に戻す.
bool portalOpenPending = false;

/// サブスク検証のスロットル間隔.
const _verifyInterval = Duration(minutes: 5);

/// 最後にサブスク検証を実行した時刻.
DateTime? _lastVerifiedAt;

/// プレミアム画面アクセス時にサブスク状態を検証する.
///
/// 前回検証から [_verifyInterval] 以内の場合はスキップする.
/// バックグラウンドで実行し、結果に応じて [onStateChanged] を呼ぶ.
void verifySubscriptionOnAccess({
  required SharedPreferences prefs,
  required String? userKey,
  required void Function(bool active) onStateChanged,
}) {
  if (userKey == null || userKey.isEmpty) return;

  final now = DateTime.now();
  if (_lastVerifiedAt != null &&
      now.difference(_lastVerifiedAt!) < _verifyInterval) {
    return; // スロットル: 前回検証から間もない場合はスキップ
  }
  _lastVerifiedAt = now;

  // バックグラウンドで検証（UIをブロックしない）
  final service = StripeService(prefs);
  service.verifySubscription(userKey: userKey).then((active) {
    if (active != null) {
      onStateChanged(active);
    }
  });
}

/// Stripe連携サービス.
class StripeService {
  /// StripeServiceを作成する.
  StripeService(this._prefs, {http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  final SharedPreferences _prefs;
  final http.Client _httpClient;

  /// サブスクリプションが有効かどうか.
  bool get isSubscriptionActive =>
      _prefs.getBool(_subscriptionActiveKey) ?? false;

  /// サブスクリプション開始日.
  DateTime? get activatedAt {
    final ms = _prefs.getInt(_subscriptionActivatedAtKey);
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  /// Stripe Checkout Session のURLを取得する.
  ///
  /// Apps Script 経由で Stripe Checkout Session を作成し、
  /// 決済ページのURLを返す.
  Future<String?> createCheckoutUrl({String? userKey}) async {
    try {
      final response = await _httpClient.post(
        Uri.parse(stripeEndpointUrl),
        headers: {'Content-Type': 'text/plain'},
        body: jsonEncode({
          'userKey': userKey ?? '',
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json['url'] as String?;
    } on Object catch (e) {
      debugPrint('[StripeService] createCheckoutUrl error: $e');
      return null;
    }
  }

  /// サブスクリプション状態をローカルに保存する.
  ///
  /// [verifySubscription] のサーバー検証結果に基づいて呼ばれる.
  /// 外部から直接呼び出さないこと（サーバー検証を経由すること）.
  Future<void> activateSubscription() async {
    await _prefs.setBool(_subscriptionActiveKey, true);
    await _prefs.setInt(
      _subscriptionActivatedAtKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Stripe Customer Portal のURLを取得する.
  ///
  /// ユーザーが自分でサブスクリプションの解約・変更を行えるポータル.
  Future<String?> createCustomerPortalUrl({String? userKey}) async {
    try {
      final response = await _httpClient.post(
        Uri.parse(stripeEndpointUrl),
        headers: {'Content-Type': 'text/plain'},
        body: jsonEncode({
          'action': 'portal',
          'userKey': userKey ?? '',
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json['url'] as String?;
    } on Object catch (e) {
      debugPrint('[StripeService] createCustomerPortalUrl error: $e');
      return null;
    }
  }

  /// サーバーに問い合わせてサブスクリプション状態を検証・同期する.
  ///
  /// Stripe の実際の契約状態を取得し、ローカルの状態を更新する.
  /// - 契約中なのにローカルが未有効 → 有効化
  /// - 解約済みなのにローカルが有効 → クリア
  ///
  /// 通信エラー時はローカル状態を変更せず null を返す.
  Future<bool?> verifySubscription({String? userKey}) async {
    try {
      final response = await _httpClient.post(
        Uri.parse(stripeEndpointUrl),
        headers: {'Content-Type': 'text/plain'},
        body: jsonEncode({
          'action': 'status',
          'userKey': userKey ?? '',
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final active = json['active'] as bool? ?? false;

      // ローカル状態をStripe実状態に同期
      if (active && !isSubscriptionActive) {
        await activateSubscription();
      } else if (!active && isSubscriptionActive) {
        await clearSubscription();
      }

      return active;
    } on Object catch (e) {
      debugPrint('[StripeService] verifySubscription error: $e');
      return null;
    }
  }

  /// サブスクリプション状態をクリアする.
  Future<void> clearSubscription() async {
    await _prefs.remove(_subscriptionActiveKey);
    await _prefs.remove(_subscriptionActivatedAtKey);
  }

  // ── 無料トライアル ──

  /// 無料トライアルが開始済みかどうか.
  bool get isTrialStarted => _prefs.getInt(_trialStartedAtKey) != null;

  /// 無料トライアル開始日.
  DateTime? get trialStartedAt {
    final ms = _prefs.getInt(_trialStartedAtKey);
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  /// 無料トライアルが有効（期間内）かどうか.
  bool get isTrialActive {
    final start = trialStartedAt;
    if (start == null) return false;
    final remaining = _trialRemainingDays(start);
    return remaining > 0;
  }

  /// 無料トライアルの残り日数.
  int get trialRemainingDays {
    final start = trialStartedAt;
    if (start == null) return 0;
    return _trialRemainingDays(start);
  }

  int _trialRemainingDays(DateTime start) {
    final elapsed = DateTime.now().difference(start).inDays;
    final remaining = trialDurationDays - elapsed;
    return remaining > 0 ? remaining : 0;
  }

  /// 無料トライアルを開始する.
  Future<void> startTrial() async {
    if (isTrialStarted) return; // 二重開始防止
    await _prefs.setInt(
      _trialStartedAtKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// プレミアム機能が利用可能か（サブスク or トライアル）.
  bool get hasPremiumAccess => isSubscriptionActive || isTrialActive;
}
