import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yume_log/dialogs/dream_dialog.dart';
import 'package:yume_log/models/dream.dart';

void main() {
  Widget buildApp({Dream? dream}) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () => showDreamDialog(context, dream: dream),
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

    expect(find.text('新しい夢を追加'), findsOneWidget);
    expect(find.text('タイトル'), findsOneWidget);
    expect(find.text('説明'), findsOneWidget);
    expect(find.text('追加'), findsOneWidget);
  });

  testWidgets('編集モードでダイアログが表示される', (tester) async {
    final dream = Dream(
      id: 'dream-1',
      title: '医者になる',
      description: '人の役に立ちたい',
    );
    await tester.pumpWidget(buildApp(dream: dream));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('夢を編集'), findsOneWidget);
    expect(find.text('医者になる'), findsOneWidget);
    expect(find.text('人の役に立ちたい'), findsOneWidget);
    expect(find.text('更新'), findsOneWidget);
  });

  testWidgets('空のフォームは保存できない', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // 追加ボタンをタップ
    await tester.tap(find.text('追加'));
    await tester.pumpAndSettle();

    // ダイアログはまだ表示されている（バリデーションエラー）
    expect(find.text('新しい夢を追加'), findsOneWidget);
    expect(find.text('必須項目です'), findsOneWidget);
  });

  testWidgets('キャンセルでダイアログが閉じる', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();

    expect(find.text('新しい夢を追加'), findsNothing);
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
    expect(find.text('新しい夢を追加'), findsOneWidget);
  });
}
