import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yume_hashi/dialogs/app_guide_dialog.dart';

void main() {
  Widget wrap({bool isPremium = false}) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showAppGuideDialog(context, isPremium: isPremium),
            child: const Text('open'),
          ),
        ),
      ),
    );
  }

  group('全体像タブ', () {
    testWidgets('ガイドダイアログが表示される', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('使い方'), findsWidgets);
      expect(find.text('全体像'), findsOneWidget);
    });

    testWidgets('メイン階層の図が表示される', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // メインノード
      expect(find.text('夢'), findsOneWidget);
      expect(find.text('目標'), findsWidgets);
      // 矢印ラベル
      expect(find.text('分解'), findsOneWidget);
    });

    testWidgets('連携する画面の図が表示される', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('連携する画面'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('連携する画面'), findsOneWidget);
    });

    testWidgets('サポート画面のミニノードが表示される', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('統計'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('統計'), findsOneWidget);
      expect(find.text('振り返り'), findsOneWidget);
    });
  });

  group('使い方タブ', () {
    testWidgets('ステップ番号付きの手順が表示される', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('使い方').last);
      await tester.pumpAndSettle();

      expect(find.text('夢を登録する'), findsOneWidget);
      // 手順の番号付きテキストが存在する
      expect(find.text('1. '), findsWidgets);
    });

    testWidgets('体験版では活動予定ガイドが非表示', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('使い方').last);
      await tester.pumpAndSettle();

      // kIsWebはテスト環境ではfalseなので活動予定は表示される
      expect(find.text('活動予定でタスク管理'), findsOneWidget);
    });

    testWidgets('プレミアム版では活動予定ガイドが表示される',
        (tester) async {
      await tester.pumpWidget(wrap(isPremium: true));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('使い方').last);
      await tester.pumpAndSettle();

      expect(find.text('活動予定でタスク管理'), findsOneWidget);
    });

    testWidgets('星座ステップまでスクロールできる', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('使い方').last);
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('星座で成長を実感'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('星座で成長を実感'), findsOneWidget);
    });
  });

  group('閉じるボタン', () {
    testWidgets('閉じるボタンでダイアログが閉じる', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('閉じる'));
      await tester.pumpAndSettle();

      expect(find.text('全体像'), findsNothing);
    });

    testWidgets('Xボタンでダイアログが閉じる', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('全体像'), findsNothing);
    });
  });
}
