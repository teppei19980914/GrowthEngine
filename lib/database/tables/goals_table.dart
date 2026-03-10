/// 目標テーブル定義.
library;

import 'package:drift/drift.dart';

/// 目標テーブル.
class Goals extends Table {
  /// 一意識別子.
  TextColumn get id => text()();

  /// 紐づく夢のID.
  TextColumn get dreamId => text().withDefault(const Constant(''))();

  /// なぜその夢を目指すのか（動機・理由）※Dream側に移動済み.
  TextColumn get why => text()();

  /// いつまでに（目標日付または期間の説明）.
  TextColumn get whenTarget => text()();

  /// When指定タイプ（date or period）.
  TextColumn get whenType => text()();

  /// 何を目標とするか.
  TextColumn get what => text()();

  /// どうやって達成するか.
  TextColumn get how => text()();

  /// 表示色（ガントチャート用）.
  TextColumn get color => text().withDefault(const Constant('#4A9EFF'))();

  /// 作成日時.
  DateTimeColumn get createdAt => dateTime()();

  /// 更新日時.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
