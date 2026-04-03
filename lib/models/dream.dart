/// 夢のデータモデル.
library;

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../l10n/app_labels.dart';

/// 夢のカテゴリ.
enum DreamCategory {
  /// キャリア・仕事.
  career('career', AppLabels.catCareer, Icons.work_outline, Color(0xFF4FC3F7)),

  /// 学び・資格.
  learning('learning', AppLabels.catLearning, Icons.school_outlined, Color(0xFF81C784)),

  /// 健康・運動.
  health('health', AppLabels.catHealth, Icons.favorite_outline, Color(0xFFE57373)),

  /// お金・資産.
  finance('finance', AppLabels.catFinance, Icons.savings_outlined, Color(0xFFFFD54F)),

  /// 趣味・創作.
  hobby('hobby', AppLabels.catHobby, Icons.palette_outlined, Color(0xFFBA68C8)),

  /// 人間関係.
  relationship('relationship', AppLabels.catRelationship, Icons.people_outline, Color(0xFFFF8A65)),

  /// 旅行・体験.
  travel('travel', AppLabels.catTravel, Icons.flight_outlined, Color(0xFF4DD0E1)),

  /// その他.
  other('other', AppLabels.catOther, Icons.auto_awesome, Color(0xFF90A4AE));

  const DreamCategory(this.value, this.label, this.icon, this.color);

  /// DB保存用の値.
  final String value;

  /// 表示用ラベル.
  final String label;

  /// アイコン.
  final IconData icon;

  /// テーマカラー.
  final Color color;

  /// 文字列からDreamCategoryを取得する.
  static DreamCategory fromValue(String value) {
    return DreamCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DreamCategory.other,
    );
  }
}

/// 夢モデル.
class Dream {
  /// 夢を作成する.
  Dream({
    required this.title,
    String? id,
    String? description,
    String? why,
    String? category,
    this.sortOrder = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        description = description ?? '',
        why = why ?? '',
        category = category ?? DreamCategory.other.value,
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

  /// カテゴリ.
  final String category;

  /// カテゴリのenum.
  DreamCategory get dreamCategory => DreamCategory.fromValue(category);

  /// 作成日時.
  final DateTime createdAt;

  /// 更新日時.
  final DateTime updatedAt;

  /// 並び順.
  final int sortOrder;

  /// フィールドを変更したコピーを返す.
  Dream copyWith({
    String? id,
    String? title,
    String? description,
    String? why,
    String? category,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Dream(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      why: why ?? this.why,
      category: category ?? this.category,
      sortOrder: sortOrder ?? this.sortOrder,
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
      'category': category,
      'sort_order': sortOrder,
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
      category: data['category'] as String? ?? 'other',
      sortOrder: (data['sort_order'] as int?) ?? 0,
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
