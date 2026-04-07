import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yume_hashi/services/study_stats_types.dart';
import 'package:yume_hashi/theme/app_theme.dart';
import 'package:yume_hashi/widgets/milestone/milestone_popup.dart';

Widget _wrap(MilestoneData data) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => MilestonePopup(data: data),
          ),
          child: const Text('open'),
        ),
      ),
    ),
  );
}

Future<void> _openDialog(WidgetTester tester, MilestoneData data) async {
  await tester.pumpWidget(_wrap(data));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  group('MilestonePopup', () {
    testWidgets('統計情報が表示される', (tester) async {
      final data = MilestoneData(
        totalHours: 42.5,
        studyDays: 30,
        currentStreak: 7,
        achieved: const [],
      );

      await _openDialog(tester, data);

      expect(find.text('実績'), findsOneWidget);
      expect(find.text('累計活動時間'), findsOneWidget);
      expect(find.text('42.5時間'), findsOneWidget);
      expect(find.text('累計活動日数'), findsOneWidget);
      expect(find.text('30日'), findsOneWidget);
      expect(find.text('連続活動日数'), findsOneWidget);
      expect(find.text('7日'), findsOneWidget);
    });

    testWidgets('達成済み実績が表示される', (tester) async {
      final data = MilestoneData(
        totalHours: 100.0,
        studyDays: 60,
        currentStreak: 14,
        achieved: const [
          Milestone(
            milestoneType: MilestoneType.totalHours,
            value: 10,
            label: '累計10時間達成',
          ),
          Milestone(
            milestoneType: MilestoneType.studyDays,
            value: 30,
            label: '30日活動達成',
          ),
        ],
      );

      await _openDialog(tester, data);

      expect(find.textContaining('累計10時間達成'), findsOneWidget);
      expect(find.textContaining('30日活動達成'), findsOneWidget);
      // 未達成メッセージは表示されない
      expect(find.text('最初の実績を目指そう'), findsNothing);
    });

    testWidgets('実績がないとき「最初の実績を目指そう」が表示される',
        (tester) async {
      final data = MilestoneData(
        totalHours: 0.5,
        studyDays: 1,
        currentStreak: 1,
        achieved: const [],
      );

      await _openDialog(tester, data);

      expect(find.text('最初の実績を目指そう'), findsOneWidget);
    });

    testWidgets('次の目標が表示される', (tester) async {
      final data = MilestoneData(
        totalHours: 8.0,
        studyDays: 5,
        currentStreak: 3,
        achieved: const [],
        nextMilestone: const Milestone(
          milestoneType: MilestoneType.totalHours,
          value: 10,
          label: '累計10時間達成',
        ),
      );

      await _openDialog(tester, data);

      expect(find.text('次の目標: 累計10時間達成'), findsOneWidget);
    });

    testWidgets('次の目標がないとき表示されない', (tester) async {
      final data = MilestoneData(
        totalHours: 100.0,
        studyDays: 60,
        currentStreak: 14,
        achieved: const [],
      );

      await _openDialog(tester, data);

      expect(find.textContaining('次の目標'), findsNothing);
    });

    testWidgets('「閉じる」ボタンでダイアログが閉じる', (tester) async {
      final data = MilestoneData(
        totalHours: 10.0,
        studyDays: 5,
        currentStreak: 2,
        achieved: const [],
      );

      await _openDialog(tester, data);

      // ダイアログが表示されていることを確認
      expect(find.text('実績'), findsOneWidget);

      await tester.tap(find.text('閉じる'));
      await tester.pumpAndSettle();

      // ダイアログが閉じたことを確認
      expect(find.text('実績'), findsNothing);
    });
  });
}
