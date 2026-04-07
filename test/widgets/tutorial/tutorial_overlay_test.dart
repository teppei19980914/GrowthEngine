import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yume_hashi/providers/theme_provider.dart';
import 'package:yume_hashi/services/tutorial_service.dart';
import 'package:yume_hashi/widgets/tutorial/tutorial_overlay.dart';
import 'package:yume_hashi/widgets/tutorial/tutorial_target_keys.dart';

/// テスト用のラッパー（実際のアプリ構造を再現）.
///
/// - TutorialOverlay: MaterialApp.builder 内（ダイアログより上）
/// - TutorialSpotlight: Scaffold body 内（ダイアログより下）
Widget _buildApp({
  required SharedPreferences prefs,
  required Widget body,
}) {
  final router = GoRouter(
    navigatorKey: TutorialTargetKeys.navigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(
          body: Stack(
            children: [
              body,
              const TutorialSpotlight(),
            ],
          ),
        ),
      ),
      GoRoute(path: '/dreams', builder: (_, _) => const Scaffold()),
      GoRoute(path: '/goals', builder: (_, _) => const Scaffold()),
      GoRoute(path: '/gantt', builder: (_, _) => const Scaffold()),
    ],
  );

  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      builder: (context, child) => Stack(
        children: [
          child!,
          const TutorialOverlay(),
        ],
      ),
    ),
  );
}

void main() {
  group('TutorialOverlay', () {
    late SharedPreferences prefs;

    testWidgets('チュートリアル非アクティブ時はオーバーレイが表示されない',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(_buildApp(
        prefs: prefs,
        body: const Center(child: Text('メイン')),
      ));
      await tester.pump();

      // 吹き出しもスポットライトも表示されない
      expect(find.text('チュートリアル完了！'), findsNothing);
      expect(find.textContaining('ステップ'), findsNothing);
    });

    testWidgets('チュートリアル完了時に完了ダイアログが表示される',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'tutorial_active': true,
        'tutorial_step': 7,
      });
      prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(_buildApp(
        prefs: prefs,
        body: const Center(child: Text('メイン')),
      ));
      await tester.pump();

      expect(find.text('チュートリアル完了！'), findsOneWidget);
      expect(find.text('データを削除'), findsOneWidget);
      expect(find.text('データを保持'), findsOneWidget);
    });

    testWidgets('設定画面から再実行の案内が完了オーバーレイに表示される',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'tutorial_active': true,
        'tutorial_step': 7,
      });
      prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(_buildApp(
        prefs: prefs,
        body: const Center(child: Text('メイン')),
      ));
      await tester.pump();

      expect(
        find.textContaining('設定画面からいつでもチュートリアルを再実行できます'),
        findsOneWidget,
      );
    });

    testWidgets('完了時にデータを保持を選択するとオーバーレイが閉じる',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'tutorial_active': true,
        'tutorial_step': 7,
      });
      prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(_buildApp(
        prefs: prefs,
        body: const Center(child: Text('メイン')),
      ));
      await tester.pump();

      expect(find.text('チュートリアル完了！'), findsOneWidget);

      await tester.tap(find.text('データを保持'));
      await tester.pump();

      expect(find.text('チュートリアル完了！'), findsNothing);
    });

    testWidgets('アクティブ時にターゲット付近に吹き出しが表示される',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'tutorial_active': true,
        'tutorial_step': 0,
      });
      prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(_buildApp(
        prefs: prefs,
        body: Center(
          child: ElevatedButton(
            key: TutorialTargetKeys.dreamTab,
            onPressed: () {},
            child: const Text('夢タブ'),
          ),
        ),
      ));
      await tester.pump();
      await tester.pump();

      // 吹き出しにステップ番号と指示テキストが表示される
      expect(find.textContaining('ステップ 1 / 7'), findsOneWidget);
      expect(
        find.text(TutorialStep.goToDreams.instruction),
        findsOneWidget,
      );
    });

    testWidgets('×ボタンでチュートリアルが中断される', (tester) async {
      SharedPreferences.setMockInitialValues({
        'tutorial_active': true,
        'tutorial_step': 0,
      });
      prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(_buildApp(
        prefs: prefs,
        body: Center(
          child: ElevatedButton(
            key: TutorialTargetKeys.dreamTab,
            onPressed: () {},
            child: const Text('夢タブ'),
          ),
        ),
      ));
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('ステップ 1 / 7'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(find.textContaining('ステップ'), findsNothing);
    });

    testWidgets('ターゲットが未マウント時はフローティング吹き出しが表示される',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'tutorial_active': true,
        'tutorial_step': 1, // addDream → addDreamButton (不在)
      });
      prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(_buildApp(
        prefs: prefs,
        body: const Center(child: Text('ターゲットなし')),
      ));
      await tester.pump();
      await tester.pump();

      // ターゲットが見つからなくてもフローティング吹き出しが表示される
      expect(find.textContaining('ステップ 2 / 7'), findsOneWidget);
      expect(
        find.text(TutorialStep.addDream.instruction),
        findsOneWidget,
      );
    });

    testWidgets('グレーアウトはタップを透過する（IgnorePointer）',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'tutorial_active': true,
        'tutorial_step': 0,
      });
      prefs = await SharedPreferences.getInstance();

      var tapped = false;
      await tester.pumpWidget(_buildApp(
        prefs: prefs,
        body: Center(
          child: ElevatedButton(
            key: TutorialTargetKeys.dreamTab,
            onPressed: () => tapped = true,
            child: const Text('夢タブ'),
          ),
        ),
      ));
      await tester.pump();
      await tester.pump();

      // スポットライト外のボタンもタップできる
      await tester.tap(find.text('夢タブ'));
      expect(tapped, isTrue);
    });

    testWidgets('スポットライトがターゲット存在時に表示される',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'tutorial_active': true,
        'tutorial_step': 0,
      });
      prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(_buildApp(
        prefs: prefs,
        body: Center(
          child: ElevatedButton(
            key: TutorialTargetKeys.dreamTab,
            onPressed: () {},
            child: const Text('夢タブ'),
          ),
        ),
      ));
      await tester.pump();
      await tester.pump();

      // TutorialSpotlight がスポットライトを描画している
      expect(find.byType(TutorialSpotlight), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('ターゲットなしのaddTaskステップでWeb制限メッセージが表示される',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'tutorial_active': true,
        'tutorial_step': 5, // addTask (ターゲットなし)
      });
      prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(_buildApp(
        prefs: prefs,
        body: const Center(child: Text('活動予定')),
      ));
      await tester.pump();
      await tester.pump();

      expect(
        find.textContaining('活動予定で目標達成までの道のりを可視化しよう'),
        findsOneWidget,
      );
      expect(
        find.textContaining('プレミアムプランにアップグレードすると'),
        findsOneWidget,
      );
    });

    testWidgets('addTaskステップの×ボタンでexplainAppBarステップに進む',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'tutorial_active': true,
        'tutorial_step': 5, // addTask (ターゲットなし)
      });
      prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(_buildApp(
        prefs: prefs,
        body: const Center(child: Text('活動予定')),
      ));
      await tester.pump();
      await tester.pump();

      // ×ボタンタップでexplainAppBarステップに遷移
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      // 完了ダイアログではなく次のステップに進む
      expect(find.text('チュートリアル完了！'), findsNothing);
    });

    testWidgets('フローティング吹き出しの×ボタンでチュートリアルが中断される',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'tutorial_active': true,
        'tutorial_step': 1, // addDreamButton (不在)
      });
      prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(_buildApp(
        prefs: prefs,
        body: const Center(child: Text('ターゲットなし')),
      ));
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('ステップ 2 / 7'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(find.textContaining('ステップ'), findsNothing);
    });
  });
}
