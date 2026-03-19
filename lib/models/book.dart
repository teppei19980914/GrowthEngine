/// 書籍のデータモデル.
library;

import 'package:uuid/uuid.dart';

/// 書籍カテゴリ.
enum BookCategory {
  /// IT・技術.
  it('IT・技術'),

  /// ビジネス.
  business('ビジネス'),

  /// 小説・文学.
  novel('小説・文学'),

  /// 自己啓発.
  selfHelp('自己啓発'),

  /// 学術・教育.
  academic('学術・教育'),

  /// 趣味・実用.
  hobby('趣味・実用'),

  /// その他.
  other('その他');

  const BookCategory(this.label);

  /// 表示ラベル.
  final String label;

  /// 文字列値からBookCategoryを生成する.
  static BookCategory fromValue(String value) {
    return BookCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BookCategory.other,
    );
  }
}

/// 書籍のステータス.
enum BookStatus {
  /// 未読.
  unread('unread'),

  /// 読書中.
  reading('reading'),

  /// 読了.
  completed('completed');

  const BookStatus(this.value);

  /// JSON保存用の値.
  final String value;

  /// 文字列値からBookStatusを生成する.
  static BookStatus fromValue(String value) {
    return BookStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ArgumentError('Invalid BookStatus value: $value'),
    );
  }
}

/// 書籍モデル.
///
/// 書籍の登録・読了記録を管理する.
class Book {
  /// 書籍を作成する.
  ///
  /// [title]は空白のみは不可、[progress]は0-100の範囲、
  /// [endDate]が設定されている場合は[startDate]以降である必要がある.
  Book({
    required this.title,
    String? id,
    this.status = BookStatus.unread,
    this.category = BookCategory.other,
    this.why = '',
    this.description = '',
    this.summary = '',
    this.impressions = '',
    this.completedDate,
    this.startDate,
    this.endDate,
    this.progress = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now() {
    if (title.trim().isEmpty) {
      throw ArgumentError('書籍名は必須です');
    }
    if (progress < 0 || progress > 100) {
      throw ArgumentError('進捗率は0-100の範囲で指定してください: $progress');
    }
    if (startDate != null && endDate != null && endDate!.isBefore(startDate!)) {
      throw ArgumentError('終了日は開始日以降に設定してください');
    }
  }

  /// 一意識別子.
  final String id;

  /// 書籍名.
  final String title;

  /// ステータス.
  final BookStatus status;

  /// カテゴリ.
  final BookCategory category;

  /// なぜ読むのか.
  final String why;

  /// 内容メモ（フリーテキスト）.
  final String description;

  /// 要約（読了時に記入）.
  final String summary;

  /// 感想（読了時に記入）.
  final String impressions;

  /// 読了日.
  final DateTime? completedDate;

  /// 読書開始予定日（ガントチャート用）.
  final DateTime? startDate;

  /// 読書終了予定日（ガントチャート用）.
  final DateTime? endDate;

  /// 読書進捗率（0-100）.
  final int progress;

  /// 作成日時.
  final DateTime createdAt;

  /// 更新日時.
  final DateTime updatedAt;

  /// スケジュールが設定されているかどうか.
  ///
  /// startDateとendDateが両方設定されている場合true.
  bool get hasSchedule => startDate != null && endDate != null;

  /// フィールドを変更したコピーを返す.
  Book copyWith({
    String? id,
    String? title,
    BookStatus? status,
    BookCategory? category,
    String? why,
    String? description,
    String? summary,
    String? impressions,
    DateTime? completedDate,
    bool clearCompletedDate = false,
    DateTime? startDate,
    bool clearStartDate = false,
    DateTime? endDate,
    bool clearEndDate = false,
    int? progress,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      status: status ?? this.status,
      category: category ?? this.category,
      why: why ?? this.why,
      description: description ?? this.description,
      summary: summary ?? this.summary,
      impressions: impressions ?? this.impressions,
      completedDate:
          clearCompletedDate ? null : (completedDate ?? this.completedDate),
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      progress: progress ?? this.progress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Mapに変換する（JSON保存用）.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'status': status.value,
      'category': category.name,
      'why': why,
      'description': description,
      'summary': summary,
      'impressions': impressions,
      'completed_date': completedDate?.toIso8601String(),
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'progress': progress,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// MapからBookを生成する.
  factory Book.fromMap(Map<String, dynamic> data) {
    final completedDateStr = data['completed_date'] as String?;
    final startDateStr = data['start_date'] as String?;
    final endDateStr = data['end_date'] as String?;
    return Book(
      id: data['id'] as String,
      title: data['title'] as String,
      status: BookStatus.fromValue(data['status'] as String),
      category: data['category'] != null
          ? BookCategory.fromValue(data['category'] as String)
          : BookCategory.other,
      why: (data['why'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      summary: (data['summary'] as String?) ?? '',
      impressions: (data['impressions'] as String?) ?? '',
      completedDate:
          completedDateStr != null ? DateTime.parse(completedDateStr) : null,
      startDate: startDateStr != null ? DateTime.parse(startDateStr) : null,
      endDate: endDateStr != null ? DateTime.parse(endDateStr) : null,
      progress: (data['progress'] as int?) ?? 0,
      createdAt: DateTime.parse(data['created_at'] as String),
      updatedAt: DateTime.parse(data['updated_at'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Book && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Book(id: $id, title: $title)';
}
