import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yume_log/dialogs/upgrade_dialog.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildApp() {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () => showUpgradeDialog(context),
            child: const Text('Open'),
          ),
        ),
      ),
    );
  }

  testWidgets('タイトルが表示される', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('もっと自由に、もっと先へ'), findsOneWidget);
  });

  testWidgets('プレミアムプラン情報が表示される', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('プレミアムプラン'), findsOneWidget);
    expect(find.text('¥480/月'), findsOneWidget);
  });

  testWidgets('トライアル未開始時は両方のボタンが表示される', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('7日間無料で試してみる'), findsOneWidget);
    expect(find.textContaining('すぐに申し込む'), findsOneWidget);
  });

  testWidgets('価値訴求の機能一覧が表示される', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('やりたいことを、制限なく追いかけられる'), findsOneWidget);
    expect(find.text('やるべきことが一目でわかる'), findsOneWidget);
    expect(find.text('自分の成長が見える'), findsOneWidget);
    expect(find.text('あなたの声が、新機能になる'), findsOneWidget);
  });

  testWidgets('閉じるボタンでダイアログが閉じる', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('もっと自由に、もっと先へ'), findsOneWidget);

    await tester.tap(find.text('閉じる'));
    await tester.pumpAndSettle();

    expect(find.text('もっと自由に、もっと先へ'), findsNothing);
  });

  testWidgets('トライアル開始済みの場合は申し込みボタンが表示される',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'premium_trial_started_at':
          DateTime.now()
              .subtract(const Duration(days: 10))
              .millisecondsSinceEpoch,
    });

    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.textContaining('プレミアムプランに申し込む'), findsOneWidget);
  });
}
