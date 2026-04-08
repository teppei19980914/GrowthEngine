import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:yume_hashi/services/sync_payload_codec.dart';

void main() {
  group('encodeSyncPayload / decodeSyncPayload', () {
    test('プレーンJSONをエンコードすると gz1: プレフィックスがつく', () {
      const json = '{"version":1,"dreams":[{"id":"d1","title":"夢"}]}';

      final encoded = encodeSyncPayload(json);

      expect(encoded.startsWith(syncPayloadFormat2Prefix), isTrue);
      expect(isCompressedSyncPayload(encoded), isTrue);
    });

    test('encode → decode で元の文字列に戻る（往復テスト）', () {
      const json = '{"version":1,"dreams":[{"id":"d1","title":"夢"}],'
          '"goals":[],"tasks":[],"books":[],"study_logs":[],"notifications":[]}';

      final encoded = encodeSyncPayload(json);
      final decoded = decodeSyncPayload(encoded);

      expect(decoded, equals(json));
    });

    test('日本語を含む JSON も正しく往復する', () {
      const json =
          '{"dreams":[{"title":"ITエンジニアになる","why":"夢を追いたい"}]}';

      final encoded = encodeSyncPayload(json);
      final decoded = decodeSyncPayload(encoded);

      expect(decoded, equals(json));
    });

    test('decode は legacy format 1（プレーンJSON）も透過的に扱う', () {
      const legacyJson = '{"version":1,"dreams":[{"id":"d1"}]}';

      // legacy はプレフィックスを持たない
      expect(isCompressedSyncPayload(legacyJson), isFalse);

      final decoded = decodeSyncPayload(legacyJson);

      // そのまま返ってくる
      expect(decoded, equals(legacyJson));
    });

    test('実際のエクスポート形式に近いデータでサイズが大幅に削減される', () {
      // 50 件の繰り返しダミーデータ（実環境に近い）
      final dreams = List.generate(
        50,
        (i) => {
          'id': 'dream-$i',
          'title': 'テスト夢 $i',
          'description': '同じような説明文がたくさん繰り返されると圧縮効率が高くなります。',
          'why': '理由テキスト',
          'category': 'career',
          'sort_order': i,
          'created_at': '2026-04-08T00:00:00.000',
          'updated_at': '2026-04-08T00:00:00.000',
        },
      );
      final data = {
        'version': 1,
        'exported_at': '2026-04-08T00:00:00.000',
        'dreams': dreams,
        'goals': <dynamic>[],
        'tasks': <dynamic>[],
        'books': <dynamic>[],
        'study_logs': <dynamic>[],
        'notifications': <dynamic>[],
      };
      final json = jsonEncode(data);

      final encoded = encodeSyncPayload(json);

      // 繰り返しの多い JSON は gzip で大幅圧縮される（半分以下になるはず）
      expect(encoded.length, lessThan(json.length ~/ 2));
    });

    test('空文字列はそのまま返る（encode/decode 共に）', () {
      expect(encodeSyncPayload(''), '');
      expect(decodeSyncPayload(''), '');
    });

    test('isCompressedSyncPayload は gz1: プレフィックスを判定する', () {
      expect(isCompressedSyncPayload('gz1:somebase64'), isTrue);
      expect(isCompressedSyncPayload('{"a":1}'), isFalse);
      expect(isCompressedSyncPayload(''), isFalse);
      expect(isCompressedSyncPayload('gz1'), isFalse);
    });

    test('format 2 でエンコードしたものは format 1 ではない', () {
      const json = '{"a":"テスト"}';
      final encoded = encodeSyncPayload(json);

      // gz1: プレフィックスがつく
      expect(encoded.startsWith('{'), isFalse);
      expect(encoded.startsWith(syncPayloadFormat2Prefix), isTrue);
    });
  });
}
