/// 活動統計に関するデータクラスと列挙型.
library;

/// アクティビティの集計期間タイプ.
enum ActivityPeriodType {
  /// 年次.
  yearly,

  /// 月次.
  monthly,

  /// 週次.
  weekly,

  /// 日次.
  daily,
}

/// 実績の種類.
enum MilestoneType {
  /// 累計活動時間.
  totalHours('total_hours'),

  /// 活動日数.
  studyDays('study_days'),

  /// 連続活動日数.
  streak('streak');

  const MilestoneType(this.value);

  /// JSON保存用の値.
  final String value;
}

/// タスク別活動統計.
class TaskStudyStats {
  /// タスク別活動統計を作成する.
  const TaskStudyStats({
    required this.taskId,
    required this.totalMinutes,
    required this.studyDays,
    required this.logCount,
  });

  /// タスクID.
  final String taskId;

  /// 合計活動時間（分）.
  final int totalMinutes;

  /// 活動日数.
  final int studyDays;

  /// ログ件数.
  final int logCount;

  /// 合計活動時間（時間）.
  double get totalHours => totalMinutes / 60.0;
}

/// 目標別活動統計.
class GoalStudyStats {
  /// 目標別活動統計を作成する.
  const GoalStudyStats({
    required this.goalId,
    required this.taskStats,
    required this.totalMinutes,
    required this.totalStudyDays,
  });

  /// 目標ID.
  final String goalId;

  /// タスク別統計のリスト.
  final List<TaskStudyStats> taskStats;

  /// 合計活動時間（分）.
  final int totalMinutes;

  /// 合計活動日数（重複排除）.
  final int totalStudyDays;

  /// 合計活動時間（時間）.
  double get totalHours => totalMinutes / 60.0;
}

/// 日別活動データ.
class DailyStudyData {
  /// 日別活動データを作成する.
  const DailyStudyData({required this.studyDate, required this.totalMinutes});

  /// 活動日.
  final DateTime studyDate;

  /// 合計活動時間（分）.
  final int totalMinutes;
}

/// 日別アクティビティデータ.
class DailyActivityData {
  /// 日別アクティビティデータを作成する.
  const DailyActivityData({
    required this.days,
    required this.maxMinutes,
    required this.periodStart,
    required this.periodEnd,
  });

  /// 日別活動データのリスト.
  final List<DailyStudyData> days;

  /// 期間内最大活動時間（分）.
  final int maxMinutes;

  /// 期間開始日.
  final DateTime periodStart;

  /// 期間終了日.
  final DateTime periodEnd;
}

/// アクティビティバケットデータ.
class ActivityBucketData {
  /// アクティビティバケットデータを作成する.
  const ActivityBucketData({
    required this.label,
    required this.totalMinutes,
    required this.periodStart,
    required this.periodEnd,
  });

  /// 表示ラベル.
  final String label;

  /// 合計活動時間（分）.
  final int totalMinutes;

  /// 期間開始日.
  final DateTime periodStart;

  /// 期間終了日.
  final DateTime periodEnd;
}

/// アクティビティチャートデータ.
class ActivityChartData {
  /// アクティビティチャートデータを作成する.
  const ActivityChartData({
    required this.periodType,
    required this.buckets,
    required this.maxMinutes,
  });

  /// 集計期間タイプ.
  final ActivityPeriodType periodType;

  /// バケットのリスト.
  final List<ActivityBucketData> buckets;

  /// バケット内最大活動時間（分）.
  final int maxMinutes;
}

/// ストリークデータ.
class StreakData {
  /// ストリークデータを作成する.
  const StreakData({
    required this.currentStreak,
    required this.longestStreak,
    required this.studiedToday,
  });

  /// 現在の連続活動日数.
  final int currentStreak;

  /// 最長連続活動日数.
  final int longestStreak;

  /// 今日活動したかどうか.
  final bool studiedToday;
}

/// 今日の活動データ.
class TodayStudyData {
  /// 今日の活動データを作成する.
  const TodayStudyData({
    required this.totalMinutes,
    required this.sessionCount,
    required this.studied,
  });

  /// 合計活動時間（分）.
  final int totalMinutes;

  /// セッション数.
  final int sessionCount;

  /// 活動したかどうか.
  final bool studied;
}

/// 実績データ.
class Milestone {
  /// 実績データを作成する.
  const Milestone({
    required this.milestoneType,
    required this.value,
    required this.label,
  });

  /// 実績種別.
  final MilestoneType milestoneType;

  /// 実績値.
  final int value;

  /// 表示ラベル.
  final String label;
}

/// 実績サマリーデータ.
class MilestoneData {
  /// 実績サマリーデータを作成する.
  const MilestoneData({
    required this.totalHours,
    required this.studyDays,
    required this.currentStreak,
    required this.achieved,
    this.nextMilestone,
  });

  /// 累計活動時間.
  final double totalHours;

  /// 活動日数.
  final int studyDays;

  /// 現在の連続活動日数.
  final int currentStreak;

  /// 達成した実績のリスト.
  final List<Milestone> achieved;

  /// 次の実績.
  final Milestone? nextMilestone;
}

/// 自己ベストデータ.
class PersonalRecordData {
  /// 自己ベストデータを作成する.
  const PersonalRecordData({
    required this.bestDayMinutes,
    this.bestDayDate,
    required this.bestWeekMinutes,
    this.bestWeekStart,
    required this.longestStreak,
    required this.totalHours,
    required this.totalStudyDays,
  });

  /// 1日最高活動時間（分）.
  final int bestDayMinutes;

  /// 1日最高の日付.
  final DateTime? bestDayDate;

  /// 1週間最高活動時間（分）.
  final int bestWeekMinutes;

  /// 1週間最高の開始日.
  final DateTime? bestWeekStart;

  /// 最長連続活動日数.
  final int longestStreak;

  /// 累計活動時間（時間）.
  final double totalHours;

  /// 累計活動日数.
  final int totalStudyDays;
}

/// 活動の実施率データ.
class ConsistencyData {
  /// 活動の実施率データを作成する.
  const ConsistencyData({
    required this.thisWeekDays,
    required this.thisWeekTotal,
    required this.thisWeekMinutes,
    required this.thisMonthDays,
    required this.thisMonthTotal,
    required this.thisMonthMinutes,
    required this.overallRate,
    required this.overallStudyDays,
    required this.overallTotalDays,
  });

  /// 今週の活動日数.
  final int thisWeekDays;

  /// 今週の経過曜日数 (1-7).
  final int thisWeekTotal;

  /// 今週の合計活動時間（分）.
  final int thisWeekMinutes;

  /// 今月の活動日数.
  final int thisMonthDays;

  /// 今月の経過日数 (1-31).
  final int thisMonthTotal;

  /// 今月の合計活動時間（分）.
  final int thisMonthMinutes;

  /// 全体の実施率.
  final double overallRate;

  /// 全体の活動日数.
  final int overallStudyDays;

  /// 全体の対象日数.
  final int overallTotalDays;
}

/// 本棚データ.
class BookshelfData {
  /// 本棚データを作成する.
  const BookshelfData({
    required this.totalCount,
    required this.completedCount,
    required this.readingCount,
    required this.recentCompleted,
  });

  /// 全書籍数.
  final int totalCount;

  /// 読了数.
  final int completedCount;

  /// 読書中数.
  final int readingCount;

  /// 最近読了した書籍（最大5件）.
  final List<dynamic> recentCompleted;
}

/// ダッシュボードウィジェット設定.
class DashboardWidgetConfig {
  /// ダッシュボードウィジェット設定を作成する.
  const DashboardWidgetConfig({
    required this.widgetType,
    required this.columnSpan,
  });

  /// ウィジェット種別.
  final String widgetType;

  /// カラムスパン.
  final int columnSpan;

  /// Mapに変換する.
  Map<String, dynamic> toMap() {
    return {'widget_type': widgetType, 'column_span': columnSpan};
  }

  /// Mapから生成する.
  factory DashboardWidgetConfig.fromMap(Map<String, dynamic> data) {
    return DashboardWidgetConfig(
      widgetType: data['widget_type'] as String,
      columnSpan: data['column_span'] as int,
    );
  }
}

/// ウィジェットメタデータ.
class WidgetMetadata {
  /// ウィジェットメタデータを作成する.
  const WidgetMetadata({
    required this.widgetType,
    required this.displayName,
    required this.icon,
    required this.defaultSpan,
    required this.allowedSpans,
  });

  /// ウィジェット種別.
  final String widgetType;

  /// 表示名.
  final String displayName;

  /// アイコン.
  final String icon;

  /// デフォルトスパン.
  final int defaultSpan;

  /// 許可されたスパンのリスト.
  final List<int> allowedSpans;
}

/// ガントチャートタイムライン範囲.
class TimelineRange {
  /// タイムライン範囲を作成する.
  const TimelineRange({required this.startDate, required this.endDate});

  /// 開始日.
  final DateTime startDate;

  /// 終了日.
  final DateTime endDate;

  /// 日数.
  int get totalDays => endDate.difference(startDate).inDays + 1;
}

/// ガントチャートバーの座標.
class BarGeometry {
  /// バーの座標を作成する.
  const BarGeometry({
    required this.x,
    required this.width,
    required this.progressWidth,
  });

  /// X座標.
  final double x;

  /// 幅.
  final double width;

  /// 進捗幅.
  final double progressWidth;
}
