import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yume_log/dialogs/book_schedule_dialog.dart';
import 'package:yume_log/models/book.dart';

void main() {
  Widget buildApp({Book? book, List<Book> unscheduledBooks = const []}) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () => showBookScheduleDialog(
              context,
              book: book,
              unscheduledBooks: unscheduledBooks,
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );
  }

  testWidgets('追加モードで正しいタイトルが表示される', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('読書スケジュールを追加'), findsOneWidget);
    expect(find.text('追加'), findsOneWidget);
  });

  testWidgets('編集モードで正しいタイトルとデータが表示される', (tester) async {
    final book = Book(
      id: 'book-1',
      title: 'Flutter実践入門',
      startDate: DateTime(2026, 3, 1),
      endDate: DateTime(2026, 3, 31),
      progress: 50,
    );
    await tester.pumpWidget(buildApp(book: book));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('読書スケジュールを編集'), findsOneWidget);
    expect(find.text('Flutter実践入門'), findsOneWidget);
    expect(find.text('2026-03-01'), findsOneWidget);
    expect(find.text('2026-03-31'), findsOneWidget);
    expect(find.text('50%'), findsWidgets);
    expect(find.text('保存'), findsOneWidget);
  });

  testWidgets('空のタイトルでバリデーションエラーが表示される', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // タイトルを空のまま追加ボタンをタップ
    await tester.tap(find.text('追加'));
    await tester.pumpAndSettle();

    // ダイアログはまだ表示されている（バリデーションエラー）
    expect(find.text('読書スケジュールを追加'), findsOneWidget);
    expect(find.text('書籍名は必須です'), findsOneWidget);
  });

  group('ステータスラベル', () {
    testWidgets('進捗0%で未読と表示される', (tester) async {
      final book = Book(
        id: 'book-1',
        title: 'テスト本',
        startDate: DateTime(2026, 3, 1),
        endDate: DateTime(2026, 3, 31),
        progress: 0,
      );
      await tester.pumpWidget(buildApp(book: book));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('未読'), findsOneWidget);
    });

    testWidgets('進捗50%で読書中と表示される', (tester) async {
      final book = Book(
        id: 'book-2',
        title: 'テスト本2',
        startDate: DateTime(2026, 3, 1),
        endDate: DateTime(2026, 3, 31),
        progress: 50,
      );
      await tester.pumpWidget(buildApp(book: book));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('読書中'), findsOneWidget);
    });

    testWidgets('進捗100%で読了と表示される', (tester) async {
      final book = Book(
        id: 'book-3',
        title: 'テスト本3',
        startDate: DateTime(2026, 3, 1),
        endDate: DateTime(2026, 3, 31),
        progress: 100,
      );
      await tester.pumpWidget(buildApp(book: book));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('読了'), findsOneWidget);
    });
  });

  testWidgets('キャンセルでダイアログが閉じる', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('読書スケジュールを追加'), findsOneWidget);

    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();

    expect(find.text('読書スケジュールを追加'), findsNothing);
  });
}
