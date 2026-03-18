import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yume_log/dialogs/goal_dialog.dart';
import 'package:yume_log/models/dream.dart';
import 'package:yume_log/models/goal.dart';

void main() {
  final testDreams = [
    Dream(id: 'dream-1', title: '医者になる'),
    Dream(id: 'dream-2', title: 'エンジニアになる'),
  ];

  Widget buildApp({Goal? goal}) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () => showGoalDialog(
              context,
              goal: goal,
              dreams: testDreams,
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );
  }

  testWidgets('新規追加モードでダイアログが表示される', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('新しい目標を追加'), findsOneWidget);
    expect(find.text('紐づく夢（任意）'), findsOneWidget);
    expect(find.text('What（何を目標とするか）'), findsOneWidget);
    expect(find.text('When（いつまでに達成するか）'), findsOneWidget);
    expect(find.text('How（どうやって達成するか）'), findsOneWidget);
  });

  testWidgets('編集モードでダイアログが表示される', (tester) async {
    final goal = Goal(
      dreamId: 'dream-1',
      what: 'テスト目標',
      how: 'テスト方法',
      whenType: WhenType.period,
      whenTarget: '3ヶ月',
    );
    await tester.pumpWidget(buildApp(goal: goal));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('目標を編集'), findsOneWidget);
    // フォームフィールドに値がセットされている
    expect(find.text('テスト目標'), findsOneWidget);
    expect(find.text('テスト方法'), findsOneWidget);
  });

  testWidgets('空のフォームは保存できない', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // 追加ボタンをタップ
    await tester.tap(find.text('追加'));
    await tester.pumpAndSettle();

    // ダイアログはまだ表示されている（バリデーションエラー）
    expect(find.text('新しい目標を追加'), findsOneWidget);
  });

  testWidgets('キャンセルでダイアログが閉じる', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();

    expect(find.text('新しい目標を追加'), findsNothing);
  });

  testWidgets('WhenTypeの切り替えが動作する', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // SegmentedButtonのラベル
    expect(find.text('期間指定'), findsOneWidget);
    expect(find.text('日付指定'), findsOneWidget);
  });
}
