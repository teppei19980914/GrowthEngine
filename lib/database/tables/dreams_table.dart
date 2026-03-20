/// 夢テーブル定義.
library;

import 'package:drift/drift.dart';

/// 夢テーブル.
class Dreams extends Table {
  /// 一意識別子.
  TextColumn get id => text()();

  /// 夢のタイトル.
  TextColumn get title => text()();

  /// 夢の説明.
  TextColumn get description => text().withDefault(const Constant(''))();

  /// なぜこの夢を叶えたいか（動機・理由）.
  TextColumn get why => text().withDefault(const Constant(''))();

  /// カテゴリ.
  TextColumn get category => text().withDefault(const Constant('other'))();

  /// 作成日時.
  DateTimeColumn get createdAt => dateTime()();

  /// 更新日時.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
