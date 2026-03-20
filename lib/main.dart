/// ユメログ アプリケーションのエントリポイント.
library;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'providers/service_providers.dart';
import 'providers/theme_provider.dart';
import 'services/invite_service.dart';
import 'services/remote_config_service.dart';
import 'services/stripe_service.dart';
import 'services/trial_limit_service.dart';

/// アプリケーションのエントリポイント.
///
/// SharedPreferencesの初期化のみを同期的に待ち、
/// リモート設定は非同期で取得してアプリを即座に起動する.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  // URLキーの保存は同期的に実施（軽量なSharedPreferences操作のみ）
  _saveUrlKeyIfPresent(prefs);

  // リモート設定をバックグラウンドで取得
  // デフォルト設定で即座にアプリを起動し、取得完了後にプロバイダを更新する
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      remoteConfigProvider.overrideWithValue(UserConfig.defaultConfig),
    ],
  );

  // アプリを即座に表示
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const YumeLogApp(),
    ),
  );

  // リモート設定・招待コード・サブスク状態を非同期で処理
  _initRemoteConfigAsync(prefs, container);
  _initInviteCodeAsync(prefs);
  _initSubscriptionAsync(prefs);
}

/// URLキーをSharedPreferencesに保存する（同期的）.
void _saveUrlKeyIfPresent(SharedPreferences prefs) {
  if (!kIsWeb) return;
  final urlKey = _getUrlKey();
  if (urlKey != null && urlKey.isNotEmpty) {
    RemoteConfigService(prefs).saveUserKey(urlKey);
  }
}

/// リモート設定を非同期で取得し、プロバイダを更新する.
Future<void> _initRemoteConfigAsync(
  SharedPreferences prefs,
  ProviderContainer container,
) async {
  if (!kIsWeb) return;

  final service = RemoteConfigService(prefs);
  if (service.savedUserKey == null) return;

  try {
    final config = await service.fetchAndApply();

    // プロバイダを更新（UIが自動的に再構築される）
    container.updateOverrides([
      sharedPreferencesProvider.overrideWithValue(prefs),
      remoteConfigProvider.overrideWithValue(config),
    ]);

    // unlimited: プレミアム機能を解放（開発者用）
    if (config.unlimited) {
      setSubscriptionPremium(enabled: true);
    }

    // resetOnAccess: アクセス時にデータをリセット
    if (config.resetOnAccess) {
      await service.clearPreferencesExceptKey();
      await prefs.setBool(resetPendingKey, true);
    }
  } on Exception {
    // リモート設定取得失敗時はデフォルト設定のまま動作する
  }
}

/// 招待コードを非同期で処理する.
///
/// URLパラメータ `?invite=CODE` から招待コードを取得し、
/// Gistで有効性を検証してからブラウザに保存する.
Future<void> _initInviteCodeAsync(SharedPreferences prefs) async {
  if (!kIsWeb) return;

  final inviteCode = _getUrlParam('invite');
  if (inviteCode == null || inviteCode.isEmpty) return;

  final inviteService = InviteService(prefs);
  // 既に同じコードで有効化済みならスキップ
  if (inviteService.savedCode == inviteCode) return;

  final configService = RemoteConfigService(prefs);
  final inviteConfig = await configService.fetchInviteConfig(inviteCode);
  if (inviteConfig == null) return;

  await inviteService.activate(inviteCode, inviteConfig);
}

/// サブスクリプション状態を非同期で処理する.
///
/// URLパラメータ `?subscription=success` を検出して有効化するか、
/// 保存済みのサブスクリプション状態を復元する.
Future<void> _initSubscriptionAsync(SharedPreferences prefs) async {
  if (!kIsWeb) return;

  final stripeService = StripeService(prefs);

  // ?subscription=success パラメータの検出
  final subscriptionParam = _getUrlParam('subscription');
  if (subscriptionParam == 'success') {
    await stripeService.activateSubscription();
  }

  // サブスクリプション有効ならプレミアム機能を解放
  if (stripeService.isSubscriptionActive) {
    setSubscriptionPremium(enabled: true);
  }

  // 無料トライアル有効ならプレミアム機能を解放
  if (stripeService.isTrialActive) {
    setTrialPremium(enabled: true);
  }
}

/// URLのクエリパラメータを取得する.
String? _getUrlParam(String name) {
  try {
    return Uri.base.queryParameters[name];
  } on Exception {
    return null;
  }
}

/// URLのクエリパラメータからキーを取得する.
String? _getUrlKey() => _getUrlParam('key');
