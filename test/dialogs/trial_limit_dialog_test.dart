import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_planner/dialogs/trial_limit_dialog.dart';

void main() {
  Widget buildApp({
    required String itemName,
    required int currentCount,
    required int maxCount,
  }) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () => showTrialLimitDialog(
              context,
              itemName: itemName,
              currentCount: currentCount,
              maxCount: maxCount,
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );
  }

  group('ダイアログ表示', () {
    testWidgets('夢の上限タイトルが正しく表示される', (tester) async {
      await tester.pumpWidget(buildApp(
        itemName: '夢',
        currentCount: 2,
        maxCount: 2,
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('夢の上限に達しました'), findsOneWidget);
    });

    testWidgets('書籍の上限タイトルが正しく表示される', (tester) async {
      await tester.pumpWidget(buildApp(
        itemName: '書籍',
        currentCount: 5,
        maxCount: 5,
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('書籍の上限に達しました'), findsOneWidget);
    });

    testWidgets('目標の上限タイトルが正しく表示される', (tester) async {
      await tester.pumpWidget(buildApp(
        itemName: '目標',
        currentCount: 3,
        maxCount: 3,
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('目標の上限に達しました'), findsOneWidget);
    });
  });

  testWidgets('使用量バーに現在数/最大数が表示される', (tester) async {
    await tester.pumpWidget(buildApp(
      itemName: '夢',
      currentCount: 2,
      maxCount: 2,
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('2 / 2'), findsOneWidget);
  });

  testWidgets('デスクトップ版アップグレードメッセージが表示される', (tester) async {
    await tester.pumpWidget(buildApp(
      itemName: '夢',
      currentCount: 2,
      maxCount: 2,
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('デスクトップ版なら無制限'), findsOneWidget);
    expect(
      find.text('デスクトップ版をインストールすると、'
          '全ての機能を制限なくご利用いただけます。'),
      findsOneWidget,
    );
  });

  testWidgets('Web体験版の制限テキストが表示される', (tester) async {
    await tester.pumpWidget(buildApp(
      itemName: '夢',
      currentCount: 2,
      maxCount: 2,
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Web体験版では夢を2件まで登録できます。'), findsOneWidget);
  });

  testWidgets('閉じるボタンでダイアログが閉じる', (tester) async {
    await tester.pumpWidget(buildApp(
      itemName: '夢',
      currentCount: 2,
      maxCount: 2,
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // ダイアログが表示されていることを確認
    expect(find.text('夢の上限に達しました'), findsOneWidget);

    // 閉じるボタンをタップ
    await tester.tap(find.text('閉じる'));
    await tester.pumpAndSettle();

    // ダイアログが閉じたことを確認
    expect(find.text('夢の上限に達しました'), findsNothing);
  });
}
