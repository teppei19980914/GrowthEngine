import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yume_log/pages/book_page.dart';
import 'package:yume_log/providers/book_providers.dart';

import '../helpers/test_helpers.dart';

void main() {
  final setup = TestSetup();

  setUp(() => setup.setUp());
  tearDown(() => setup.tearDown());

  Future<SharedPreferences> getPrefs() async =>
      SharedPreferences.getInstance();

  testWidgets('書籍ページが正常にレンダリングされる', (tester) async {
    final prefs = await getPrefs();
    await tester.pumpWidget(
      wrapWithProviders(const BookPage(), prefs: prefs, db: setup.db),
    );
    await tester.pumpAndSettle();

    // タイトル入力欄が表示される
    expect(find.byType(TextField), findsOneWidget);
    // 追加ボタン
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('サンプル書籍が表示される', (tester) async {
    final prefs = await getPrefs();
    await tester.pumpWidget(
      wrapWithProviders(
        const BookPage(),
        prefs: prefs,
        db: setup.db,
        customOverrides: [
          bookListProvider
              .overrideWith(() => SampleBookListNotifier()),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Flutter実践入門'), findsOneWidget);
    expect(find.text('Dart言語ガイド'), findsOneWidget);
  });

  testWidgets('書籍が本棚スタイルで表示される', (tester) async {
    final prefs = await getPrefs();
    await tester.pumpWidget(
      wrapWithProviders(
        const BookPage(),
        prefs: prefs,
        db: setup.db,
        customOverrides: [
          bookListProvider
              .overrideWith(() => SampleBookListNotifier()),
        ],
      ),
    );
    await tester.pumpAndSettle();

    // 背表紙にタイトルが表示される
    expect(find.text('Flutter実践入門'), findsOneWidget);
    expect(find.text('Dart言語ガイド'), findsOneWidget);
  });
}
