import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yume_log/pages/stats_page.dart';

import '../helpers/test_helpers.dart';

void main() {
  final setup = TestSetup();

  setUp(() => setup.setUp());
  tearDown(() => setup.tearDown());

  Future<SharedPreferences> getPrefs() async =>
      SharedPreferences.getInstance();

  testWidgets('統計ページが正常にレンダリングされる', (tester) async {
    final prefs = await getPrefs();
    await tester.pumpWidget(
      wrapWithProviders(const StatsPage(), prefs: prefs, db: setup.db),
    );
    await tester.pumpAndSettle();

    expect(find.text('サマリー'), findsOneWidget);
    expect(find.text('自己ベスト'), findsOneWidget);
    expect(find.text('活動の実施率'), findsOneWidget);
    expect(find.text('アクティビティ'), findsOneWidget);
  });

  testWidgets('合計活動時間がサマリーに表示される', (tester) async {
    final prefs = await getPrefs();
    await tester.pumpWidget(
      wrapWithProviders(const StatsPage(), prefs: prefs, db: setup.db),
    );
    await tester.pumpAndSettle();

    expect(find.text('10.5h'), findsWidgets);
  });

  testWidgets('連続活動がサマリーに表示される', (tester) async {
    final prefs = await getPrefs();
    await tester.pumpWidget(
      wrapWithProviders(const StatsPage(), prefs: prefs, db: setup.db),
    );
    await tester.pumpAndSettle();

    expect(find.text('3日'), findsWidgets);
  });

  testWidgets('実施率のプログレスバーが表示される', (tester) async {
    final prefs = await getPrefs();
    await tester.pumpWidget(
      wrapWithProviders(const StatsPage(), prefs: prefs, db: setup.db),
    );
    await tester.pumpAndSettle();

    expect(find.text('70%'), findsOneWidget);
  });

  testWidgets('自己ベストが表示される', (tester) async {
    final prefs = await getPrefs();
    await tester.pumpWidget(
      wrapWithProviders(const StatsPage(), prefs: prefs, db: setup.db),
    );
    await tester.pumpAndSettle();

    expect(find.text('1日の最高活動時間'), findsOneWidget);
    expect(find.text('2時間'), findsOneWidget);
  });

  testWidgets('最近のログセクションが表示される', (tester) async {
    final prefs = await getPrefs();
    await tester.pumpWidget(
      wrapWithProviders(const StatsPage(), prefs: prefs, db: setup.db),
    );
    await tester.pumpAndSettle();

    expect(find.text('最近の活動ログ'), findsOneWidget);
  });
}
