import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yume_log/widgets/contact/contact_button.dart';

void main() {
  Widget buildApp() {
    SharedPreferences.setMockInitialValues({
      'onboarding_completed': true,
    });
    return const ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          appBar: _TestAppBar(),
          body: SizedBox.shrink(),
        ),
      ),
    );
  }

  testWidgets('メールアイコンが表示される', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.mail_outline), findsWidgets);
  });

  testWidgets('タップで選択メニューが表示される', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.mail_outline).first);
    await tester.pumpAndSettle();

    expect(find.text('ご意見・お問い合わせ'), findsOneWidget);
    expect(find.text('フィードバックを送る'), findsOneWidget);
    expect(find.text('お問い合わせ'), findsOneWidget);
  });

  testWidgets('メニューのサブタイトルが表示される', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.mail_outline).first);
    await tester.pumpAndSettle();

    expect(find.text('アプリへのご意見・改善要望'), findsOneWidget);
    expect(find.text('追加開発・案件のご相談など'), findsOneWidget);
  });
}

class _TestAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _TestAppBar();

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Test'),
      actions: const [ContactButton()],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
