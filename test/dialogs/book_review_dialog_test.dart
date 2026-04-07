import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yume_hashi/dialogs/book_review_dialog.dart';

void main() {
  Widget buildApp() {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () =>
                showBookReviewDialog(context, bookTitle: 'テスト書籍'),
            child: const Text('Open'),
          ),
        ),
      ),
    );
  }

  testWidgets('読了レビューダイアログが表示される', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // タイトルは '読了レビュー: テスト書籍'
    expect(find.textContaining('読了レビュー'), findsOneWidget);
    expect(find.textContaining('テスト書籍'), findsOneWidget);
  });

  testWidgets('読了日フィールドが表示される', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('読了日'), findsOneWidget);
  });

  testWidgets('キャンセルでダイアログが閉じる', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();

    expect(find.textContaining('読了レビュー'), findsNothing);
  });

  testWidgets('読了ボタンが表示される', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('読了'), findsOneWidget);
  });

  testWidgets('コンテンツがスクロール可能である', (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.textContaining('読了レビュー'), findsOneWidget);
  });
}
