import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yume_log/pages/goal_page.dart';
import 'package:yume_log/providers/dream_providers.dart';
import 'package:yume_log/providers/goal_providers.dart';

import '../helpers/test_helpers.dart';

void main() {
  final setup = TestSetup();

  setUp(() => setup.setUp());
  tearDown(() => setup.tearDown());

  Future<SharedPreferences> getPrefs() async =>
      SharedPreferences.getInstance();

  testWidgets('空の目標リストが表示される', (tester) async {
    final prefs = await getPrefs();
    await tester.pumpWidget(
      wrapWithProviders(const GoalPage(), prefs: prefs, db: setup.db),
    );
    await tester.pumpAndSettle();

    // 追加ボタンが表示される
    expect(find.byIcon(Icons.add), findsOneWidget);
    // ヘッダー説明テキスト
    expect(find.textContaining('3W1H'), findsWidgets);
  });

  testWidgets('サンプル目標が表示される', (tester) async {
    final prefs = await getPrefs();
    await tester.pumpWidget(
      wrapWithProviders(
        const GoalPage(),
        prefs: prefs,
        db: setup.db,
        customOverrides: [
          goalListProvider
              .overrideWith(() => SampleGoalListNotifier()),
        ],
      ),
    );
    await tester.pumpAndSettle();

    // 目標タイトルが表示される
    expect(find.text('Flutter学習'), findsOneWidget);
    expect(find.text('基本情報技術者'), findsOneWidget);
  });

  testWidgets('目標カードのWhy/Howが表示される', (tester) async {
    final prefs = await getPrefs();
    await tester.pumpWidget(
      wrapWithProviders(
        const GoalPage(),
        prefs: prefs,
        db: setup.db,
        customOverrides: [
          goalListProvider
              .overrideWith(() => SampleGoalListNotifier()),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('スキルアップ'), findsOneWidget);
    expect(find.text('毎日1時間'), findsOneWidget);
  });

  testWidgets('夢がない状態で追加ボタンをタップするとSnackBarが表示される',
      (tester) async {
    final prefs = await getPrefs();
    await tester.pumpWidget(
      wrapWithProviders(const GoalPage(), prefs: prefs, db: setup.db),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // 夢がないのでSnackBarが表示される
    expect(find.text('先に「夢」を登録してください'), findsOneWidget);
  });

  testWidgets('夢がある状態で追加ボタンをタップするとダイアログが開く',
      (tester) async {
    final prefs = await getPrefs();
    await tester.pumpWidget(
      wrapWithProviders(
        const GoalPage(),
        prefs: prefs,
        db: setup.db,
        customOverrides: [
          dreamListProvider
              .overrideWith(() => SampleDreamListNotifier()),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // ダイアログが表示される
    expect(find.text('新しい目標を追加'), findsOneWidget);
  });
}
