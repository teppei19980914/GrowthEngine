/// ユメハシ アプリケーションのエントリポイント.
library;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'providers/service_providers.dart';
import 'providers/theme_provider.dart';
import 'services/firestore_sync_service.dart';
import 'services/invite_service.dart';
import 'services/remote_config_service.dart';
import 'services/startup_premium_sync.dart';
import 'services/stripe_service.dart';
import 'services/trial_limit_service.dart';

/// アプリケーションのエントリポイント.
///
/// SharedPreferencesの初期化のみを同期的に待ち、
/// リモート設定は非同期で取得してアプリを即座に起動する.
///
/// v2.0.2: 起動時の体感パフォーマンスを改善するため以下の順序で処理する.
/// 1. Firebase 初期化 + SharedPreferences ロード（必須、同期）
/// 2. ローカルキャッシュされたプレミアム状態を同期的に適用
///    → UI 初期描画時点で正しいプレミアム階層が反映される
/// 3. runApp() で即座に UI を表示
/// 4. 初回フレーム描画完了後に Apps Script / Firebase Auth 等の
///    外部通信を走らせる（クリティカルパスから外す）
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  final prefs = await SharedPreferences.getInstance();

  // URLキーの保存は同期的に実施（軽量なSharedPreferences操作のみ）
  _saveUrlKeyIfPresent(prefs);

  // キャッシュされたプレミアム状態を即座に適用する.
  // これにより verifySubscription (~1.8秒) の完了を待たずに
  // 正しいプレミアム階層で UI をレンダリングできる.
  if (kIsWeb) {
    applyCachedPremiumState(prefs);
  }

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
      child: const YumeHashiApp(),
    ),
  );

  // 初回フレーム描画が完了した後に外部通信・データクリーンアップを開始する.
  // これによりペイント直前のネットワーク競合を避け、First Paint を最速化する.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _initRemoteConfigAsync(prefs, container);
    _initInviteCodeAsync(prefs);
    _verifySubscriptionAsync(prefs);
    _initAnonymousAuth();
    _runDataRetentionCleanup(container);
  });
}

/// データ保持期間を超えた古いデータを物理削除する.
///
/// 既読かつ 30 日以上経過した通知、および完了済みかつ 30 日以上更新されて
/// いないタスクを削除する. 起動時に 1 回だけ実行. 失敗してもアプリ本体には
/// 影響しない (例外は DataRetentionService 内で吸収).
Future<void> _runDataRetentionCleanup(ProviderContainer container) async {
  try {
    final service = container.read(dataRetentionServiceProvider);
    await service.cleanup();
  } on Object {
    // クリーンアップの失敗はアプリ動作に影響させない
  }
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

/// サブスクリプション状態をサーバー検証して同期する.
///
/// 必ずサーバーに問い合わせて Stripe の実契約状態を検証し、
/// ローカル状態を更新する. URL パラメータだけでは有効化しない.
///
/// 呼び出し前に [applyCachedPremiumState] がキャッシュ値を適用しているため、
/// この関数は「キャッシュとサーバーの差分を埋める」役割のみを担う.
/// そのため起動クリティカルパスから外して [addPostFrameCallback] 経由で
/// 実行される（初回描画をブロックしない）.
Future<void> _verifySubscriptionAsync(SharedPreferences prefs) async {
  if (!kIsWeb) return;

  final stripeService = StripeService(prefs);
  final configService = RemoteConfigService(prefs);
  final userKey = configService.savedUserKey;

  final subscriptionParam = _getUrlParam('subscription');

  // サーバーに問い合わせてStripe実契約状態を検証・同期
  // userKeyがある場合のみ検証（匿名ユーザーは検証不可）
  if (userKey != null && userKey.isNotEmpty) {
    await stripeService.verifySubscription(userKey: userKey);
  }

  // 検証結果をローカル状態に反映
  if (stripeService.isSubscriptionActive) {
    setSubscriptionPremium(enabled: true);
  } else {
    // 解約済みの場合は明示的にプレミアムを無効化
    setSubscriptionPremium(enabled: false);
  }

  // 無料トライアル有効ならプレミアム機能を解放
  if (stripeService.isTrialActive) {
    setTrialPremium(enabled: true);
  }

  // Stripe Checkout 復帰時はクラウド認証フラグを立てる
  if (subscriptionParam == 'success') {
    await prefs.setBool('cloud_auth_pending', true);
  }
}

/// Web起動時にFirebase匿名認証を自動実行する.
///
/// ユーザー操作なしでUIDが発行され、以降のデータ同期の基盤となる.
/// 既にサインイン済み（匿名・メール問わず）の場合は何もしない.
Future<void> _initAnonymousAuth() async {
  if (!kIsWeb) return;
  try {
    await FirestoreSyncService().ensureSignedIn();
  } on Exception {
    // 認証失敗時はローカルのみで動作（次回起動時にリトライ）
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
