/// モチベーション関連の統計計算ロジック.
library;

import 'dart:math';

import '../models/study_log.dart';
import 'study_stats_types.dart';

/// 実績の閾値.
const _totalHoursThresholds = [1, 5, 10, 25, 50, 100, 250, 500, 1000];
const _studyDaysThresholds = [3, 7, 14, 30, 60, 100, 200, 365];
const _streakThresholds = [3, 7, 14, 30, 60, 100];

/// モチベーション関連の統計を計算するクラス.
class MotivationCalculator {
  /// ストリーク（連続活動日数）を計算する.
  static StreakData calculateStreak(
    List<StudyLog> logs, {
    DateTime? today,
  }) {
    final now = today ?? DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final studyDates = <DateTime>{};
    for (final log in logs) {
      studyDates.add(
        DateTime(
          log.studyDate.year,
          log.studyDate.month,
          log.studyDate.day,
        ),
      );
    }

    final studiedToday = studyDates.contains(todayDate);
    var currentStreak = 0;

    var checkDate = studiedToday
        ? todayDate
        : todayDate.subtract(const Duration(days: 1));

    while (studyDates.contains(checkDate)) {
      currentStreak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    final longestStreak = _calculateLongestStreak(studyDates);

    return StreakData(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      studiedToday: studiedToday,
    );
  }

  /// 今日の活動データを計算する.
  static TodayStudyData calculateTodayStudy(
    List<StudyLog> logs, {
    DateTime? today,
  }) {
    final now = today ?? DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);

    var totalMinutes = 0;
    var sessionCount = 0;
    for (final log in logs) {
      final logDate = DateTime(
        log.studyDate.year,
        log.studyDate.month,
        log.studyDate.day,
      );
      if (logDate == todayDate) {
        totalMinutes += log.durationMinutes;
        sessionCount++;
      }
    }

    return TodayStudyData(
      totalMinutes: totalMinutes,
      sessionCount: sessionCount,
      studied: sessionCount > 0,
    );
  }

  /// 実績データを計算する.
  static MilestoneData calculateMilestones(
    List<StudyLog> logs, {
    int currentStreak = 0,
  }) {
    final totalMinutes = logs.fold<int>(0, (sum, l) => sum + l.durationMinutes);
    final totalHours =
        double.parse((totalMinutes / 60.0).toStringAsFixed(1));
    final studyDates = <DateTime>{};
    for (final log in logs) {
      studyDates.add(
        DateTime(
          log.studyDate.year,
          log.studyDate.month,
          log.studyDate.day,
        ),
      );
    }
    final studyDays = studyDates.length;

    final achieved = <Milestone>[];
    Milestone? nextMilestone;

    final checks = [
      (MilestoneType.totalHours, totalHours.floor(), _totalHoursThresholds),
      (MilestoneType.studyDays, studyDays, _studyDaysThresholds),
      (MilestoneType.streak, currentStreak, _streakThresholds),
    ];

    for (final (type, value, thresholds) in checks) {
      for (final threshold in thresholds) {
        if (value >= threshold) {
          achieved.add(
            Milestone(
              milestoneType: type,
              value: threshold,
              label: _milestoneLabel(type, threshold),
            ),
          );
        } else {
          nextMilestone ??= Milestone(
            milestoneType: type,
            value: threshold,
            label: _milestoneLabel(type, threshold),
          );
        }
      }
    }

    achieved.sort((a, b) => b.value.compareTo(a.value));
    final topAchieved = achieved.take(5).toList();

    return MilestoneData(
      totalHours: totalHours,
      studyDays: studyDays,
      currentStreak: currentStreak,
      achieved: topAchieved,
      nextMilestone: nextMilestone,
    );
  }

  /// 自己ベストを計算する.
  static PersonalRecordData calculatePersonalRecords(
    List<StudyLog> logs, {
    DateTime? today,
  }) {
    if (logs.isEmpty) {
      return const PersonalRecordData(
        bestDayMinutes: 0,
        bestWeekMinutes: 0,
        longestStreak: 0,
        totalHours: 0,
        totalStudyDays: 0,
      );
    }

    final dailyTotals = <DateTime, int>{};
    final weeklyTotals = <String, (int, DateTime)>{};
    final studyDates = <DateTime>{};
    var totalMinutes = 0;

    for (final log in logs) {
      final day = DateTime(
        log.studyDate.year,
        log.studyDate.month,
        log.studyDate.day,
      );
      dailyTotals[day] = (dailyTotals[day] ?? 0) + log.durationMinutes;
      studyDates.add(day);
      totalMinutes += log.durationMinutes;

      // ISO week (Monday-start)
      final monday = day.subtract(Duration(days: day.weekday - 1));
      final weekKey = '${monday.year}-${monday.month}-${monday.day}';
      final existing = weeklyTotals[weekKey];
      weeklyTotals[weekKey] = (
        (existing?.$1 ?? 0) + log.durationMinutes,
        monday,
      );
    }

    var bestDayMinutes = 0;
    DateTime? bestDayDate;
    for (final entry in dailyTotals.entries) {
      if (entry.value > bestDayMinutes) {
        bestDayMinutes = entry.value;
        bestDayDate = entry.key;
      }
    }

    var bestWeekMinutes = 0;
    DateTime? bestWeekStart;
    for (final entry in weeklyTotals.entries) {
      if (entry.value.$1 > bestWeekMinutes) {
        bestWeekMinutes = entry.value.$1;
        bestWeekStart = entry.value.$2;
      }
    }

    final longestStreak = _calculateLongestStreak(studyDates);

    return PersonalRecordData(
      bestDayMinutes: bestDayMinutes,
      bestDayDate: bestDayDate,
      bestWeekMinutes: bestWeekMinutes,
      bestWeekStart: bestWeekStart,
      longestStreak: longestStreak,
      totalHours: double.parse((totalMinutes / 60.0).toStringAsFixed(1)),
      totalStudyDays: studyDates.length,
    );
  }

  /// 活動の実施率を計算する.
  static ConsistencyData calculateConsistency(
    List<StudyLog> logs, {
    DateTime? today,
  }) {
    final now = today ?? DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final monday = todayDate.subtract(Duration(days: todayDate.weekday - 1));
    final monthStart = DateTime(todayDate.year, todayDate.month);

    final weekDates = <DateTime>{};
    final monthDates = <DateTime>{};
    var thisWeekMinutes = 0;
    var thisMonthMinutes = 0;

    for (final log in logs) {
      final day = DateTime(
        log.studyDate.year,
        log.studyDate.month,
        log.studyDate.day,
      );
      if (!day.isBefore(monday) && !day.isAfter(todayDate)) {
        weekDates.add(day);
        thisWeekMinutes += log.durationMinutes;
      }
      if (!day.isBefore(monthStart) && !day.isAfter(todayDate)) {
        monthDates.add(day);
        thisMonthMinutes += log.durationMinutes;
      }
    }
    final thisWeekDays = weekDates.length;
    final thisWeekTotal = todayDate.weekday; // 1(月)-7(日)
    final thisMonthDays = monthDates.length;
    final thisMonthTotal = todayDate.day; // 1-31

    final studyDates = <DateTime>{};
    for (final log in logs) {
      studyDates.add(
        DateTime(
          log.studyDate.year,
          log.studyDate.month,
          log.studyDate.day,
        ),
      );
    }
    final overallStudyDays = studyDates.length;

    int overallTotalDays;
    if (studyDates.isEmpty) {
      overallTotalDays = 1;
    } else {
      final sortedDates = studyDates.toList()..sort();
      overallTotalDays =
          todayDate.difference(sortedDates.first).inDays + 1;
      overallTotalDays = max(overallTotalDays, 1);
    }

    final overallRate =
        double.parse(
          (overallStudyDays / overallTotalDays).toStringAsFixed(3),
        );

    return ConsistencyData(
      thisWeekDays: thisWeekDays,
      thisWeekTotal: thisWeekTotal,
      thisWeekMinutes: thisWeekMinutes,
      thisMonthDays: thisMonthDays,
      thisMonthTotal: thisMonthTotal,
      thisMonthMinutes: thisMonthMinutes,
      overallRate: overallRate,
      overallStudyDays: overallStudyDays,
      overallTotalDays: overallTotalDays,
    );
  }

  static int _calculateLongestStreak(Set<DateTime> studyDates) {
    if (studyDates.isEmpty) return 0;
    final sorted = studyDates.toList()..sort();
    var longest = 1;
    var current = 1;
    for (var i = 1; i < sorted.length; i++) {
      if (sorted[i].difference(sorted[i - 1]).inDays == 1) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 1;
      }
    }
    return longest;
  }

  static String _milestoneLabel(MilestoneType type, int value) {
    switch (type) {
      case MilestoneType.totalHours:
        return '累計$value時間';
      case MilestoneType.studyDays:
        return '$value日活動';
      case MilestoneType.streak:
        return '$value日連続';
    }
  }
}
