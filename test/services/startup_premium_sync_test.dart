import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yume_hashi/services/startup_premium_sync.dart';
import 'package:yume_hashi/services/stripe_service.dart';
import 'package:yume_hashi/services/trial_limit_service.dart';

void main() {
  group('applyCachedPremiumState', () {
    setUp(() {
      // 各テストで前回のフラグをリセット
      setSubscriptionPremium(enabled: false);
      setTrialPremium(enabled: false);
      setTrialModeForTest(enabled: true); // isPremium が階層ごとのフラグを見るようにする
    });

    tearDown(() {
      setSubscriptionPremium(enabled: false);
      setTrialPremium(enabled: false);
      setTrialModeForTest(enabled: false);
    });

    test('サブスク有効のキャッシュがあれば即座にプレミアム階層が反映される', () async {
      SharedPreferences.setMockInitialValues({
        'stripe_subscription_active': true,
      });
      final prefs = await SharedPreferences.getInstance();

      // 前提: まだフラグは false
      expect(isPremium, isFalse);

      applyCachedPremiumState(prefs);

      // サブスクフラグが立っている
      expect(isPremium, isTrue);
    });

    test('トライアル期間内のキャッシュがあれば即座にプレミアム階層が反映される', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        'premium_trial_started_at': now,
      });
      final prefs = await SharedPreferences.getInstance();

      expect(isPremium, isFalse);

      applyCachedPremiumState(prefs);

      expect(isPremium, isTrue);
    });

    test('トライアル期限切れのキャッシュではプレミアムにならない', () async {
      // 10日前に開始 → 7日トライアルを超過
      final tenDaysAgo = DateTime.now()
          .subtract(const Duration(days: 10))
          .millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        'premium_trial_started_at': tenDaysAgo,
      });
      final prefs = await SharedPreferences.getInstance();

      applyCachedPremiumState(prefs);

      expect(isPremium, isFalse);
    });

    test('キャッシュが空の場合は何もしない（既存の状態を変更しない）', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      applyCachedPremiumState(prefs);

      expect(isPremium, isFalse);
    });

    test('サブスク無効のキャッシュがあってもフラグを下げない（サーバー検証の責務）', () async {
      // 事前に外部から true になっている状態
      setSubscriptionPremium(enabled: true);
      expect(isPremium, isTrue);

      SharedPreferences.setMockInitialValues({
        'stripe_subscription_active': false,
      });
      final prefs = await SharedPreferences.getInstance();

      applyCachedPremiumState(prefs);

      // applyCachedPremiumState は「有効化のみ」を行うため、
      // 既に立っているフラグは変更されない（サーバー検証で下げる）
      expect(isPremium, isTrue);
    });

    test('StripeService の isSubscriptionActive と整合する', () async {
      SharedPreferences.setMockInitialValues({
        'stripe_subscription_active': true,
      });
      final prefs = await SharedPreferences.getInstance();
      final stripe = StripeService(prefs);

      // StripeService が true を返す
      expect(stripe.isSubscriptionActive, isTrue);

      applyCachedPremiumState(prefs);

      // applyCachedPremiumState も同じ値を使ってフラグを立てる
      expect(isPremium, isTrue);
    });
  });
}
