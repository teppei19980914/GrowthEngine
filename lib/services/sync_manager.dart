/// クラウド同期マネージャー.
///
/// デバウンス(5秒) + ハッシュ比較 + gzip圧縮 + ライフサイクル同期を組み合わせ、
/// Firestore へのIO回数とドキュメントサイズを最小化する.
/// 起動時にはタイムスタンプ比較でクラウドが新しければ自動ダウンロードする.
///
/// **コスト最適化（v2.1.0）**:
/// - デバウンス間隔: 5 秒（3 秒から拡大して書き込み回数を削減）
/// - JSON コンパクト形式: インデント削除で約 20% 削減
/// - gzip 圧縮 + Base64: 追加で 50〜70% 削減（[encodeSyncPayload]）
/// - 後方互換性: 旧 format 1 も読めるため既存ユーザーのデータは無傷
library;

import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb, visibleForTesting;
import 'package:shared_preferences/shared_preferences.dart';

import 'data_export_service.dart';
import 'firestore_sync_service.dart';
import 'sync_payload_codec.dart';

/// クラウド同期を管理するシングルトン.
class SyncManager {
  /// SyncManagerを作成する.
  factory SyncManager() => _instance;
  SyncManager._();
  static final _instance = SyncManager._();

  /// テスト用コンストラクタ（kIsWebガードを無効化できる）.
  @visibleForTesting
  SyncManager.forTest({bool webMode = true}) : _webMode = webMode;

  DataExportService? _exportService;
  SharedPreferences? _prefs;
  // テスト環境でFirebase未初期化エラーを防ぐため遅延初期化
  CloudSyncClient? _syncService;
  CloudSyncClient get _sync => _syncService ??= FirestoreSyncService();

  Timer? _debounceTimer;
  bool _dirty = false;
  String _lastHash = '';

  // テスト時にkIsWebを上書きするためのフラグ
  bool? _webMode;
  bool get _isWeb => _webMode ?? kIsWeb;

  /// 書き込みデバウンス間隔.
  ///
  /// v2.1.0 で 3 秒 → 5 秒に拡大. 連続するデータ変更を 1 回の Firestore 書き込みに
  /// まとめる窓を広げてコスト削減する. ローカル DB は即座に書き込まれるため
  /// データ消失リスクは増えない.
  static const _debounceDuration = Duration(seconds: 5);
  static const _lastSyncKey = 'cloud_last_sync_ms';

  /// Firestore ドキュメントサイズの警告しきい値（バイト）.
  ///
  /// Firestore の 1 ドキュメント上限は 1 MiB. 90% に達したら debugPrint で警告し、
  /// ユーザーに古いデータの整理（エクスポート + 削除）を促す検討材料とする.
  static const int _payloadWarningBytes = 900 * 1024;

  /// 初期化（アプリ起動時に1回呼ぶ）.
  void init(
    DataExportService exportService, {
    SharedPreferences? prefs,
    CloudSyncClient? syncService,
  }) {
    _exportService = exportService;
    _prefs = prefs;
    if (syncService != null) _syncService = syncService;
  }

  /// データ変更を通知する（デバウンス同期をスケジュール）.
  ///
  /// 即座にIOは発生しない。3秒間追加の通知がなければ同期を実行する.
  void requestSync() {
    if (!_isWeb) return;

    _dirty = true;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, _executeUpload);
  }

  /// アプリ離脱時に未同期データがあれば即座に同期する.
  ///
  /// デバウンス待機中のデータを失わないよう、タイマーをキャンセルして即実行.
  Future<void> syncOnExit() async {
    if (!_dirty) return;
    _debounceTimer?.cancel();
    await _executeUpload();
  }

  /// 起動時の同期: タイムスタンプ比較でダウンロードまたはアップロードを実行する.
  ///
  /// クラウドのデータがローカルより新しい場合は自動ダウンロードし、
  /// そうでなければアップロードする.
  Future<void> syncNow() async {
    if (!_isWeb || !_sync.isSignedIn) return;

    try {
      final cloudTime = await _sync.getLastSyncTime();
      final localTimeMs = _prefs?.getInt(_lastSyncKey) ?? 0;
      final localTime = localTimeMs > 0
          ? DateTime.fromMillisecondsSinceEpoch(localTimeMs, isUtc: true)
          : null;

      if (cloudTime != null &&
          (localTime == null || cloudTime.toUtc().isAfter(localTime))) {
        // クラウドが新しい → ダウンロード
        await _executeDownload();
      } else {
        // ローカルが新しいまたは同じ → アップロード
        _dirty = true;
        await _executeUpload();
      }
    } on Object {
      // 同期失敗: 次回リトライ
    }
  }

  Future<void> _executeUpload() async {
    if (!_dirty || _exportService == null) return;
    if (!_sync.isSignedIn) return;

    try {
      // コンパクト JSON でエクスポート（インデント削除で約 20% 削減）.
      final jsonString = await _exportService!.exportDataCompact();

      // 空データでクラウドのバックアップを上書きしない（データ消失防止）.
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      final totalItems = ((decoded['dreams'] as List?)?.length ?? 0) +
          ((decoded['goals'] as List?)?.length ?? 0) +
          ((decoded['tasks'] as List?)?.length ?? 0) +
          ((decoded['books'] as List?)?.length ?? 0) +
          ((decoded['study_logs'] as List?)?.length ?? 0);
      if (totalItems == 0) {
        debugPrint('[SyncManager] 空データのため同期をスキップ');
        _dirty = false;
        return;
      }

      // ハッシュ比較: 前回と同じならアップロードをスキップ.
      // ハッシュは生 JSON に対して計算する（圧縮前後で同じデータでも
      // gzip の出力がライブラリバージョン依存で揺れる可能性があるため）.
      final hash = sha256.convert(utf8.encode(jsonString)).toString();
      if (hash == _lastHash) {
        _dirty = false;
        return;
      }

      // gzip 圧縮 + Base64 エンコード（format 2）.
      // 圧縮失敗時は legacy 形式で書き込まれる（codec が安全側にフォールバック）.
      final payload = encodeSyncPayload(jsonString);
      _warnIfPayloadTooLarge(payload);

      await _sync.uploadData(payload);
      _lastHash = hash;
      _dirty = false;
      _saveLocalSyncTime();
    } on Object {
      // 同期失敗: dirtyフラグは残す（次回リトライ）
    }
  }

  Future<void> _executeDownload() async {
    if (_exportService == null) return;
    if (!_sync.isSignedIn) return;

    try {
      final payload = await _sync.downloadData();
      if (payload == null || payload.isEmpty) return;

      // format 2（圧縮）と format 1（legacy・プレーン JSON）の両方を扱う.
      final jsonString = decodeSyncPayload(payload);
      if (jsonString.isEmpty) return;

      await _exportService!.importData(jsonString);
      _lastHash = sha256.convert(utf8.encode(jsonString)).toString();
      _dirty = false;
      _saveLocalSyncTime();
    } on Object {
      // ダウンロード失敗: 次回リトライ
    }
  }

  /// ペイロードが警告しきい値を超えていれば debugPrint で警告する.
  ///
  /// Firestore の 1 ドキュメント上限 1 MiB に対して 90% を超えた場合、
  /// 開発者がログから検知できるように出力する.
  void _warnIfPayloadTooLarge(String payload) {
    final size = payload.length;
    if (size > _payloadWarningBytes) {
      debugPrint(
        '[SyncManager] WARNING: アップロードペイロードが大きいです '
        '(${(size / 1024).toStringAsFixed(1)} KB / 上限 1024 KB). '
        '古い完了タスクや既読通知の整理を検討してください.',
      );
    }
  }

  void _saveLocalSyncTime() {
    _prefs?.setInt(_lastSyncKey, DateTime.now().toUtc().millisecondsSinceEpoch);
  }

  /// テスト用: 状態をリセットする.
  void reset() {
    _debounceTimer?.cancel();
    _dirty = false;
    _lastHash = '';
    _exportService = null;
    _syncService = null;
    _prefs = null;
  }
}
