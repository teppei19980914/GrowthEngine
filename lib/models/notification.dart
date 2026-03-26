/// 通知のデータモデル.
library;

import 'package:uuid/uuid.dart';

/// 通知の種類.
enum NotificationType {
  /// システム通知（運営からのお知らせ）.
  system('system'),

  /// 実績達成通知.
  achievement('achievement'),

  /// 期限リマインド通知.
  reminder('reminder');

  const NotificationType(this.value);

  /// JSON保存用の値.
  final String value;

  /// 文字列値からNotificationTypeを生成する.
  static NotificationType fromValue(String value) {
    return NotificationType.values.firstWhere(
      (e) => e.value == value,
      orElse: () =>
          throw ArgumentError('Invalid NotificationType value: $value'),
    );
  }
}

/// 通知モデル.
class Notification {
  /// 通知を作成する.
  Notification({
    required this.notificationType,
    required this.title,
    required this.message,
    String? id,
    this.isRead = false,
    DateTime? createdAt,
    this.dedupKey = '',
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  /// 一意識別子.
  final String id;

  /// 通知種別.
  final NotificationType notificationType;

  /// 通知タイトル.
  final String title;

  /// 通知メッセージ.
  final String message;

  /// 既読フラグ.
  final bool isRead;

  /// 作成日時.
  final DateTime createdAt;

  /// 重複防止キー（実績通知: "total_hours:100" など）.
  final String dedupKey;

  /// フィールドを変更したコピーを返す.
  Notification copyWith({
    String? id,
    NotificationType? notificationType,
    String? title,
    String? message,
    bool? isRead,
    DateTime? createdAt,
    String? dedupKey,
  }) {
    return Notification(
      id: id ?? this.id,
      notificationType: notificationType ?? this.notificationType,
      title: title ?? this.title,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      dedupKey: dedupKey ?? this.dedupKey,
    );
  }

  /// Mapに変換する（JSON保存用）.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'notification_type': notificationType.value,
      'title': title,
      'message': message,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'dedup_key': dedupKey,
    };
  }

  /// MapからNotificationを生成する.
  factory Notification.fromMap(Map<String, dynamic> data) {
    return Notification(
      id: data['id'] as String,
      notificationType:
          NotificationType.fromValue(data['notification_type'] as String),
      title: data['title'] as String,
      message: data['message'] as String,
      isRead: (data['is_read'] as bool?) ?? false,
      createdAt: DateTime.parse(data['created_at'] as String),
      dedupKey: (data['dedup_key'] as String?) ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Notification && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Notification(id: $id, title: $title)';
}
