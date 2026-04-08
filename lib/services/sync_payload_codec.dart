/// クラウド同期用ペイロードのコーデック.
///
/// Firestore のドキュメントサイズと下り帯域を削減するため、
/// JSON 文字列を gzip 圧縮して Base64 にエンコードする.
///
/// **形式バージョン**:
/// - **format 1 (legacy)**: プレーン JSON 文字列（v2.1.0 以前で書き込まれたデータ）
/// - **format 2**: `gz1:` プレフィックス + Base64(gzip(utf8(json)))
///
/// **後方互換性**:
/// 既存ユーザーが Firestore に保存した format 1 データも透過的に読めるよう、
/// [decodeSyncPayload] はプレフィックスを判定して両形式を扱う.
/// 書き込みは常に format 2 で行うため、初回アップロード後に自動移行する.
///
/// **セキュリティ**:
/// gzip と Base64 はどちらも可逆エンコーディングであり、暗号化ではない.
/// 機密性は Firestore Security Rules（ユーザー uid ベースのアクセス制御）と
/// HTTPS によって担保される. このコーデックは純粋にコスト削減目的.
library;

import 'dart:convert';

import 'package:archive/archive.dart';

/// format 2 を識別するプレフィックス（圧縮判定用）.
///
/// JSON 文字列の先頭は通常 `{` や `[` であるため、`gz1:` と衝突しない.
const String syncPayloadFormat2Prefix = 'gz1:';

/// クラウド同期用のペイロードを format 2（gzip + Base64）にエンコードする.
///
/// 圧縮に失敗した場合は安全側に倒して元の JSON 文字列をそのまま返す
/// （legacy format 1 として書き込まれる）.
String encodeSyncPayload(String jsonString) {
  if (jsonString.isEmpty) return jsonString;
  try {
    final bytes = utf8.encode(jsonString);
    final gzipped = GZipEncoder().encode(bytes);
    if (gzipped == null) {
      // 圧縮失敗時は legacy 形式で書き込む
      return jsonString;
    }
    return '$syncPayloadFormat2Prefix${base64Encode(gzipped)}';
  } on Object {
    // 圧縮失敗時は legacy 形式で書き込む（読み込み側はどちらでも処理可能）
    return jsonString;
  }
}

/// クラウド同期用のペイロードをデコードする.
///
/// - format 2（`gz1:` プレフィックスあり）: Base64 復号 → gzip 解凍 → UTF-8 デコード
/// - それ以外: legacy format 1（プレーン JSON）としてそのまま返す
///
/// 復号に失敗した場合は元のペイロードをそのまま返す（呼び出し側で
/// JSON パースに失敗するのでエラーは伝播する）.
String decodeSyncPayload(String payload) {
  if (payload.isEmpty) return payload;
  if (!payload.startsWith(syncPayloadFormat2Prefix)) {
    // legacy format 1: プレーン JSON
    return payload;
  }
  try {
    final base64Body = payload.substring(syncPayloadFormat2Prefix.length);
    final compressed = base64Decode(base64Body);
    final decompressed = GZipDecoder().decodeBytes(compressed);
    return utf8.decode(decompressed);
  } on Object {
    // デコード失敗時はそのまま返す（呼び出し側で例外になる）
    return payload;
  }
}

/// payload が format 2（gzip 圧縮済み）かどうかを判定する.
///
/// サイズ計測やテストでフォーマットを区別するために使用する.
bool isCompressedSyncPayload(String payload) =>
    payload.startsWith(syncPayloadFormat2Prefix);
