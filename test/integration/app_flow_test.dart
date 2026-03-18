/// アプリ全体の主要フロー統合テスト.
///
/// ページ遷移、目標作成、設定変更などの主要操作フローをテストする.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yume_log/app.dart';

import '../helpers/test_helpers.dart';

void main() {
  final setup = TestSetup();

  setUp(() => setup.setUp());
  tearDown(() => setup.tearDown());

  Future<Widget> buildApp() async {
    final prefs = await SharedPreferences.getInstance();
    return ProviderScope(
      overrides: createTestOverrides(prefs: prefs, db: setup.db),
      child: const YumeLogApp(),
    );
  }

  testWidgets('全ページに遷移できる', (tester) async {
    await tester.pumpWidget(await buildApp());
    await tester.pumpAndSettle();

    // ダッシュボード（初期ページ）
    expect(find.text('ダッシュボード'), findsWidgets);

    // 夢ページ
    await navigateViaDrawerInTest(tester, '夢');
    expect(find.text('夢'), findsWidgets);

    // 目標ページ
    await navigateViaDrawerInTest(tester, '目標');
    expect(find.text('目標'), findsWidgets);

    // ガントチャートページ
    await navigateViaDrawerInTest(tester, 'ガントチャート');
    expect(find.text('ガントチャート'), findsWidgets);

    // 書籍ページ
    await navigateViaDrawerInTest(tester, '書籍');
    expect(find.text('書籍'), findsWidgets);

    // 星座ページ
    await navigateViaDrawerInTest(tester, '星座');
    expect(find.text('星座'), findsWidgets);

    // 統計ページ
    await navigateViaDrawerInTest(tester, '統計');
    expect(find.text('統計'), findsWidgets);

    // 設定ページ
    await navigateViaDrawerInTest(tester, '設定');
    expect(find.text('設定'), findsWidgets);
  });

  testWidgets('目標ページで夢なし時でもダイアログが開く', (tester) async {
    await tester.pumpWidget(await buildApp());
    await tester.pumpAndSettle();

    // 目標ページに遷移
    await navigateViaDrawerInTest(tester, '目標');

    // 追加ボタンをタップ（夢がなくてもダイアログが開く）
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('新しい目標を追加'), findsOneWidget);
    expect(find.text('なし（独立した目標）'), findsOneWidget);
  });

  testWidgets('設定ページでテーマ切替ができる', (tester) async {
    await tester.pumpWidget(await buildApp());
    await tester.pumpAndSettle();

    // 設定ページに遷移
    await navigateViaDrawerInTest(tester, '設定');

    // ダークモード（初期状態）
    expect(find.text('Catppuccin Mocha'), findsOneWidget);

    // テーマトグル
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    // ライトモードに切替
    expect(find.text('Catppuccin Latte'), findsOneWidget);

    // もう一度トグルして戻る
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(find.text('Catppuccin Mocha'), findsOneWidget);
  });

  testWidgets('統計ページに遷移してセクションが表示される', (tester) async {
    await tester.pumpWidget(await buildApp());
    await tester.pumpAndSettle();

    // 統計ページに遷移
    await navigateViaDrawerInTest(tester, '統計');

    expect(find.text('統計'), findsWidgets);
    expect(find.text('サマリー'), findsOneWidget);
  });

  testWidgets('書籍ページに遷移できる', (tester) async {
    await tester.pumpWidget(await buildApp());
    await tester.pumpAndSettle();

    // 書籍ページに遷移
    await navigateViaDrawerInTest(tester, '書籍');

    expect(find.text('書籍'), findsWidgets);
  });
}
