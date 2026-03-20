import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yume_log/dialogs/trial_limit_dialog.dart';
import 'package:yume_log/services/feedback_service.dart';

void main() {
  late FeedbackService feedbackService;

  http.Client createMockClient() {
    return MockClient((request) async {
      return http.Response(jsonEncode({'success': true}), 200);
    });
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    feedbackService = FeedbackService(prefs, httpClient: createMockClient());
  });

  Widget buildApp({
    required String itemName,
    required int currentCount,
    required int maxCount,
    FeedbackService? fbService,
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
              feedbackService: fbService,
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

  testWidgets('スタータープランの制限テキストが表示される', (tester) async {
    await tester.pumpWidget(buildApp(
      itemName: '夢',
      currentCount: 2,
      maxCount: 2,
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('スタータープランでは夢を2件まで登録できます。'), findsOneWidget);
  });

  testWidgets('閉じるボタンでダイアログが閉じる', (tester) async {
    await tester.pumpWidget(buildApp(
      itemName: '夢',
      currentCount: 2,
      maxCount: 2,
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('夢の上限に達しました'), findsOneWidget);

    await tester.tap(find.text('閉じる'));
    await tester.pumpAndSettle();

    expect(find.text('夢の上限に達しました'), findsNothing);
  });

  testWidgets('feedbackServiceありでフィードバックボタンが表示される',
      (tester) async {
    await tester.pumpWidget(buildApp(
      itemName: '夢',
      currentCount: 2,
      maxCount: 2,
      fbService: feedbackService,
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('フィードバックで制限を解除'), findsOneWidget);
    expect(find.text('フィードバックを送信'), findsOneWidget);
  });

  testWidgets('feedbackServiceなしでフィードバックボタンが非表示',
      (tester) async {
    await tester.pumpWidget(buildApp(
      itemName: '夢',
      currentCount: 2,
      maxCount: 2,
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('フィードバックを送信'), findsNothing);
  });

  testWidgets('最大レベル時はフィードバックボタンが非表示', (tester) async {
    SharedPreferences.setMockInitialValues({'feedback_unlock_level': 3});
    final prefs = await SharedPreferences.getInstance();
    final maxService = FeedbackService(prefs, httpClient: createMockClient());

    await tester.pumpWidget(buildApp(
      itemName: '夢',
      currentCount: 2,
      maxCount: 2,
      fbService: maxService,
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('フィードバックを送信'), findsNothing);
    expect(find.textContaining('完全に解除'), findsOneWidget);
  });

  testWidgets('フィードバック上限到達時は課金案内ボタンが表示される', (tester) async {
    SharedPreferences.setMockInitialValues({'feedback_unlock_level': 2});
    final prefs = await SharedPreferences.getInstance();
    final level2Service =
        FeedbackService(prefs, httpClient: createMockClient());

    await tester.pumpWidget(buildApp(
      itemName: '夢',
      currentCount: 6,
      maxCount: 6,
      fbService: level2Service,
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // フィードバックボタンではなく課金案内ボタンが表示
    expect(find.text('フィードバックを送信'), findsNothing);
    expect(find.text('無制限プランを見る'), findsOneWidget);
    expect(find.textContaining('フィードバックによる解除は上限に達しました'),
        findsOneWidget);
  });
}
