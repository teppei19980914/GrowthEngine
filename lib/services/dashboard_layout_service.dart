/// ダッシュボードレイアウト管理サービス.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'study_stats_types.dart';

const _prefsKeyLayout = 'dashboard_layout';

/// 利用可能なウィジェット定義.
const widgetRegistry = <String, WidgetMetadata>{
  'today_banner': WidgetMetadata(
    widgetType: 'today_banner',
    displayName: '今日の活動状況',
    icon: '\u2705',
    defaultSpan: 2,
    allowedSpans: [1, 2],
  ),
  'total_time_card': WidgetMetadata(
    widgetType: 'total_time_card',
    displayName: '合計活動時間',
    icon: '\u23F1\uFE0F',
    defaultSpan: 1,
    allowedSpans: [1, 2],
  ),
  'study_days_card': WidgetMetadata(
    widgetType: 'study_days_card',
    displayName: '活動日数',
    icon: '\uD83D\uDCC5',
    defaultSpan: 1,
    allowedSpans: [1, 2],
  ),
  'dream_count_card': WidgetMetadata(
    widgetType: 'dream_count_card',
    displayName: '夢の数',
    icon: '\u2728',
    defaultSpan: 1,
    allowedSpans: [1, 2],
  ),
  'goal_count_card': WidgetMetadata(
    widgetType: 'goal_count_card',
    displayName: '目標数',
    icon: '\uD83C\uDFAF',
    defaultSpan: 1,
    allowedSpans: [1, 2],
  ),
  'streak_card': WidgetMetadata(
    widgetType: 'streak_card',
    displayName: '連続活動',
    icon: '\uD83D\uDD25',
    defaultSpan: 1,
    allowedSpans: [1, 2],
  ),
  'bookshelf': WidgetMetadata(
    widgetType: 'bookshelf',
    displayName: '本棚',
    icon: '\uD83D\uDCDA',
    defaultSpan: 2,
    allowedSpans: [1, 2],
  ),
  'personal_record': WidgetMetadata(
    widgetType: 'personal_record',
    displayName: '自己ベスト',
    icon: '\uD83C\uDFC5',
    defaultSpan: 1,
    allowedSpans: [1, 2],
  ),
  'consistency': WidgetMetadata(
    widgetType: 'consistency',
    displayName: '活動の実施率',
    icon: '\uD83D\uDCCA',
    defaultSpan: 1,
    allowedSpans: [1, 2],
  ),
  'daily_chart': WidgetMetadata(
    widgetType: 'daily_chart',
    displayName: 'アクティビティ',
    icon: '\uD83D\uDCC8',
    defaultSpan: 2,
    allowedSpans: [1, 2],
  ),
  'constellation_preview': WidgetMetadata(
    widgetType: 'constellation_preview',
    displayName: '星座',
    icon: '\u2B50',
    defaultSpan: 1,
    allowedSpans: [1, 2],
  ),
};

/// ダッシュボードのレイアウト設定を管理するサービス.
class DashboardLayoutService {
  /// 保存済みレイアウトを取得する.
  Future<List<DashboardWidgetConfig>> getLayout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKeyLayout);
      if (raw != null) {
        final list = json.decode(raw) as List<dynamic>;
        final layout = _parseLayout(list);
        if (layout.isNotEmpty) return layout;
      }
    } on FormatException {
      // JSON parse error — fall through to default
    }
    return getDefaultLayout();
  }

  /// レイアウト設定を保存する.
  Future<void> saveLayout(List<DashboardWidgetConfig> layout) async {
    final prefs = await SharedPreferences.getInstance();
    final data = layout.map((w) => w.toMap()).toList();
    await prefs.setString(_prefsKeyLayout, json.encode(data));
  }

  /// デフォルトレイアウトを取得する.
  List<DashboardWidgetConfig> getDefaultLayout() {
    return const [
      DashboardWidgetConfig(widgetType: 'today_banner', columnSpan: 2),
      DashboardWidgetConfig(widgetType: 'total_time_card', columnSpan: 1),
      DashboardWidgetConfig(widgetType: 'study_days_card', columnSpan: 1),
      DashboardWidgetConfig(widgetType: 'streak_card', columnSpan: 1),
      DashboardWidgetConfig(widgetType: 'dream_count_card', columnSpan: 1),
      DashboardWidgetConfig(widgetType: 'goal_count_card', columnSpan: 1),
      DashboardWidgetConfig(widgetType: 'personal_record', columnSpan: 1),
      DashboardWidgetConfig(widgetType: 'consistency', columnSpan: 1),
      DashboardWidgetConfig(widgetType: 'constellation_preview', columnSpan: 1),
      DashboardWidgetConfig(widgetType: 'bookshelf', columnSpan: 2),
      DashboardWidgetConfig(widgetType: 'daily_chart', columnSpan: 2),
    ];
  }

  /// 現在のレイアウトに含まれていないウィジェットを取得する.
  List<WidgetMetadata> getAvailableWidgets(
    List<DashboardWidgetConfig> current,
  ) {
    final currentTypes = current.map((w) => w.widgetType).toSet();
    return [
      for (final meta in widgetRegistry.values)
        if (!currentTypes.contains(meta.widgetType)) meta,
    ];
  }

  /// ウィジェットの順序を変更する.
  List<DashboardWidgetConfig> reorder(
    List<DashboardWidgetConfig> layout,
    int fromIndex,
    int toIndex,
  ) {
    final result = List<DashboardWidgetConfig>.of(layout);
    if (fromIndex < 0 ||
        fromIndex >= result.length ||
        toIndex < 0 ||
        toIndex >= result.length) {
      return result;
    }
    final widget = result.removeAt(fromIndex);
    result.insert(toIndex, widget);
    return result;
  }

  /// ウィジェットを追加する.
  List<DashboardWidgetConfig> addWidget(
    List<DashboardWidgetConfig> layout,
    String widgetType,
  ) {
    final meta = widgetRegistry[widgetType];
    if (meta == null) return List.of(layout);
    if (layout.any((w) => w.widgetType == widgetType)) return List.of(layout);
    return [
      ...layout,
      DashboardWidgetConfig(
        widgetType: widgetType,
        columnSpan: meta.defaultSpan,
      ),
    ];
  }

  /// ウィジェットを削除する.
  List<DashboardWidgetConfig> removeWidget(
    List<DashboardWidgetConfig> layout,
    int index,
  ) {
    final result = List<DashboardWidgetConfig>.of(layout);
    if (index >= 0 && index < result.length) {
      result.removeAt(index);
    }
    return result;
  }

  /// ウィジェットのサイズを切り替える.
  List<DashboardWidgetConfig> resizeWidget(
    List<DashboardWidgetConfig> layout,
    int index,
  ) {
    final result = List<DashboardWidgetConfig>.of(layout);
    if (index < 0 || index >= result.length) return result;
    final widget = result[index];
    final meta = widgetRegistry[widget.widgetType];
    if (meta == null || meta.allowedSpans.length <= 1) return result;
    final currentIdx = meta.allowedSpans.indexOf(widget.columnSpan);
    final nextIdx =
        (currentIdx == -1 ? 0 : currentIdx + 1) % meta.allowedSpans.length;
    result[index] = DashboardWidgetConfig(
      widgetType: widget.widgetType,
      columnSpan: meta.allowedSpans[nextIdx],
    );
    return result;
  }

  List<DashboardWidgetConfig> _parseLayout(List<dynamic> raw) {
    final result = <DashboardWidgetConfig>[];
    for (final item in raw) {
      if (item is! Map<String, dynamic>) continue;
      final widgetType = item['widget_type'] as String?;
      var columnSpan = item['column_span'] as int? ?? 1;
      if (widgetType == null || !widgetRegistry.containsKey(widgetType)) {
        continue;
      }
      final meta = widgetRegistry[widgetType]!;
      if (!meta.allowedSpans.contains(columnSpan)) {
        columnSpan = meta.defaultSpan;
      }
      result.add(
        DashboardWidgetConfig(widgetType: widgetType, columnSpan: columnSpan),
      );
    }
    return result;
  }
}
