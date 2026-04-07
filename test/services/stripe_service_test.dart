import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yume_hashi/services/stripe_service.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('createCheckoutUrl', () {
    test('成功時にURLを返す', () async {
      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['userKey'], 'test-user');
        return http.Response(
          jsonEncode({'url': 'https://checkout.stripe.com/test'}),
          200,
        );
      });

      final service = StripeService(prefs, httpClient: mockClient);
      final url = await service.createCheckoutUrl(userKey: 'test-user');
      expect(url, 'https://checkout.stripe.com/test');
    });

    test('エラー時にnullを返す', () async {
      final mockClient = MockClient((_) async {
        return http.Response('error', 500);
      });

      final service = StripeService(prefs, httpClient: mockClient);
      final url = await service.createCheckoutUrl(userKey: 'test-user');
      expect(url, isNull);
    });

    test('userKeyなしでも送信できる', () async {
      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['userKey'], '');
        return http.Response(
          jsonEncode({'url': 'https://checkout.stripe.com/test'}),
          200,
        );
      });

      final service = StripeService(prefs, httpClient: mockClient);
      final url = await service.createCheckoutUrl();
      expect(url, 'https://checkout.stripe.com/test');
    });
  });

  group('isSubscriptionActive', () {
    test('初期状態はfalse', () {
      final service = StripeService(prefs);
      expect(service.isSubscriptionActive, isFalse);
    });

    test('activateSubscription後はtrue', () async {
      final service = StripeService(prefs);
      await service.activateSubscription();
      expect(service.isSubscriptionActive, isTrue);
    });

    test('activatedAtが設定される', () async {
      final service = StripeService(prefs);
      expect(service.activatedAt, isNull);
      await service.activateSubscription();
      expect(service.activatedAt, isNotNull);
    });

    test('clearSubscriptionでリセットされる', () async {
      final service = StripeService(prefs);
      await service.activateSubscription();
      expect(service.isSubscriptionActive, isTrue);

      await service.clearSubscription();
      expect(service.isSubscriptionActive, isFalse);
      expect(service.activatedAt, isNull);
    });
  });

  group('無料トライアル', () {
    test('初期状態はトライアル未開始', () {
      final service = StripeService(prefs);
      expect(service.isTrialStarted, isFalse);
      expect(service.isTrialActive, isFalse);
      expect(service.trialRemainingDays, 0);
    });

    test('startTrialでトライアルが開始される', () async {
      final service = StripeService(prefs);
      await service.startTrial();
      expect(service.isTrialStarted, isTrue);
      expect(service.isTrialActive, isTrue);
      expect(service.trialRemainingDays, trialDurationDays);
    });

    test('二重開始は無視される', () async {
      final service = StripeService(prefs);
      await service.startTrial();
      final firstStart = service.trialStartedAt;
      await service.startTrial(); // 二重呼び出し
      expect(service.trialStartedAt, firstStart);
    });

    test('期限切れ後はisTrialActiveがfalse', () async {
      SharedPreferences.setMockInitialValues({
        'premium_trial_started_at': DateTime.now()
            .subtract(const Duration(days: 10))
            .millisecondsSinceEpoch,
      });
      prefs = await SharedPreferences.getInstance();

      final service = StripeService(prefs);
      expect(service.isTrialStarted, isTrue);
      expect(service.isTrialActive, isFalse);
      expect(service.trialRemainingDays, 0);
    });

    test('hasPremiumAccessはサブスクまたはトライアルで有効', () async {
      final service = StripeService(prefs);
      expect(service.hasPremiumAccess, isFalse);

      await service.startTrial();
      expect(service.hasPremiumAccess, isTrue);
    });
  });

  group('verifySubscription', () {
    test('サーバーがactive=trueを返すとローカルが有効化される', () async {
      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['action'], 'status');
        expect(body['userKey'], 'test-user');
        return http.Response(jsonEncode({'active': true}), 200);
      });

      final service = StripeService(prefs, httpClient: mockClient);
      expect(service.isSubscriptionActive, isFalse);

      final result =
          await service.verifySubscription(userKey: 'test-user');
      expect(result, isTrue);
      expect(service.isSubscriptionActive, isTrue);
      expect(service.activatedAt, isNotNull);
    });

    test('サーバーがactive=falseを返すとローカルがクリアされる', () async {
      final mockClient = MockClient((_) async {
        return http.Response(jsonEncode({'active': false}), 200);
      });

      final service = StripeService(prefs, httpClient: mockClient);
      // 先にローカルを有効化
      await service.activateSubscription();
      expect(service.isSubscriptionActive, isTrue);

      final result =
          await service.verifySubscription(userKey: 'test-user');
      expect(result, isFalse);
      expect(service.isSubscriptionActive, isFalse);
      expect(service.activatedAt, isNull);
    });

    test('ローカルとサーバーが一致している場合は状態を変更しない', () async {
      final mockClient = MockClient((_) async {
        return http.Response(jsonEncode({'active': true}), 200);
      });

      final service = StripeService(prefs, httpClient: mockClient);
      await service.activateSubscription();
      final originalActivatedAt = service.activatedAt;

      final result =
          await service.verifySubscription(userKey: 'test-user');
      expect(result, isTrue);
      expect(service.isSubscriptionActive, isTrue);
      // activatedAtが変更されていないことを確認
      expect(service.activatedAt, originalActivatedAt);
    });

    test('通信エラー時はnullを返しローカル状態を変更しない', () async {
      final mockClient = MockClient((_) async {
        return http.Response('error', 500);
      });

      final service = StripeService(prefs, httpClient: mockClient);
      await service.activateSubscription();

      final result =
          await service.verifySubscription(userKey: 'test-user');
      expect(result, isNull);
      // ローカル状態は変更されていない
      expect(service.isSubscriptionActive, isTrue);
    });

    test('例外発生時はnullを返しローカル状態を変更しない', () async {
      final mockClient = MockClient((_) async {
        throw Exception('network error');
      });

      final service = StripeService(prefs, httpClient: mockClient);
      final result =
          await service.verifySubscription(userKey: 'test-user');
      expect(result, isNull);
      expect(service.isSubscriptionActive, isFalse);
    });

    test('userKeyなしでも送信できる', () async {
      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['userKey'], '');
        return http.Response(jsonEncode({'active': false}), 200);
      });

      final service = StripeService(prefs, httpClient: mockClient);
      final result = await service.verifySubscription();
      expect(result, isFalse);
    });
  });

  group('verifySubscriptionOnAccess', () {
    test('userKeyがnullの場合はコールバックが呼ばれない', () async {
      var called = false;
      verifySubscriptionOnAccess(
        prefs: prefs,
        userKey: null,
        onStateChanged: (_) => called = true,
      );
      await Future<void>.delayed(Duration.zero);
      expect(called, isFalse);
    });

    test('userKeyが空の場合はコールバックが呼ばれない', () async {
      var called = false;
      verifySubscriptionOnAccess(
        prefs: prefs,
        userKey: '',
        onStateChanged: (_) => called = true,
      );
      await Future<void>.delayed(Duration.zero);
      expect(called, isFalse);
    });
  });

  group('portalOpenPending', () {
    test('初期値はfalse', () {
      expect(portalOpenPending, isFalse);
    });

    test('設定と解除ができる', () {
      portalOpenPending = true;
      expect(portalOpenPending, isTrue);
      portalOpenPending = false;
      expect(portalOpenPending, isFalse);
    });
  });

  group('サブスク有効化のセキュリティ', () {
    test('activateSubscription単体ではサーバー検証なしに有効化される（内部用）',
        () async {
      final service = StripeService(prefs);
      await service.activateSubscription();
      expect(service.isSubscriptionActive, isTrue);
    });

    test('verifySubscriptionがfalseを返した場合、ローカルの有効状態はクリアされる',
        () async {
      final mockClient = MockClient((_) async {
        return http.Response(jsonEncode({'active': false}), 200);
      });

      final service = StripeService(prefs, httpClient: mockClient);
      // 不正にローカルを有効化したとしても
      await service.activateSubscription();
      expect(service.isSubscriptionActive, isTrue);

      // サーバー検証で無効化される
      final result =
          await service.verifySubscription(userKey: 'test-user');
      expect(result, isFalse);
      expect(service.isSubscriptionActive, isFalse);
    });

    test('サーバー検証のみがプレミアム有効化の正規経路である', () async {
      final mockClient = MockClient((_) async {
        return http.Response(jsonEncode({'active': true}), 200);
      });

      final service = StripeService(prefs, httpClient: mockClient);
      expect(service.isSubscriptionActive, isFalse);

      // サーバー検証でのみ有効化される
      final result =
          await service.verifySubscription(userKey: 'test-user');
      expect(result, isTrue);
      expect(service.isSubscriptionActive, isTrue);
    });
  });

  test('定数 stripeEndpointUrlが定義されている', () {
    expect(stripeEndpointUrl, isNotEmpty);
    expect(stripeEndpointUrl, contains('script.google.com'));
  });
}
