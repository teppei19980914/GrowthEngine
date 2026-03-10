/// 活動統計の計算ロジック.
library;

import '../models/study_log.dart';
import 'study_stats_types.dart';

/// 活動統計を計算するクラス.
class StudyStatsCalculator {
  /// 日別アクティビティを計算する.
  static DailyActivityData calculateDailyActivity(
    List<StudyLog> logs, {
    int periodDays = 30,
    DateTime? endDate,
  }) {
    final end = endDate ?? DateTime.now();
    final endDay = DateTime(end.year, end.month, end.day);
    final startDay = endDay.subtract(Duration(days: periodDays - 1));

    final dailyMap = <DateTime, int>{};
    for (final log in logs) {
      final day = DateTime(
        log.studyDate.year,
        log.studyDate.month,
        log.studyDate.day,
      );
      if (!day.isBefore(startDay) && !day.isAfter(endDay)) {
        dailyMap[day] = (dailyMap[day] ?? 0) + log.durationMinutes;
      }
    }

    final days = <DailyStudyData>[];
    var maxMinutes = 0;
    var current = startDay;
    while (!current.isAfter(endDay)) {
      final minutes = dailyMap[current] ?? 0;
      days.add(DailyStudyData(studyDate: current, totalMinutes: minutes));
      if (minutes > maxMinutes) maxMinutes = minutes;
      current = current.add(const Duration(days: 1));
    }

    return DailyActivityData(
      days: days,
      maxMinutes: maxMinutes,
      periodStart: startDay,
      periodEnd: endDay,
    );
  }

  /// アクティビティチャートデータを計算する.
  static ActivityChartData calculateActivity(
    List<StudyLog> logs,
    ActivityPeriodType periodType, {
    DateTime? endDate,
  }) {
    switch (periodType) {
      case ActivityPeriodType.yearly:
        return _calculateYearlyActivity(logs, endDate: endDate);
      case ActivityPeriodType.monthly:
        return _calculateMonthlyActivity(logs, endDate: endDate);
      case ActivityPeriodType.weekly:
        return _calculateWeeklyActivity(logs, endDate: endDate);
      case ActivityPeriodType.daily:
        return _calculateDailyActivityBuckets(logs, endDate: endDate);
    }
  }

  static ActivityChartData _calculateYearlyActivity(
    List<StudyLog> logs, {
    DateTime? endDate,
  }) {
    final end = endDate ?? DateTime.now();
    final currentYear = end.year;

    int startYear;
    if (logs.isEmpty) {
      startYear = currentYear;
    } else {
      startYear = logs
          .map((l) => l.studyDate.year)
          .reduce((a, b) => a < b ? a : b);
    }

    final buckets = <ActivityBucketData>[];
    var maxMinutes = 0;
    for (var year = startYear; year <= currentYear; year++) {
      final yearStart = DateTime(year);
      final yearEnd = DateTime(year, 12, 31);
      final totalMinutes = _sumMinutesInRange(logs, yearStart, yearEnd);
      if (totalMinutes > maxMinutes) maxMinutes = totalMinutes;
      buckets.add(
        ActivityBucketData(
          label: '$year年',
          totalMinutes: totalMinutes,
          periodStart: yearStart,
          periodEnd: yearEnd,
        ),
      );
    }

    return ActivityChartData(
      periodType: ActivityPeriodType.yearly,
      buckets: buckets,
      maxMinutes: maxMinutes,
    );
  }

  static ActivityChartData _calculateMonthlyActivity(
    List<StudyLog> logs, {
    DateTime? endDate,
  }) {
    final end = endDate ?? DateTime.now();
    final buckets = <ActivityBucketData>[];
    var maxMinutes = 0;

    for (var i = 11; i >= 0; i--) {
      var year = end.year;
      var month = end.month - i;
      while (month <= 0) {
        month += 12;
        year--;
      }
      final monthStart = DateTime(year, month);
      final monthEnd =
          month == 12
              ? DateTime(year + 1, 1).subtract(const Duration(days: 1))
              : DateTime(year, month + 1).subtract(const Duration(days: 1));
      final totalMinutes = _sumMinutesInRange(logs, monthStart, monthEnd);
      if (totalMinutes > maxMinutes) maxMinutes = totalMinutes;
      buckets.add(
        ActivityBucketData(
          label: '$month月',
          totalMinutes: totalMinutes,
          periodStart: monthStart,
          periodEnd: monthEnd,
        ),
      );
    }

    return ActivityChartData(
      periodType: ActivityPeriodType.monthly,
      buckets: buckets,
      maxMinutes: maxMinutes,
    );
  }

  static ActivityChartData _calculateWeeklyActivity(
    List<StudyLog> logs, {
    DateTime? endDate,
  }) {
    final end = endDate ?? DateTime.now();
    final endDay = DateTime(end.year, end.month, end.day);
    final currentMonday = endDay.subtract(
      Duration(days: endDay.weekday - 1),
    );

    final buckets = <ActivityBucketData>[];
    var maxMinutes = 0;

    for (var i = 11; i >= 0; i--) {
      final weekStart = currentMonday.subtract(Duration(days: i * 7));
      final weekEnd = weekStart.add(const Duration(days: 6));
      final totalMinutes = _sumMinutesInRange(logs, weekStart, weekEnd);
      if (totalMinutes > maxMinutes) maxMinutes = totalMinutes;
      buckets.add(
        ActivityBucketData(
          label: '${weekStart.month}/${weekStart.day}~',
          totalMinutes: totalMinutes,
          periodStart: weekStart,
          periodEnd: weekEnd,
        ),
      );
    }

    return ActivityChartData(
      periodType: ActivityPeriodType.weekly,
      buckets: buckets,
      maxMinutes: maxMinutes,
    );
  }

  static ActivityChartData _calculateDailyActivityBuckets(
    List<StudyLog> logs, {
    DateTime? endDate,
  }) {
    final end = endDate ?? DateTime.now();
    final endDay = DateTime(end.year, end.month, end.day);

    final buckets = <ActivityBucketData>[];
    var maxMinutes = 0;

    for (var i = 29; i >= 0; i--) {
      final day = endDay.subtract(Duration(days: i));
      final totalMinutes = _sumMinutesInRange(logs, day, day);
      if (totalMinutes > maxMinutes) maxMinutes = totalMinutes;
      buckets.add(
        ActivityBucketData(
          label: '${day.month}/${day.day}',
          totalMinutes: totalMinutes,
          periodStart: day,
          periodEnd: day,
        ),
      );
    }

    return ActivityChartData(
      periodType: ActivityPeriodType.daily,
      buckets: buckets,
      maxMinutes: maxMinutes,
    );
  }

  static int _sumMinutesInRange(
    List<StudyLog> logs,
    DateTime start,
    DateTime end,
  ) {
    var total = 0;
    for (final log in logs) {
      final day = DateTime(
        log.studyDate.year,
        log.studyDate.month,
        log.studyDate.day,
      );
      if (!day.isBefore(start) && !day.isAfter(end)) {
        total += log.durationMinutes;
      }
    }
    return total;
  }
}
