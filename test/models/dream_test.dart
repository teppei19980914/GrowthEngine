import 'package:flutter_test/flutter_test.dart';
import 'package:yume_hashi/models/dream.dart';

void main() {
  group('Dream', () {
    test('デフォルト値でDreamを作成する', () {
      final dream = Dream(title: 'テスト');
      expect(dream.title, 'テスト');
      expect(dream.description, '');
      expect(dream.id, isNotEmpty);
      expect(dream.createdAt, isA<DateTime>());
      expect(dream.updatedAt, isA<DateTime>());
    });

    test('全フィールド指定でDreamを作成する', () {
      final now = DateTime(2026, 1, 1);
      final dream = Dream(
        id: 'dream-1',
        title: '医者になる',
        description: '人の役に立ちたい',
        createdAt: now,
        updatedAt: now,
      );
      expect(dream.id, 'dream-1');
      expect(dream.title, '医者になる');
      expect(dream.description, '人の役に立ちたい');
      expect(dream.createdAt, now);
      expect(dream.updatedAt, now);
    });

    test('copyWithでフィールドをコピーする', () {
      final dream = Dream(id: 'dream-1', title: '元のタイトル');
      final copied = dream.copyWith(title: '新しいタイトル');
      expect(copied.title, '新しいタイトル');
      expect(copied.id, 'dream-1');
    });

    test('toMapとfromMapが対称的に動作する', () {
      final now = DateTime(2026, 1, 1);
      final dream = Dream(
        id: 'dream-1',
        title: '医者になる',
        description: '説明文',
        createdAt: now,
        updatedAt: now,
      );
      final map = dream.toMap();
      final restored = Dream.fromMap(map);
      expect(restored.id, dream.id);
      expect(restored.title, dream.title);
      expect(restored.description, dream.description);
      expect(restored.createdAt, dream.createdAt);
      expect(restored.updatedAt, dream.updatedAt);
    });

    test('同じIDのDreamは等価', () {
      final a = Dream(id: 'dream-1', title: 'A');
      final b = Dream(id: 'dream-1', title: 'B');
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('異なるIDのDreamは不等価', () {
      final a = Dream(id: 'dream-1', title: 'A');
      final b = Dream(id: 'dream-2', title: 'A');
      expect(a, isNot(equals(b)));
    });

    test('fromMapでdescriptionがnullの場合空文字になる', () {
      final map = {
        'id': 'dream-1',
        'title': 'テスト',
        'created_at': DateTime(2026).toIso8601String(),
        'updated_at': DateTime(2026).toIso8601String(),
      };
      final dream = Dream.fromMap(map);
      expect(dream.description, '');
    });
  });
}
