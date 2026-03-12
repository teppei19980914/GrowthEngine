import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yume_log/pages/dashboard_page.dart';
import 'package:yume_log/services/study_stats_types.dart';
import 'package:yume_log/providers/dashboard_providers.dart';

import '../helpers/test_helpers.dart';

void main() {
  final setup = TestSetup();

  setUp(() => setup.setUp());
  tearDown(() => setup.tearDown());

  Future<SharedPreferences> getPrefs() async =>
      SharedPreferences.getInstance();

  testWidgets('ダッシュボードが正常にレンダリングされる', (tester) async {
    final prefs = await getPrefs();
    await tester.pumpWidget(
      wrapWithProviders(const DashboardPage(), prefs: prefs, db: setup.db),
    );
    await tester.pumpAndSettle();

    // 今日の活動バナーが表示される
    expect(find.text('今日は活動済み!'), findsOneWidget);
  });

  testWidgets('合計活動時間が表示される', (tester) async {
    final prefs = await getPrefs();
    await tester.pumpWidget(
      wrapWithProviders(const DashboardPage(), prefs: prefs, db: setup.db),
    );
    await tester.pumpAndSettle();

    expect(find.text('合計活動時間'), findsOneWidget);
    expect(find.text('10.5h'), findsOneWidget);
  });

  testWidgets('連続活動が表示される', (tester) async {
    final prefs = await getPrefs();
    await tester.pumpWidget(
      wrapWithProviders(const DashboardPage(), prefs: prefs, db: setup.db),
    );
    await tester.pumpAndSettle();

    expect(find.text('連続活動'), findsOneWidget);
    expect(find.text('3日'), findsOneWidget);
  });

  testWidgets('目標数が表示される', (tester) async {
    final prefs = await getPrefs();
    await tester.pumpWidget(
      wrapWithProviders(const DashboardPage(), prefs: prefs, db: setup.db),
    );
    await tester.pumpAndSettle();

    expect(find.text('目標数'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('編集ボタンをタップすると編集モードになる', (tester) async {
    final prefs = await getPrefs();
    await tester.pumpWidget(
      wrapWithProviders(const DashboardPage(), prefs: prefs, db: setup.db),
    );
    await tester.pumpAndSettle();

    // 編集ボタンをタップ
    await tester.tap(find.byIcon(Icons.tune_outlined));
    await tester.pumpAndSettle();

    // 完了ボタンが表示される
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    // リセットボタンが表示される
    expect(find.text('リセット'), findsOneWidget);
  });

  testWidgets('未活動状態のバナーを表示する', (tester) async {
    final prefs = await getPrefs();
    await tester.pumpWidget(
      wrapWithProviders(
        const DashboardPage(),
        prefs: prefs,
        db: setup.db,
        customOverrides: [
          todayStudyProvider.overrideWith(
            (ref) async => const TodayStudyData(
              totalMinutes: 0,
              sessionCount: 0,
              studied: false,
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('まだ活動していません'), findsOneWidget);
  });
}
