import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yume_hashi/dialogs/onboarding_dialog.dart';

void main() {
  group('shouldShowOnboarding', () {
    test('初回アクセスではtrueを返す', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      expect(shouldShowOnboarding(prefs), isTrue);
    });

    test('オンボーディング完了後はfalseを返す', () async {
      SharedPreferences.setMockInitialValues({'onboarding_completed': true});
      final prefs = await SharedPreferences.getInstance();
      expect(shouldShowOnboarding(prefs), isFalse);
    });
  });

  group('OnboardingDialog', () {
    late SharedPreferences prefs;

    Future<void> pumpDialog(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                showOnboardingDialog(context, prefs);
              });
              return const Scaffold(body: Text('Home'));
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('初回アクセスでオンボーディングが表示される', (tester) async {
      await pumpDialog(tester);

      expect(find.text('あなたには、\n「やりたいこと」がありますか？'), findsOneWidget);
    });

    testWidgets('次へボタンでページが進む', (tester) async {
      await pumpDialog(tester);

      // ページ1
      expect(find.text('あなたには、\n「やりたいこと」がありますか？'), findsOneWidget);

      // ページ2へ
      await tester.tap(find.text('次へ'));
      await tester.pumpAndSettle();
      expect(
        find.text('書き出すことで、\n実現に向けて動き出します。'),
        findsOneWidget,
      );

      // ページ3へ
      await tester.tap(find.text('次へ'));
      await tester.pumpAndSettle();
      expect(
        find.text('一歩踏み出せば、\n自然と前に進めます。'),
        findsOneWidget,
      );

      // ページ4へ
      await tester.tap(find.text('次へ'));
      await tester.pumpAndSettle();
      expect(
        find.text('ユメハシは、あなたの\n「最初の一歩」を支えます。'),
        findsOneWidget,
      );
    });

    testWidgets('戻るボタンで前のページに戻れる', (tester) async {
      await pumpDialog(tester);

      // ページ2へ進む
      await tester.tap(find.text('次へ'));
      await tester.pumpAndSettle();

      // 戻るボタンが表示される
      expect(find.text('戻る'), findsOneWidget);

      // ページ1に戻る
      await tester.tap(find.text('戻る'));
      await tester.pumpAndSettle();
      expect(find.text('あなたには、\n「やりたいこと」がありますか？'), findsOneWidget);
    });

    testWidgets('最終ページではじめるボタンで完了する', (tester) async {
      await pumpDialog(tester);

      // 全ページを進む
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('次へ'));
        await tester.pumpAndSettle();
      }

      // はじめるボタンが表示される
      expect(find.text('はじめる'), findsOneWidget);

      // はじめるをタップ
      await tester.tap(find.text('はじめる'));
      await tester.pumpAndSettle();

      // ダイアログが閉じる
      expect(find.text('Home'), findsOneWidget);

      // SharedPreferencesにフラグが保存される
      expect(prefs.getBool('onboarding_completed'), isTrue);
    });

    testWidgets('完了済みの場合はダイアログが表示されない', (tester) async {
      SharedPreferences.setMockInitialValues({'onboarding_completed': true});
      prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                showOnboardingDialog(context, prefs);
              });
              return const Scaffold(body: Text('Home'));
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // オンボーディングは表示されない
      expect(
        find.text('あなたには、\n「やりたいこと」がありますか？'),
        findsNothing,
      );
    });

    testWidgets('ページインジケーターが表示される', (tester) async {
      await pumpDialog(tester);

      // 4つのインジケーターが表示される
      expect(find.byType(AnimatedContainer), findsNWidgets(4));
    });

    testWidgets('ページ1では戻るボタンが表示されない', (tester) async {
      await pumpDialog(tester);
      expect(find.text('戻る'), findsNothing);
    });
  });
}
