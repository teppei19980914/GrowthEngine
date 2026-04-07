/// 書籍ソートのテスト.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:yume_hashi/models/book.dart';

void main() {
  group('書籍ソート', () {
    late List<Book> books;

    setUp(() {
      books = [
        Book(
          title: 'カ行の本',
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 3, 1),
        ),
        Book(
          title: 'ア行の本',
          createdAt: DateTime(2025, 3, 1),
          updatedAt: DateTime(2025, 1, 1),
        ),
        Book(
          title: 'サ行の本',
          createdAt: DateTime(2025, 2, 1),
          updatedAt: DateTime(2025, 2, 1),
        ),
      ];
    });

    test('登録日順（降順）', () {
      final sorted = [...books]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      expect(sorted[0].title, 'ア行の本');
      expect(sorted[1].title, 'サ行の本');
      expect(sorted[2].title, 'カ行の本');
    });

    test('更新日順（降順）', () {
      final sorted = [...books]
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      expect(sorted[0].title, 'カ行の本');
      expect(sorted[1].title, 'サ行の本');
      expect(sorted[2].title, 'ア行の本');
    });

    test('50音順（昇順）', () {
      final sorted = [...books]
        ..sort((a, b) => a.title.compareTo(b.title));
      expect(sorted[0].title, 'ア行の本');
      expect(sorted[1].title, 'カ行の本');
      expect(sorted[2].title, 'サ行の本');
    });
  });
}
