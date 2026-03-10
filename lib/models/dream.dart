/// 夢のデータモデル.
library;

import 'package:uuid/uuid.dart';

/// 夢モデル.
class Dream {
  /// 夢を作成する.
  Dream({
    required this.title,
    String? id,
    String? description,
    String? why,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        description = description ?? '',
        why = why ?? '',
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// 一意識別子.
  final String id;

  /// 夢のタイトル.
  final String title;

  /// 夢の説明.
  final String description;

  /// なぜこの夢を叶えたいか（動機・理由）.
  final String why;

  /// 作成日時.
  final DateTime createdAt;

  /// 更新日時.
  final DateTime updatedAt;

  /// フィールドを変更したコピーを返す.
  Dream copyWith({
    String? id,
    String? title,
    String? description,
    String? why,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Dream(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      why: why ?? this.why,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Mapに変換する（JSON保存用）.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'why': why,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// MapからDreamを生成する.
  factory Dream.fromMap(Map<String, dynamic> data) {
    return Dream(
      id: data['id'] as String,
      title: data['title'] as String,
      description: data['description'] as String? ?? '',
      why: data['why'] as String? ?? '',
      createdAt: DateTime.parse(data['created_at'] as String),
      updatedAt: DateTime.parse(data['updated_at'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Dream && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Dream(id: $id, title: $title)';
}
