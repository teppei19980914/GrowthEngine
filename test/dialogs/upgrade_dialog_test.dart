import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yume_log/dialogs/upgrade_dialog.dart';

void main() {
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

    expect(find.text('プレミアムプランのご案内'), findsOneWidget);
  });

  testWidgets('ネイティブアプリ購入オプションが表示される', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('ネイティブアプリ（買い切り）'), findsOneWidget);
  });

  testWidgets('WebプレミアムプランのオプションTが表示される', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Webプレミアムプラン（サブスク）'), findsOneWidget);
  });

  testWidgets('プレミアム機能一覧が表示される', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('ガントチャート'), findsOneWidget);
    expect(find.text('Excel出力'), findsOneWidget);
    expect(find.text('目標別統計'), findsOneWidget);
  });

  testWidgets('相互独立の注意書きが表示される', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('ネイティブアプリとWebプレミアムは別々のサービスです'),
      findsOneWidget,
    );
    expect(
      find.textContaining('それぞれ別途ご契約が必要です'),
      findsOneWidget,
    );
  });

  testWidgets('閉じるボタンでダイアログが閉じる', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('プレミアムプランのご案内'), findsOneWidget);

    await tester.tap(find.text('閉じる'));
    await tester.pumpAndSettle();

    expect(find.text('プレミアムプランのご案内'), findsNothing);
  });
}
