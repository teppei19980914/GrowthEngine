import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yume_log/dialogs/dream_discovery_dialog.dart';

void main() {
  Future<void> pumpDialog(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showDreamDiscoveryDialog(context);
            });
            return const Scaffold(body: Text('Home'));
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('ガイドダイアログが表示される', (tester) async {
    await pumpDialog(tester);

    expect(find.text('やりたいこと発見ガイド'), findsOneWidget);
    expect(find.text('いくつかの質問に答えてみましょう'), findsOneWidget);
  });

  testWidgets('質問の選択肢が表示される', (tester) async {
    await pumpDialog(tester);

    expect(find.text('休みの日、つい時間を使ってしまうことは？'), findsOneWidget);
    expect(find.text('本や記事を読む'), findsOneWidget);
    expect(find.text('体を動かす'), findsOneWidget);
  });

  testWidgets('回答を選択すると次へボタンが有効になる', (tester) async {
    await pumpDialog(tester);

    // 選択肢をタップ
    await tester.tap(find.text('本や記事を読む'));
    await tester.pumpAndSettle();

    // 次へボタンが有効
    final nextButton = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(nextButton.onPressed, isNotNull);
  });

  testWidgets('次へでカテゴリページに進む', (tester) async {
    await pumpDialog(tester);

    // 回答を選択
    await tester.tap(find.text('本や記事を読む'));
    await tester.pumpAndSettle();

    // 次へ
    await tester.tap(find.text('次へ'));
    await tester.pumpAndSettle();

    // カテゴリページ
    expect(find.textContaining('気になるカテゴリを選んでください'), findsOneWidget);
    expect(find.text('おすすめ'), findsWidgets);
  });

  testWidgets('カテゴリを選択してテンプレートページに進む', (tester) async {
    await pumpDialog(tester);

    // 回答を選択
    await tester.tap(find.text('本や記事を読む'));
    await tester.pumpAndSettle();

    // カテゴリページへ
    await tester.tap(find.text('次へ'));
    await tester.pumpAndSettle();

    // カテゴリを選択（スクロールして学習・資格を探す）
    await tester.scrollUntilVisible(
      find.text('学習・資格'),
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('学習・資格'));
    await tester.pumpAndSettle();

    // テンプレートページへ
    await tester.tap(find.text('次へ'));
    await tester.pumpAndSettle();

    // テンプレートが表示される
    expect(find.text('学習・資格の夢テンプレート'), findsOneWidget);
    expect(find.text('自分で入力する'), findsOneWidget);
  });

  testWidgets('戻るボタンで前のページに戻れる', (tester) async {
    await pumpDialog(tester);

    // 回答を選択して次へ
    await tester.tap(find.text('本や記事を読む'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('次へ'));
    await tester.pumpAndSettle();

    // 戻る
    await tester.tap(find.text('戻る'));
    await tester.pumpAndSettle();

    // 質問ページに戻る
    expect(find.text('いくつかの質問に答えてみましょう'), findsOneWidget);
  });

  testWidgets('閉じるボタンでダイアログが閉じる', (tester) async {
    await pumpDialog(tester);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
  });
}
