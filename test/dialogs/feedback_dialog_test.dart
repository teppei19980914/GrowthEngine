import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yume_hashi/dialogs/feedback_dialog.dart';
import 'package:yume_hashi/services/feedback_service.dart';

void main() {
  late FeedbackService feedbackService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    feedbackService = FeedbackService(prefs);
  });

  Widget wrap() {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showFeedbackDialog(context, feedbackService),
            child: const Text('open'),
          ),
        ),
      ),
    );
  }

  testWidgets('フィードバックダイアログが表示される', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('アプリの感想を送信'), findsOneWidget);
    expect(find.text('カテゴリ *'), findsOneWidget);
    expect(find.text('ご意見・ご感想 *'), findsOneWidget);
    expect(find.text('送信する'), findsOneWidget);
  });

  testWidgets('カテゴリ未選択で送信するとエラー', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final sendButton = find.text('送信する');
    await tester.ensureVisible(sendButton);
    await tester.pumpAndSettle();
    await tester.tap(sendButton);
    await tester.pumpAndSettle();

    expect(find.text('カテゴリの選択は必須です'), findsOneWidget);
  });

  testWidgets('文字数不足で送信するとエラー', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // カテゴリを選択（DropdownButtonFormFieldをタップ）
    await tester.tap(find.byType(DropdownButtonFormField<FeedbackCategory>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('改善要望').last);
    await tester.pumpAndSettle();

    // 短いテキストを入力
    await tester.enterText(find.byType(TextField), 'テスト');
    await tester.pumpAndSettle();

    final sendButton = find.text('送信する');
    await tester.ensureVisible(sendButton);
    await tester.pumpAndSettle();
    await tester.tap(sendButton);
    await tester.pumpAndSettle();

    expect(find.textContaining('15文字以上'), findsOneWidget);
  });

  testWidgets('キャンセルで閉じる', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();

    expect(find.text('アプリの感想を送信'), findsNothing);
  });

  testWidgets('文字数カウンターが表示される', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('あと15文字'), findsOneWidget);
  });

  testWidgets('非体験版（プレミアム）では解除レベル情報が非表示', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // テスト環境は非Web = isPremium = true なので制限解除案内は非表示
    expect(find.textContaining('レベル'), findsNothing);
  });

  testWidgets('匿名送信の注記が表示される', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.textContaining('匿名で送信されます'), findsOneWidget);
    expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
  });

  testWidgets('コンテンツがスクロール可能である', (tester) async {
    tester.view.physicalSize = const Size(400, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrap());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.text('アプリの感想を送信'), findsOneWidget);
  });
}
