/// 目標のデータモデル.
library;

import 'package:uuid/uuid.dart';

/// When（いつまでに）の指定タイプ.
enum WhenType {
  /// 日付指定.
  date('date'),

  /// 期間指定.
  period('period');

  const WhenType(this.value);

  /// JSON保存用の値.
  final String value;

  /// 文字列値からWhenTypeを生成する.
  static WhenType fromValue(String value) {
    return WhenType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ArgumentError('Invalid WhenType value: $value'),
    );
  }
}

/// 目標に割り当てるデフォルトカラーパレット.
const List<String> goalColors = [
  '#4A9EFF', // Blue
  '#FF6B6B', // Red
  '#51CF66', // Green
  '#FFD43B', // Yellow
  '#CC5DE8', // Purple
  '#FF922B', // Orange
  '#20C997', // Teal
  '#F06595', // Pink
];

/// 目標モデル.
class Goal {
  /// 目標を作成する.
  Goal({
    required this.dreamId,
    required this.whenTarget,
    required this.whenType,
    required this.what,
    required this.how,
    String? id,
    String? why,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? color,
    this.sortOrder = 0,
  })  : id = id ?? const Uuid().v4(),
        why = why ?? '',
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        color = color ?? goalColors[0];

  /// 一意識別子.
  final String id;

  /// 紐づく夢のID.
  final String dreamId;

  /// レガシーフィールド（夢に移動済み）.
  final String why;

  /// いつまでに（目標日付または期間の説明）.
  final String whenTarget;

  /// When指定タイプ（date or period）.
  final WhenType whenType;

  /// 何を目標とするか.
  final String what;

  /// どうやって達成するか.
  final String how;

  /// 作成日時.
  final DateTime createdAt;

  /// 更新日時.
  final DateTime updatedAt;

  /// 表示色（ガントチャート用）.
  final String color;

  /// 表示順序（夢内での並び順、小さい方が先）.
  final int sortOrder;

  /// when_typeがDATEの場合、目標日をDateTime型で返す.
  ///
  /// DATEタイプでない、またはパース不可の場合はnullを返す.
  DateTime? getTargetDate() {
    if (whenType != WhenType.date) return null;
    return DateTime.tryParse(whenTarget);
  }

  /// フィールドを変更したコピーを返す.
  Goal copyWith({
    String? id,
    String? dreamId,
    String? why,
    String? whenTarget,
    WhenType? whenType,
    String? what,
    String? how,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? color,
    int? sortOrder,
  }) {
    return Goal(
      id: id ?? this.id,
      dreamId: dreamId ?? this.dreamId,
      why: why ?? this.why,
      whenTarget: whenTarget ?? this.whenTarget,
      whenType: whenType ?? this.whenType,
      what: what ?? this.what,
      how: how ?? this.how,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      color: color ?? this.color,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  /// Mapに変換する（JSON保存用）.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dream_id': dreamId,
      'why': why,
      'when_target': whenTarget,
      'when_type': whenType.value,
      'what': what,
      'how': how,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'color': color,
      'sort_order': sortOrder,
    };
  }

  /// MapからGoalを生成する.
  factory Goal.fromMap(Map<String, dynamic> data) {
    return Goal(
      id: data['id'] as String,
      dreamId: data['dream_id'] as String,
      why: data['why'] as String? ?? '',
      whenTarget: data['when_target'] as String,
      whenType: WhenType.fromValue(data['when_type'] as String),
      what: data['what'] as String,
      how: data['how'] as String,
      createdAt: DateTime.parse(data['created_at'] as String),
      updatedAt: DateTime.parse(data['updated_at'] as String),
      color: (data['color'] as String?) ?? goalColors[0],
      sortOrder: (data['sort_order'] as int?) ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Goal && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Goal(id: $id, what: $what)';
}
