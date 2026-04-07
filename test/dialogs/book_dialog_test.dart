import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yume_hashi/dialogs/book_dialog.dart';
import 'package:yume_hashi/models/book.dart';

void main() {
  Widget buildApp({Book? book}) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () => showBookDialog(context, book: book),
            child: const Text('Open'),
          ),
        ),
      ),
    );
  }

  testWidgets('新規追加モードでダイアログが表示される', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('書籍を追加'), findsOneWidget);
    expect(find.text('書籍名 *'), findsOneWidget);
    expect(find.text('カテゴリ'), findsOneWidget);
    expect(find.text('なぜ読むのか'), findsOneWidget);
    expect(find.text('内容メモ'), findsOneWidget);
  });

  testWidgets('編集モードでダイアログが表示される', (tester) async {
    final book = Book(
      title: 'テスト書籍',
      category: BookCategory.it,
      why: 'テスト理由',
      description: 'テスト内容',
    );
    await tester.pumpWidget(buildApp(book: book));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('書籍を編集'), findsOneWidget);
    expect(find.text('テスト書籍'), findsOneWidget);
    expect(find.text('テスト理由'), findsOneWidget);
    expect(find.text('テスト内容'), findsOneWidget);
  });

  testWidgets('空のフォームは保存できない', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('追加'));
    await tester.pumpAndSettle();

    expect(find.text('書籍名は必須です'), findsOneWidget);
    expect(find.text('書籍を追加'), findsOneWidget);
  });

  testWidgets('キャンセルでダイアログが閉じる', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();

    expect(find.text('書籍を追加'), findsNothing);
  });

  testWidgets('コンテンツがスクロール可能である', (tester) async {
    // 小さい画面サイズでテスト
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // SingleChildScrollView が存在すること
    expect(find.byType(SingleChildScrollView), findsOneWidget);

    // ダイアログが表示されていること
    expect(find.text('書籍を追加'), findsOneWidget);
  });

  testWidgets('編集モードで削除ボタンが表示される', (tester) async {
    final book = Book(title: 'テスト書籍');
    await tester.pumpWidget(buildApp(book: book));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('削除'), findsOneWidget);
  });

  testWidgets('新規追加モードで削除ボタンが表示されない', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('削除'), findsNothing);
  });
}
