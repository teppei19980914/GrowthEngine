import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yume_log/dialogs/study_log_dialog.dart';

void main() {
  Widget buildApp() {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () =>
                showStudyLogDialog(context, taskName: 'テストタスク'),
            child: const Text('Open'),
          ),
        ),
      ),
    );
  }

  testWidgets('学習ログダイアログが表示される', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // タイトルは '学習ログを記録: テストタスク'
    expect(find.textContaining('学習ログを記録'), findsOneWidget);
    expect(find.textContaining('テストタスク'), findsOneWidget);
    expect(find.text('学習日'), findsOneWidget);
  });

  testWidgets('時間入力フィールドが表示される', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('学習時間'), findsOneWidget);
  });

  testWidgets('0分では保存できない', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // デフォルト値は0時間30分 — 0にするため入力クリア
    await tester.enterText(
      find.byType(TextFormField).at(1), // hours field
      '0',
    );
    await tester.enterText(
      find.byType(TextFormField).at(2), // minutes field
      '0',
    );
    await tester.tap(find.text('記録'));
    await tester.pumpAndSettle();

    // SnackBarが表示される（0分エラー）
    expect(find.textContaining('1分以上'), findsOneWidget);
  });

  testWidgets('キャンセルでダイアログが閉じる', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();

    expect(find.textContaining('学習ログを記録'), findsNothing);
  });
}
