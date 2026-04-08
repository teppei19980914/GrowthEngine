/// 起動時プレミアム状態同期ユーティリティ.
///
/// [main] 関数から `runApp()` より前に呼び出され、
/// [SharedPreferences] にキャッシュされたサブスク/トライアル情報を
/// そのまま [TrialLimitService] のプレミアムフラグへ反映する.
///
/// 外部通信を行わないので First Paint を遅延させない.
/// サーバー検証とは独立して動作し、検証結果で上書きされる想定.
library;

import 'package:shared_preferences/shared_preferences.dart';

import 'stripe_service.dart';
import 'trial_limit_service.dart';

/// キャッシュされたプレミアム状態を同期的に適用する.
///
/// [prefs] に保存されている `stripe_subscription_active` と
/// `premium_trial_started_at` を読み取り、[setSubscriptionPremium] と
/// [setTrialPremium] に反映する.
///
/// この関数は **プレミアム状態の「有効化」のみ** を行う.
/// 「無効化」はサーバー検証 ([StripeService.verifySubscription]) の
/// 結果に基づいて行われるため、キャッシュに基づいて無効化することはしない
/// （ユーザーが別端末で契約した場合に即座に無効化しないよう保護する）.
void applyCachedPremiumState(SharedPreferences prefs) {
  final stripeService = StripeService(prefs);
  if (stripeService.isSubscriptionActive) {
    setSubscriptionPremium(enabled: true);
  }
  if (stripeService.isTrialActive) {
    setTrialPremium(enabled: true);
  }
}
