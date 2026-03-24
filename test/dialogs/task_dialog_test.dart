import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yume_log/dialogs/task_dialog.dart';
import 'package:yume_log/models/task.dart';

void main() {
  Widget buildApp({Task? task}) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () => showTaskDialog(context, task: task),
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

    expect(find.text('新しいタスクを追加'), findsOneWidget);
    expect(find.text('タスク名'), findsOneWidget);
    expect(find.text('開始日'), findsOneWidget);
    expect(find.text('終了日'), findsOneWidget);
  });

  testWidgets('編集モードでダイアログが表示される', (tester) async {
    final task = Task(
      title: 'テストタスク',
      goalId: 'g1',
      startDate: DateTime(2026, 1, 1),
      endDate: DateTime(2026, 3, 31),
      progress: 50,
    );
    await tester.pumpWidget(buildApp(task: task));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('タスクを編集'), findsOneWidget);
    expect(find.text('テストタスク'), findsOneWidget);
    // 進捗スライダーが表示される（編集モードのみ）
    expect(find.byType(Slider), findsOneWidget);
  });

  testWidgets('新規モードでは進捗スライダーは非表示', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byType(Slider), findsNothing);
  });

  testWidgets('空のタイトルでは保存できない', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('追加'));
    await tester.pumpAndSettle();

    // ダイアログはまだ表示されている
    expect(find.text('新しいタスクを追加'), findsOneWidget);
  });

  testWidgets('キャンセルでダイアログが閉じる', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();

    expect(find.text('新しいタスクを追加'), findsNothing);
  });

  testWidgets('コンテンツがスクロール可能である', (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.text('新しいタスクを追加'), findsOneWidget);
  });
}
