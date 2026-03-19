/// 書籍テーブル定義.
library;

import 'package:drift/drift.dart';

/// 書籍テーブル.
class Books extends Table {
  /// 一意識別子.
  TextColumn get id => text()();

  /// 書籍名.
  TextColumn get title => text()();

  /// ステータス（unread, reading, completed）.
  TextColumn get status => text().withDefault(const Constant('unread'))();

  /// カテゴリ.
  TextColumn get category => text().withDefault(const Constant('other'))();

  /// なぜ読むのか.
  TextColumn get why => text().withDefault(const Constant(''))();

  /// 内容メモ（フリーテキスト）.
  TextColumn get description => text().withDefault(const Constant(''))();

  /// 要約（読了時に記入）.
  TextColumn get summary => text().withDefault(const Constant(''))();

  /// 感想（読了時に記入）.
  TextColumn get impressions => text().withDefault(const Constant(''))();

  /// 読了日.
  DateTimeColumn get completedDate => dateTime().nullable()();

  /// 読書開始予定日（ガントチャート用）.
  DateTimeColumn get startDate => dateTime().nullable()();

  /// 読書終了予定日（ガントチャート用）.
  DateTimeColumn get endDate => dateTime().nullable()();

  /// 読書進捗率（0-100）.
  IntColumn get progress => integer().withDefault(const Constant(0))();

  /// 作成日時.
  DateTimeColumn get createdAt => dateTime()();

  /// 更新日時.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
