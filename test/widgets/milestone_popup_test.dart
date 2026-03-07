import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yume_log/services/study_stats_types.dart';
import 'package:yume_log/theme/app_theme.dart';
import 'package:yume_log/widgets/milestone/milestone_popup.dart';

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
      expect(find.text('累計学習時間'), findsOneWidget);
      expect(find.text('42.5時間'), findsOneWidget);
      expect(find.text('累計学習日数'), findsOneWidget);
      expect(find.text('30日'), findsOneWidget);
      expect(find.text('連続学習日数'), findsOneWidget);
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
            label: '30日学習達成',
          ),
        ],
      );

      await _openDialog(tester, data);

      expect(find.textContaining('累計10時間達成'), findsOneWidget);
      expect(find.textContaining('30日学習達成'), findsOneWidget);
      // 未達成メッセージは表示されない
      expect(find.text('まだ実績はありません'), findsNothing);
    });

    testWidgets('実績がないとき「まだ実績はありません」が表示される',
        (tester) async {
      final data = MilestoneData(
        totalHours: 0.5,
        studyDays: 1,
        currentStreak: 1,
        achieved: const [],
      );

      await _openDialog(tester, data);

      expect(find.text('まだ実績はありません'), findsOneWidget);
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
