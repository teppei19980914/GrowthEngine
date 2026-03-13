import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yume_log/widgets/web/web_trial_banner.dart';

void main() {
  group('WebTrialBanner', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    // kIsWeb はテスト環境では常に false
    testWidgets('テスト環境(非Web)ではバナーが表示されない', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: WebTrialBanner(prefs: prefs))),
      );

      expect(find.text('Web体験版をご利用中です'), findsNothing);
    });

    testWidgets('テスト環境(非Web)では初回ダイアログが表示されない', (tester) async {
      late BuildContext savedContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              savedContext = context;
              return const SizedBox();
            },
          ),
        ),
      );

      final shown = await showWebTrialDialogIfNeeded(savedContext, prefs);
      await tester.pumpAndSettle();

      expect(shown, isFalse);
      expect(find.text('Web体験版について'), findsNothing);
    });
  });
}
