import 'package:flutter_test/flutter_test.dart';
import 'package:yume_log/models/study_log.dart';
import 'package:yume_log/services/motivation_calculator.dart';
import 'package:yume_log/services/study_stats_types.dart';

void main() {
  List<StudyLog> makeLogs(List<(DateTime, int)> entries) {
    return entries
        .map(
          (e) => StudyLog(
            taskId: 'task-1',
            studyDate: e.$1,
            durationMinutes: e.$2,
          ),
        )
        .toList();
  }

  group('MotivationCalculator.calculateStreak', () {
    test('ログなしでストリーク0', () {
      final result = MotivationCalculator.calculateStreak(
        [],
        today: DateTime(2025, 3, 1),
      );
      expect(result.currentStreak, 0);
      expect(result.longestStreak, 0);
      expect(result.studiedToday, isFalse);
    });

    test('今日のみのストリーク1', () {
      final logs = makeLogs([(DateTime(2025, 3, 1), 30)]);
      final result = MotivationCalculator.calculateStreak(
        logs,
        today: DateTime(2025, 3, 1),
      );
      expect(result.currentStreak, 1);
      expect(result.studiedToday, isTrue);
    });

    test('連続3日のストリーク', () {
      final logs = makeLogs([
        (DateTime(2025, 2, 27), 30),
        (DateTime(2025, 2, 28), 30),
        (DateTime(2025, 3, 1), 30),
      ]);
      final result = MotivationCalculator.calculateStreak(
        logs,
        today: DateTime(2025, 3, 1),
      );
      expect(result.currentStreak, 3);
      expect(result.longestStreak, 3);
    });

    test('昨日まで連続（今日は未活動）', () {
      final logs = makeLogs([
        (DateTime(2025, 2, 27), 30),
        (DateTime(2025, 2, 28), 30),
      ]);
      final result = MotivationCalculator.calculateStreak(
        logs,
        today: DateTime(2025, 3, 1),
      );
      expect(result.currentStreak, 2);
      expect(result.studiedToday, isFalse);
    });

    test('途中に空白がある場合', () {
      final logs = makeLogs([
        (DateTime(2025, 2, 25), 30),
        (DateTime(2025, 2, 26), 30),
        // 2/27 gap
        (DateTime(2025, 2, 28), 30),
        (DateTime(2025, 3, 1), 30),
      ]);
      final result = MotivationCalculator.calculateStreak(
        logs,
        today: DateTime(2025, 3, 1),
      );
      expect(result.currentStreak, 2);
      expect(result.longestStreak, 2);
    });
  });

  group('MotivationCalculator.calculateTodayStudy', () {
    test('今日のログがない場合', () {
      final result = MotivationCalculator.calculateTodayStudy(
        [],
        today: DateTime(2025, 3, 1),
      );
      expect(result.totalMinutes, 0);
      expect(result.sessionCount, 0);
      expect(result.studied, isFalse);
    });

    test('今日の複数セッション', () {
      final logs = makeLogs([
        (DateTime(2025, 3, 1), 30),
        (DateTime(2025, 3, 1), 45),
        (DateTime(2025, 2, 28), 60),
      ]);
      final result = MotivationCalculator.calculateTodayStudy(
        logs,
        today: DateTime(2025, 3, 1),
      );
      expect(result.totalMinutes, 75);
      expect(result.sessionCount, 2);
      expect(result.studied, isTrue);
    });
  });

  group('MotivationCalculator.calculateMilestones', () {
    test('ログなしで空の実績', () {
      final result = MotivationCalculator.calculateMilestones([]);
      expect(result.achieved, isEmpty);
      expect(result.nextMilestone, isNotNull);
    });

    test('累計1時間達成', () {
      final logs = makeLogs([
        (DateTime(2025, 3, 1), 60),
      ]);
      final result = MotivationCalculator.calculateMilestones(logs);
      expect(
        result.achieved.any(
          (m) =>
              m.milestoneType == MilestoneType.totalHours && m.value == 1,
        ),
        isTrue,
      );
    });

    test('連続活動ストリーク実績', () {
      final logs = makeLogs([
        (DateTime(2025, 3, 1), 30),
      ]);
      final result = MotivationCalculator.calculateMilestones(
        logs,
        currentStreak: 7,
      );
      expect(
        result.achieved.any(
          (m) => m.milestoneType == MilestoneType.streak && m.value == 3,
        ),
        isTrue,
      );
      expect(
        result.achieved.any(
          (m) => m.milestoneType == MilestoneType.streak && m.value == 7,
        ),
        isTrue,
      );
    });

    test('活動日数の実績', () {
      final dates = List.generate(
        7,
        (i) => DateTime(2025, 3, 1 + i),
      );
      final logs = dates
          .map(
            (d) => StudyLog(
              taskId: 'task-1',
              studyDate: d,
              durationMinutes: 30,
            ),
          )
          .toList();
      final result = MotivationCalculator.calculateMilestones(logs);
      expect(
        result.achieved.any(
          (m) =>
              m.milestoneType == MilestoneType.studyDays && m.value == 3,
        ),
        isTrue,
      );
      expect(
        result.achieved.any(
          (m) =>
              m.milestoneType == MilestoneType.studyDays && m.value == 7,
        ),
        isTrue,
      );
    });

    test('achievedは最大5件', () {
      // 大量のログで多くの実績を達成
      final dates = List.generate(
        100,
        (i) => DateTime(2025, 1, 1).add(Duration(days: i)),
      );
      final logs = dates
          .map(
            (d) => StudyLog(
              taskId: 'task-1',
              studyDate: d,
              durationMinutes: 120,
            ),
          )
          .toList();
      final result = MotivationCalculator.calculateMilestones(
        logs,
        currentStreak: 100,
      );
      expect(result.achieved.length, lessThanOrEqualTo(5));
    });
  });

  group('MotivationCalculator.calculatePersonalRecords', () {
    test('ログなしではゼロデータ', () {
      final result = MotivationCalculator.calculatePersonalRecords([]);
      expect(result.bestDayMinutes, 0);
      expect(result.bestWeekMinutes, 0);
      expect(result.longestStreak, 0);
      expect(result.totalHours, 0);
      expect(result.totalStudyDays, 0);
    });

    test('1日の最高活動時間', () {
      final logs = makeLogs([
        (DateTime(2025, 3, 1), 60),
        (DateTime(2025, 3, 1), 30),
        (DateTime(2025, 3, 2), 45),
      ]);
      final result = MotivationCalculator.calculatePersonalRecords(logs);
      expect(result.bestDayMinutes, 90); // 3/1: 60+30
      expect(result.bestDayDate, DateTime(2025, 3, 1));
    });

    test('週間の最高活動時間', () {
      // 同じ週（月曜始まり）に複数日
      final logs = makeLogs([
        (DateTime(2025, 3, 3), 60), // Monday
        (DateTime(2025, 3, 4), 90), // Tuesday
        (DateTime(2025, 3, 10), 30), // Next Monday
      ]);
      final result = MotivationCalculator.calculatePersonalRecords(logs);
      expect(result.bestWeekMinutes, 150); // 3/3-3/4: 60+90
    });

    test('最長ストリーク', () {
      final logs = makeLogs([
        (DateTime(2025, 3, 1), 30),
        (DateTime(2025, 3, 2), 30),
        (DateTime(2025, 3, 3), 30),
        // gap
        (DateTime(2025, 3, 5), 30),
        (DateTime(2025, 3, 6), 30),
      ]);
      final result = MotivationCalculator.calculatePersonalRecords(logs);
      expect(result.longestStreak, 3);
    });

    test('totalHoursとtotalStudyDays', () {
      final logs = makeLogs([
        (DateTime(2025, 3, 1), 60),
        (DateTime(2025, 3, 2), 120),
        (DateTime(2025, 3, 2), 30),
      ]);
      final result = MotivationCalculator.calculatePersonalRecords(logs);
      expect(result.totalHours, 3.5); // 210 / 60.0 rounded to 1 decimal
      expect(result.totalStudyDays, 2);
    });

    test('totalHoursが小数1桁に丸められる', () {
      final logs = makeLogs([
        (DateTime(2025, 3, 1), 100), // 100 / 60 = 1.666... → 1.7
      ]);
      final result = MotivationCalculator.calculatePersonalRecords(logs);
      expect(result.totalHours, 1.7);
    });
  });

  group('MotivationCalculator.calculateConsistency', () {
    test('ログなし', () {
      final result = MotivationCalculator.calculateConsistency(
        [],
        today: DateTime(2025, 3, 5),
      );
      expect(result.thisWeekDays, 0);
      expect(result.thisMonthDays, 0);
      expect(result.overallStudyDays, 0);
      expect(result.overallTotalDays, 1);
    });

    test('今週の活動日数と時間', () {
      // 2025-03-05 is Wednesday (weekday=3)
      final logs = makeLogs([
        (DateTime(2025, 3, 3), 60),
        (DateTime(2025, 3, 4), 30),
        (DateTime(2025, 2, 28), 45), // Last week
      ]);
      final result = MotivationCalculator.calculateConsistency(
        logs,
        today: DateTime(2025, 3, 5),
      );
      expect(result.thisWeekDays, 2);
      expect(result.thisWeekTotal, 3); // Wednesday = weekday 3
      expect(result.thisWeekMinutes, 90);
    });

    test('今月の活動日数と時間', () {
      final logs = makeLogs([
        (DateTime(2025, 3, 1), 60),
        (DateTime(2025, 3, 3), 30),
        (DateTime(2025, 2, 28), 45), // Last month
      ]);
      final result = MotivationCalculator.calculateConsistency(
        logs,
        today: DateTime(2025, 3, 5),
      );
      expect(result.thisMonthDays, 2);
      expect(result.thisMonthTotal, 5); // 5th day of month
      expect(result.thisMonthMinutes, 90);
    });

    test('全体の実施率', () {
      // 10日間の期間で5日活動
      final logs = makeLogs([
        (DateTime(2025, 3, 1), 30),
        (DateTime(2025, 3, 3), 30),
        (DateTime(2025, 3, 5), 30),
        (DateTime(2025, 3, 7), 30),
        (DateTime(2025, 3, 9), 30),
      ]);
      final result = MotivationCalculator.calculateConsistency(
        logs,
        today: DateTime(2025, 3, 10),
      );
      expect(result.overallStudyDays, 5);
      expect(result.overallTotalDays, 10); // 3/1 to 3/10
      expect(result.overallRate, 0.5);
    });
  });
}
