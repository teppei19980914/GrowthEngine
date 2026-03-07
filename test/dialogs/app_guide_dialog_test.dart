import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yume_log/dialogs/app_guide_dialog.dart';

void main() {
  Widget wrap() {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showAppGuideDialog(context),
            child: const Text('open'),
          ),
        ),
      ),
    );
  }

  testWidgets('ガイドダイアログが表示される', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('ユメログの使い方'), findsOneWidget);
    expect(find.text('ステップ1: 夢を登録'), findsOneWidget);
    expect(find.text('1 / 6'), findsOneWidget);
  });

  testWidgets('次へボタンでページを進められる', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('次へ'));
    await tester.pumpAndSettle();

    expect(find.text('ステップ2: 目標を設定'), findsOneWidget);
    expect(find.text('2 / 6'), findsOneWidget);
  });

  testWidgets('戻るボタンで前ページに戻れる', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('次へ'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('戻る'));
    await tester.pumpAndSettle();

    expect(find.text('ステップ1: 夢を登録'), findsOneWidget);
  });

  testWidgets('最後のページではじめるボタンで閉じる', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // 最後のページまで進む
    for (var i = 0; i < 5; i++) {
      await tester.tap(find.text('次へ'));
      await tester.pumpAndSettle();
    }

    expect(find.text('ステップ6: 星座で成長を実感'), findsOneWidget);
    expect(find.text('6 / 6'), findsOneWidget);
    expect(find.text('はじめる'), findsOneWidget);

    await tester.tap(find.text('はじめる'));
    await tester.pumpAndSettle();

    expect(find.text('ユメログの使い方'), findsNothing);
  });

  testWidgets('最初のページで閉じるボタンで閉じる', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('閉じる'));
    await tester.pumpAndSettle();

    expect(find.text('ユメログの使い方'), findsNothing);
  });
}
