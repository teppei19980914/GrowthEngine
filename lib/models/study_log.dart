/// 活動ログのデータモデル.
library;

import 'package:uuid/uuid.dart';

/// 活動ログモデル.
///
/// タスクごとの活動記録を表す.
class StudyLog {
  /// 活動ログを作成する.
  ///
  /// [durationMinutes]は1以上である必要がある.
  StudyLog({
    required this.taskId,
    required this.studyDate,
    required this.durationMinutes,
    String? id,
    this.memo = '',
    this.taskName = '',
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now() {
    if (durationMinutes <= 0) {
      throw ArgumentError(
        '活動時間は1分以上で指定してください: $durationMinutes',
      );
    }
  }

  /// 一意識別子.
  final String id;

  /// 紐づくTaskのID.
  final String taskId;

  /// 活動実施日.
  final DateTime studyDate;

  /// 活動時間（分単位）.
  final int durationMinutes;

  /// メモ.
  final String memo;

  /// タスク名（記録時に保存、削除後も表示用）.
  final String taskName;

  /// 作成日時.
  final DateTime createdAt;

  /// 活動時間を時間単位で返す.
  double get durationHours => durationMinutes / 60.0;

  /// フィールドを変更したコピーを返す.
  StudyLog copyWith({
    String? id,
    String? taskId,
    DateTime? studyDate,
    int? durationMinutes,
    String? memo,
    String? taskName,
    DateTime? createdAt,
  }) {
    return StudyLog(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      studyDate: studyDate ?? this.studyDate,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      memo: memo ?? this.memo,
      taskName: taskName ?? this.taskName,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Mapに変換する（JSON保存用）.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task_id': taskId,
      'task_name': taskName,
      'study_date': studyDate.toIso8601String(),
      'duration_minutes': durationMinutes,
      'memo': memo,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// MapからStudyLogを生成する.
  factory StudyLog.fromMap(Map<String, dynamic> data) {
    return StudyLog(
      id: data['id'] as String,
      taskId: data['task_id'] as String,
      studyDate: DateTime.parse(data['study_date'] as String),
      durationMinutes: data['duration_minutes'] as int,
      memo: (data['memo'] as String?) ?? '',
      taskName: (data['task_name'] as String?) ?? '',
      createdAt: DateTime.parse(data['created_at'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is StudyLog && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'StudyLog(id: $id, taskId: $taskId, minutes: $durationMinutes)';
}
