/// 書籍ソートのテスト.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yume_hashi/models/book.dart';
import 'package:yume_hashi/providers/book_providers.dart';
import 'package:yume_hashi/providers/theme_provider.dart'
    show sharedPreferencesProvider;

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

  group('bookSortOrderProvider の永続化', () {
    test('初期値はキャッシュがなければ created', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      expect(container.read(bookSortOrderProvider), BookSortOrder.created);
    });

    test('SharedPreferences に保存された値が読み込まれる', () async {
      SharedPreferences.setMockInitialValues({
        bookSortOrderPrefsKey: 'title',
      });
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      expect(container.read(bookSortOrderProvider), BookSortOrder.title);
    });

    test('setSortOrder で変更した値が SharedPreferences に保存される', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      container
          .read(bookSortOrderProvider.notifier)
          .setSortOrder(BookSortOrder.updated);

      expect(container.read(bookSortOrderProvider), BookSortOrder.updated);
      expect(prefs.getString(bookSortOrderPrefsKey), 'updated');
    });

    test('不明な値は created にフォールバックする', () async {
      SharedPreferences.setMockInitialValues({
        bookSortOrderPrefsKey: 'unknown_value',
      });
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      expect(container.read(bookSortOrderProvider), BookSortOrder.created);
    });
  });
}
