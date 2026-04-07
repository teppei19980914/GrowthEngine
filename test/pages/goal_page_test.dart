import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yume_hashi/pages/goal_page.dart';
import 'package:yume_hashi/providers/dream_providers.dart';
import 'package:yume_hashi/providers/goal_providers.dart';

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
    expect(find.textContaining('目標'), findsWidgets);
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
    expect(find.text('Flutter活動'), findsOneWidget);
    expect(find.text('基本情報技術者'), findsOneWidget);
  });

  testWidgets('目標カードのWhatが表示される', (tester) async {
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

    // WhyはDream側に移動したためGoalカードには表示されない
    expect(find.text('スキルアップ'), findsNothing);
    // HowはカードUIから削除されたため表示されない
    expect(find.text('毎日1時間'), findsNothing);
    // Whatはカードのタイトルとして表示される
    expect(find.text('Flutter活動'), findsOneWidget);
    expect(find.text('基本情報技術者'), findsOneWidget);
  });

  testWidgets('夢がない状態でも追加ボタンでダイアログが開く',
      (tester) async {
    final prefs = await getPrefs();
    await tester.pumpWidget(
      wrapWithProviders(const GoalPage(), prefs: prefs, db: setup.db),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // 夢がなくてもダイアログが表示される
    expect(find.text('新しい目標を追加'), findsOneWidget);
    // 「なし（独立した目標）」の選択肢が表示される
    expect(find.text('なし（独立した目標）'), findsOneWidget);
  });

  testWidgets('夢別にグルーピングされて夢名が表示される', (tester) async {
    final prefs = await getPrefs();
    await tester.pumpWidget(
      wrapWithProviders(
        const GoalPage(),
        prefs: prefs,
        db: setup.db,
        customOverrides: [
          goalListProvider.overrideWith(() => SampleGoalListNotifier()),
          dreamListProvider.overrideWith(() => SampleDreamListNotifier()),
        ],
      ),
    );
    await tester.pumpAndSettle();

    // 夢名がセクションヘッダーとして表示される
    expect(find.text('医者になる'), findsOneWidget);
    // 目標が表示される
    expect(find.text('Flutter活動'), findsOneWidget);
    expect(find.text('基本情報技術者'), findsOneWidget);
  });

  testWidgets('独立目標セクションが表示される', (tester) async {
    final prefs = await getPrefs();
    await tester.pumpWidget(
      wrapWithProviders(
        const GoalPage(),
        prefs: prefs,
        db: setup.db,
        customOverrides: [
          goalListProvider
              .overrideWith(() => StandaloneGoalListNotifier()),
        ],
      ),
    );
    await tester.pumpAndSettle();

    // 独立目標セクションが表示される
    expect(find.text('独立した目標'), findsOneWidget);
    expect(find.text('独立目標テスト'), findsOneWidget);
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
