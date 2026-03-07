import 'package:flutter_test/flutter_test.dart';
import 'package:yume_log/models/study_log.dart';
import 'package:yume_log/services/study_stats_calculator.dart';
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

  group('StudyStatsCalculator.calculateDailyActivity', () {
    test('ログなしでゼロデータ', () {
      final result = StudyStatsCalculator.calculateDailyActivity(
        [],
        endDate: DateTime(2025, 3, 10),
      );
      expect(result.days.length, 30); // デフォルト30日
      expect(result.maxMinutes, 0);
      for (final day in result.days) {
        expect(day.totalMinutes, 0);
      }
    });

    test('期間内のログを集計する', () {
      final logs = makeLogs([
        (DateTime(2025, 3, 5), 60),
        (DateTime(2025, 3, 5), 30),
        (DateTime(2025, 3, 7), 45),
        (DateTime(2025, 1, 1), 100), // 期間外
      ]);
      final result = StudyStatsCalculator.calculateDailyActivity(
        logs,
        endDate: DateTime(2025, 3, 10),
      );
      // 3/5のデータを取得
      final mar5 = result.days.firstWhere(
        (d) => d.studyDate == DateTime(2025, 3, 5),
      );
      expect(mar5.totalMinutes, 90);
      expect(result.maxMinutes, 90);
    });

    test('カスタム期間で集計する', () {
      final logs = makeLogs([
        (DateTime(2025, 3, 1), 60),
      ]);
      final result = StudyStatsCalculator.calculateDailyActivity(
        logs,
        periodDays: 7,
        endDate: DateTime(2025, 3, 3),
      );
      expect(result.days.length, 7);
      expect(result.periodStart, DateTime(2025, 2, 25));
      expect(result.periodEnd, DateTime(2025, 3, 3));
    });
  });

  group('StudyStatsCalculator.calculateActivity', () {
    test('yearly - 年次集計', () {
      final logs = makeLogs([
        (DateTime(2024, 6, 1), 60),
        (DateTime(2025, 3, 1), 90),
      ]);
      final result = StudyStatsCalculator.calculateActivity(
        logs,
        ActivityPeriodType.yearly,
        endDate: DateTime(2025, 3, 1),
      );
      expect(result.periodType, ActivityPeriodType.yearly);
      expect(result.buckets.length, greaterThanOrEqualTo(2));
      final y2024 = result.buckets.firstWhere((b) => b.label == '2024年');
      final y2025 = result.buckets.firstWhere((b) => b.label == '2025年');
      expect(y2024.totalMinutes, 60);
      expect(y2025.totalMinutes, 90);
    });

    test('monthly - 月次集計（12ヶ月）', () {
      final logs = makeLogs([
        (DateTime(2025, 3, 1), 60),
        (DateTime(2025, 2, 15), 30),
      ]);
      final result = StudyStatsCalculator.calculateActivity(
        logs,
        ActivityPeriodType.monthly,
        endDate: DateTime(2025, 3, 15),
      );
      expect(result.periodType, ActivityPeriodType.monthly);
      expect(result.buckets.length, 12);
    });

    test('weekly - 週次集計（12週）', () {
      final logs = makeLogs([
        (DateTime(2025, 3, 3), 60), // Monday
      ]);
      final result = StudyStatsCalculator.calculateActivity(
        logs,
        ActivityPeriodType.weekly,
        endDate: DateTime(2025, 3, 5),
      );
      expect(result.periodType, ActivityPeriodType.weekly);
      expect(result.buckets.length, 12);
    });

    test('daily - 日次集計（30日）', () {
      final logs = makeLogs([
        (DateTime(2025, 3, 1), 60),
      ]);
      final result = StudyStatsCalculator.calculateActivity(
        logs,
        ActivityPeriodType.daily,
        endDate: DateTime(2025, 3, 10),
      );
      expect(result.periodType, ActivityPeriodType.daily);
      expect(result.buckets.length, 30);
    });

    test('ログなしの年次集計', () {
      final result = StudyStatsCalculator.calculateActivity(
        [],
        ActivityPeriodType.yearly,
        endDate: DateTime(2025, 3, 1),
      );
      expect(result.buckets.length, 1); // 現在の年のみ
      expect(result.maxMinutes, 0);
    });
  });
}
