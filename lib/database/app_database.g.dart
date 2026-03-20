// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $DreamsTable extends Dreams with TableInfo<$DreamsTable, Dream> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DreamsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _whyMeta = const VerificationMeta('why');
  @override
  late final GeneratedColumn<String> why = GeneratedColumn<String>(
      'why', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('other'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, title, description, why, category, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dreams';
  @override
  VerificationContext validateIntegrity(Insertable<Dream> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('why')) {
      context.handle(
          _whyMeta, why.isAcceptableOrUnknown(data['why']!, _whyMeta));
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Dream map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Dream(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      why: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}why'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $DreamsTable createAlias(String alias) {
    return $DreamsTable(attachedDatabase, alias);
  }
}

class Dream extends DataClass implements Insertable<Dream> {
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

  /// 作成日時.
  final DateTime createdAt;

  /// 更新日時.
  final DateTime updatedAt;
  const Dream(
      {required this.id,
      required this.title,
      required this.description,
      required this.why,
      required this.category,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['description'] = Variable<String>(description);
    map['why'] = Variable<String>(why);
    map['category'] = Variable<String>(category);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DreamsCompanion toCompanion(bool nullToAbsent) {
    return DreamsCompanion(
      id: Value(id),
      title: Value(title),
      description: Value(description),
      why: Value(why),
      category: Value(category),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Dream.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Dream(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String>(json['description']),
      why: serializer.fromJson<String>(json['why']),
      category: serializer.fromJson<String>(json['category']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String>(description),
      'why': serializer.toJson<String>(why),
      'category': serializer.toJson<String>(category),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Dream copyWith(
          {String? id,
          String? title,
          String? description,
          String? why,
          String? category,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Dream(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        why: why ?? this.why,
        category: category ?? this.category,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Dream copyWithCompanion(DreamsCompanion data) {
    return Dream(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description:
          data.description.present ? data.description.value : this.description,
      why: data.why.present ? data.why.value : this.why,
      category: data.category.present ? data.category.value : this.category,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Dream(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('why: $why, ')
          ..write('category: $category, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, title, description, why, category, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Dream &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.why == this.why &&
          other.category == this.category &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DreamsCompanion extends UpdateCompanion<Dream> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> description;
  final Value<String> why;
  final Value<String> category;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DreamsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.why = const Value.absent(),
    this.category = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DreamsCompanion.insert({
    required String id,
    required String title,
    this.description = const Value.absent(),
    this.why = const Value.absent(),
    this.category = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Dream> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? why,
    Expression<String>? category,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (why != null) 'why': why,
      if (category != null) 'category': category,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DreamsCompanion copyWith(
      {Value<String>? id,
      Value<String>? title,
      Value<String>? description,
      Value<String>? why,
      Value<String>? category,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return DreamsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      why: why ?? this.why,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (why.present) {
      map['why'] = Variable<String>(why.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DreamsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('why: $why, ')
          ..write('category: $category, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GoalsTable extends Goals with TableInfo<$GoalsTable, Goal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GoalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dreamIdMeta =
      const VerificationMeta('dreamId');
  @override
  late final GeneratedColumn<String> dreamId = GeneratedColumn<String>(
      'dream_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _whyMeta = const VerificationMeta('why');
  @override
  late final GeneratedColumn<String> why = GeneratedColumn<String>(
      'why', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _whenTargetMeta =
      const VerificationMeta('whenTarget');
  @override
  late final GeneratedColumn<String> whenTarget = GeneratedColumn<String>(
      'when_target', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _whenTypeMeta =
      const VerificationMeta('whenType');
  @override
  late final GeneratedColumn<String> whenType = GeneratedColumn<String>(
      'when_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _whatMeta = const VerificationMeta('what');
  @override
  late final GeneratedColumn<String> what = GeneratedColumn<String>(
      'what', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _howMeta = const VerificationMeta('how');
  @override
  late final GeneratedColumn<String> how = GeneratedColumn<String>(
      'how', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
      'color', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('#4A9EFF'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        dreamId,
        why,
        whenTarget,
        whenType,
        what,
        how,
        color,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'goals';
  @override
  VerificationContext validateIntegrity(Insertable<Goal> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('dream_id')) {
      context.handle(_dreamIdMeta,
          dreamId.isAcceptableOrUnknown(data['dream_id']!, _dreamIdMeta));
    }
    if (data.containsKey('why')) {
      context.handle(
          _whyMeta, why.isAcceptableOrUnknown(data['why']!, _whyMeta));
    } else if (isInserting) {
      context.missing(_whyMeta);
    }
    if (data.containsKey('when_target')) {
      context.handle(
          _whenTargetMeta,
          whenTarget.isAcceptableOrUnknown(
              data['when_target']!, _whenTargetMeta));
    } else if (isInserting) {
      context.missing(_whenTargetMeta);
    }
    if (data.containsKey('when_type')) {
      context.handle(_whenTypeMeta,
          whenType.isAcceptableOrUnknown(data['when_type']!, _whenTypeMeta));
    } else if (isInserting) {
      context.missing(_whenTypeMeta);
    }
    if (data.containsKey('what')) {
      context.handle(
          _whatMeta, what.isAcceptableOrUnknown(data['what']!, _whatMeta));
    } else if (isInserting) {
      context.missing(_whatMeta);
    }
    if (data.containsKey('how')) {
      context.handle(
          _howMeta, how.isAcceptableOrUnknown(data['how']!, _howMeta));
    } else if (isInserting) {
      context.missing(_howMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
          _colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Goal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Goal(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      dreamId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}dream_id'])!,
      why: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}why'])!,
      whenTarget: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}when_target'])!,
      whenType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}when_type'])!,
      what: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}what'])!,
      how: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}how'])!,
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $GoalsTable createAlias(String alias) {
    return $GoalsTable(attachedDatabase, alias);
  }
}

class Goal extends DataClass implements Insertable<Goal> {
  /// 一意識別子.
  final String id;

  /// 紐づく夢のID.
  final String dreamId;

  /// なぜその夢を目指すのか（動機・理由）※Dream側に移動済み.
  final String why;

  /// いつまでに（目標日付または期間の説明）.
  final String whenTarget;

  /// When指定タイプ（date or period）.
  final String whenType;

  /// 何を目標とするか.
  final String what;

  /// どうやって達成するか.
  final String how;

  /// 表示色（ガントチャート用）.
  final String color;

  /// 作成日時.
  final DateTime createdAt;

  /// 更新日時.
  final DateTime updatedAt;
  const Goal(
      {required this.id,
      required this.dreamId,
      required this.why,
      required this.whenTarget,
      required this.whenType,
      required this.what,
      required this.how,
      required this.color,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['dream_id'] = Variable<String>(dreamId);
    map['why'] = Variable<String>(why);
    map['when_target'] = Variable<String>(whenTarget);
    map['when_type'] = Variable<String>(whenType);
    map['what'] = Variable<String>(what);
    map['how'] = Variable<String>(how);
    map['color'] = Variable<String>(color);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  GoalsCompanion toCompanion(bool nullToAbsent) {
    return GoalsCompanion(
      id: Value(id),
      dreamId: Value(dreamId),
      why: Value(why),
      whenTarget: Value(whenTarget),
      whenType: Value(whenType),
      what: Value(what),
      how: Value(how),
      color: Value(color),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Goal.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Goal(
      id: serializer.fromJson<String>(json['id']),
      dreamId: serializer.fromJson<String>(json['dreamId']),
      why: serializer.fromJson<String>(json['why']),
      whenTarget: serializer.fromJson<String>(json['whenTarget']),
      whenType: serializer.fromJson<String>(json['whenType']),
      what: serializer.fromJson<String>(json['what']),
      how: serializer.fromJson<String>(json['how']),
      color: serializer.fromJson<String>(json['color']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'dreamId': serializer.toJson<String>(dreamId),
      'why': serializer.toJson<String>(why),
      'whenTarget': serializer.toJson<String>(whenTarget),
      'whenType': serializer.toJson<String>(whenType),
      'what': serializer.toJson<String>(what),
      'how': serializer.toJson<String>(how),
      'color': serializer.toJson<String>(color),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Goal copyWith(
          {String? id,
          String? dreamId,
          String? why,
          String? whenTarget,
          String? whenType,
          String? what,
          String? how,
          String? color,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Goal(
        id: id ?? this.id,
        dreamId: dreamId ?? this.dreamId,
        why: why ?? this.why,
        whenTarget: whenTarget ?? this.whenTarget,
        whenType: whenType ?? this.whenType,
        what: what ?? this.what,
        how: how ?? this.how,
        color: color ?? this.color,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Goal copyWithCompanion(GoalsCompanion data) {
    return Goal(
      id: data.id.present ? data.id.value : this.id,
      dreamId: data.dreamId.present ? data.dreamId.value : this.dreamId,
      why: data.why.present ? data.why.value : this.why,
      whenTarget:
          data.whenTarget.present ? data.whenTarget.value : this.whenTarget,
      whenType: data.whenType.present ? data.whenType.value : this.whenType,
      what: data.what.present ? data.what.value : this.what,
      how: data.how.present ? data.how.value : this.how,
      color: data.color.present ? data.color.value : this.color,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Goal(')
          ..write('id: $id, ')
          ..write('dreamId: $dreamId, ')
          ..write('why: $why, ')
          ..write('whenTarget: $whenTarget, ')
          ..write('whenType: $whenType, ')
          ..write('what: $what, ')
          ..write('how: $how, ')
          ..write('color: $color, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, dreamId, why, whenTarget, whenType, what,
      how, color, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Goal &&
          other.id == this.id &&
          other.dreamId == this.dreamId &&
          other.why == this.why &&
          other.whenTarget == this.whenTarget &&
          other.whenType == this.whenType &&
          other.what == this.what &&
          other.how == this.how &&
          other.color == this.color &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class GoalsCompanion extends UpdateCompanion<Goal> {
  final Value<String> id;
  final Value<String> dreamId;
  final Value<String> why;
  final Value<String> whenTarget;
  final Value<String> whenType;
  final Value<String> what;
  final Value<String> how;
  final Value<String> color;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const GoalsCompanion({
    this.id = const Value.absent(),
    this.dreamId = const Value.absent(),
    this.why = const Value.absent(),
    this.whenTarget = const Value.absent(),
    this.whenType = const Value.absent(),
    this.what = const Value.absent(),
    this.how = const Value.absent(),
    this.color = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GoalsCompanion.insert({
    required String id,
    this.dreamId = const Value.absent(),
    required String why,
    required String whenTarget,
    required String whenType,
    required String what,
    required String how,
    this.color = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        why = Value(why),
        whenTarget = Value(whenTarget),
        whenType = Value(whenType),
        what = Value(what),
        how = Value(how),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Goal> custom({
    Expression<String>? id,
    Expression<String>? dreamId,
    Expression<String>? why,
    Expression<String>? whenTarget,
    Expression<String>? whenType,
    Expression<String>? what,
    Expression<String>? how,
    Expression<String>? color,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dreamId != null) 'dream_id': dreamId,
      if (why != null) 'why': why,
      if (whenTarget != null) 'when_target': whenTarget,
      if (whenType != null) 'when_type': whenType,
      if (what != null) 'what': what,
      if (how != null) 'how': how,
      if (color != null) 'color': color,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GoalsCompanion copyWith(
      {Value<String>? id,
      Value<String>? dreamId,
      Value<String>? why,
      Value<String>? whenTarget,
      Value<String>? whenType,
      Value<String>? what,
      Value<String>? how,
      Value<String>? color,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return GoalsCompanion(
      id: id ?? this.id,
      dreamId: dreamId ?? this.dreamId,
      why: why ?? this.why,
      whenTarget: whenTarget ?? this.whenTarget,
      whenType: whenType ?? this.whenType,
      what: what ?? this.what,
      how: how ?? this.how,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (dreamId.present) {
      map['dream_id'] = Variable<String>(dreamId.value);
    }
    if (why.present) {
      map['why'] = Variable<String>(why.value);
    }
    if (whenTarget.present) {
      map['when_target'] = Variable<String>(whenTarget.value);
    }
    if (whenType.present) {
      map['when_type'] = Variable<String>(whenType.value);
    }
    if (what.present) {
      map['what'] = Variable<String>(what.value);
    }
    if (how.present) {
      map['how'] = Variable<String>(how.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GoalsCompanion(')
          ..write('id: $id, ')
          ..write('dreamId: $dreamId, ')
          ..write('why: $why, ')
          ..write('whenTarget: $whenTarget, ')
          ..write('whenType: $whenType, ')
          ..write('what: $what, ')
          ..write('how: $how, ')
          ..write('color: $color, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TasksTable extends Tasks with TableInfo<$TasksTable, Task> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _goalIdMeta = const VerificationMeta('goalId');
  @override
  late final GeneratedColumn<String> goalId = GeneratedColumn<String>(
      'goal_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _startDateMeta =
      const VerificationMeta('startDate');
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
      'start_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endDateMeta =
      const VerificationMeta('endDate');
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
      'end_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('not_started'));
  static const VerificationMeta _progressMeta =
      const VerificationMeta('progress');
  @override
  late final GeneratedColumn<int> progress = GeneratedColumn<int>(
      'progress', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  @override
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
      'memo', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
      'book_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _orderMeta = const VerificationMeta('order');
  @override
  late final GeneratedColumn<int> order = GeneratedColumn<int>(
      'order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        goalId,
        title,
        startDate,
        endDate,
        status,
        progress,
        memo,
        bookId,
        order,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(Insertable<Task> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('goal_id')) {
      context.handle(_goalIdMeta,
          goalId.isAcceptableOrUnknown(data['goal_id']!, _goalIdMeta));
    } else if (isInserting) {
      context.missing(_goalIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(_startDateMeta,
          startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta));
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(_endDateMeta,
          endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta));
    } else if (isInserting) {
      context.missing(_endDateMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('progress')) {
      context.handle(_progressMeta,
          progress.isAcceptableOrUnknown(data['progress']!, _progressMeta));
    }
    if (data.containsKey('memo')) {
      context.handle(
          _memoMeta, memo.isAcceptableOrUnknown(data['memo']!, _memoMeta));
    }
    if (data.containsKey('book_id')) {
      context.handle(_bookIdMeta,
          bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta));
    }
    if (data.containsKey('order')) {
      context.handle(
          _orderMeta, order.isAcceptableOrUnknown(data['order']!, _orderMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Task map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Task(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      goalId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}goal_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      startDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_date'])!,
      endDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end_date'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      progress: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}progress'])!,
      memo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}memo'])!,
      bookId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}book_id'])!,
      order: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}order'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }
}

class Task extends DataClass implements Insertable<Task> {
  /// 一意識別子.
  final String id;

  /// 紐づくGoalのID.
  final String goalId;

  /// タスク名.
  final String title;

  /// 開始日.
  final DateTime startDate;

  /// 終了日.
  final DateTime endDate;

  /// ステータス（not_started, in_progress, completed）.
  final String status;

  /// 進捗率（0-100）.
  final int progress;

  /// メモ.
  final String memo;

  /// 紐づく書籍ID.
  final String bookId;

  /// 表示順序.
  final int order;

  /// 作成日時.
  final DateTime createdAt;

  /// 更新日時.
  final DateTime updatedAt;
  const Task(
      {required this.id,
      required this.goalId,
      required this.title,
      required this.startDate,
      required this.endDate,
      required this.status,
      required this.progress,
      required this.memo,
      required this.bookId,
      required this.order,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['goal_id'] = Variable<String>(goalId);
    map['title'] = Variable<String>(title);
    map['start_date'] = Variable<DateTime>(startDate);
    map['end_date'] = Variable<DateTime>(endDate);
    map['status'] = Variable<String>(status);
    map['progress'] = Variable<int>(progress);
    map['memo'] = Variable<String>(memo);
    map['book_id'] = Variable<String>(bookId);
    map['order'] = Variable<int>(order);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      goalId: Value(goalId),
      title: Value(title),
      startDate: Value(startDate),
      endDate: Value(endDate),
      status: Value(status),
      progress: Value(progress),
      memo: Value(memo),
      bookId: Value(bookId),
      order: Value(order),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Task.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Task(
      id: serializer.fromJson<String>(json['id']),
      goalId: serializer.fromJson<String>(json['goalId']),
      title: serializer.fromJson<String>(json['title']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      endDate: serializer.fromJson<DateTime>(json['endDate']),
      status: serializer.fromJson<String>(json['status']),
      progress: serializer.fromJson<int>(json['progress']),
      memo: serializer.fromJson<String>(json['memo']),
      bookId: serializer.fromJson<String>(json['bookId']),
      order: serializer.fromJson<int>(json['order']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'goalId': serializer.toJson<String>(goalId),
      'title': serializer.toJson<String>(title),
      'startDate': serializer.toJson<DateTime>(startDate),
      'endDate': serializer.toJson<DateTime>(endDate),
      'status': serializer.toJson<String>(status),
      'progress': serializer.toJson<int>(progress),
      'memo': serializer.toJson<String>(memo),
      'bookId': serializer.toJson<String>(bookId),
      'order': serializer.toJson<int>(order),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Task copyWith(
          {String? id,
          String? goalId,
          String? title,
          DateTime? startDate,
          DateTime? endDate,
          String? status,
          int? progress,
          String? memo,
          String? bookId,
          int? order,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Task(
        id: id ?? this.id,
        goalId: goalId ?? this.goalId,
        title: title ?? this.title,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        status: status ?? this.status,
        progress: progress ?? this.progress,
        memo: memo ?? this.memo,
        bookId: bookId ?? this.bookId,
        order: order ?? this.order,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Task copyWithCompanion(TasksCompanion data) {
    return Task(
      id: data.id.present ? data.id.value : this.id,
      goalId: data.goalId.present ? data.goalId.value : this.goalId,
      title: data.title.present ? data.title.value : this.title,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      status: data.status.present ? data.status.value : this.status,
      progress: data.progress.present ? data.progress.value : this.progress,
      memo: data.memo.present ? data.memo.value : this.memo,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      order: data.order.present ? data.order.value : this.order,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Task(')
          ..write('id: $id, ')
          ..write('goalId: $goalId, ')
          ..write('title: $title, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('status: $status, ')
          ..write('progress: $progress, ')
          ..write('memo: $memo, ')
          ..write('bookId: $bookId, ')
          ..write('order: $order, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, goalId, title, startDate, endDate, status,
      progress, memo, bookId, order, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Task &&
          other.id == this.id &&
          other.goalId == this.goalId &&
          other.title == this.title &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.status == this.status &&
          other.progress == this.progress &&
          other.memo == this.memo &&
          other.bookId == this.bookId &&
          other.order == this.order &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TasksCompanion extends UpdateCompanion<Task> {
  final Value<String> id;
  final Value<String> goalId;
  final Value<String> title;
  final Value<DateTime> startDate;
  final Value<DateTime> endDate;
  final Value<String> status;
  final Value<int> progress;
  final Value<String> memo;
  final Value<String> bookId;
  final Value<int> order;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.goalId = const Value.absent(),
    this.title = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.status = const Value.absent(),
    this.progress = const Value.absent(),
    this.memo = const Value.absent(),
    this.bookId = const Value.absent(),
    this.order = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TasksCompanion.insert({
    required String id,
    required String goalId,
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    this.status = const Value.absent(),
    this.progress = const Value.absent(),
    this.memo = const Value.absent(),
    this.bookId = const Value.absent(),
    this.order = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        goalId = Value(goalId),
        title = Value(title),
        startDate = Value(startDate),
        endDate = Value(endDate),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Task> custom({
    Expression<String>? id,
    Expression<String>? goalId,
    Expression<String>? title,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
    Expression<String>? status,
    Expression<int>? progress,
    Expression<String>? memo,
    Expression<String>? bookId,
    Expression<int>? order,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (goalId != null) 'goal_id': goalId,
      if (title != null) 'title': title,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (status != null) 'status': status,
      if (progress != null) 'progress': progress,
      if (memo != null) 'memo': memo,
      if (bookId != null) 'book_id': bookId,
      if (order != null) 'order': order,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TasksCompanion copyWith(
      {Value<String>? id,
      Value<String>? goalId,
      Value<String>? title,
      Value<DateTime>? startDate,
      Value<DateTime>? endDate,
      Value<String>? status,
      Value<int>? progress,
      Value<String>? memo,
      Value<String>? bookId,
      Value<int>? order,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return TasksCompanion(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      title: title ?? this.title,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      memo: memo ?? this.memo,
      bookId: bookId ?? this.bookId,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (goalId.present) {
      map['goal_id'] = Variable<String>(goalId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (progress.present) {
      map['progress'] = Variable<int>(progress.value);
    }
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (order.present) {
      map['order'] = Variable<int>(order.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('goalId: $goalId, ')
          ..write('title: $title, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('status: $status, ')
          ..write('progress: $progress, ')
          ..write('memo: $memo, ')
          ..write('bookId: $bookId, ')
          ..write('order: $order, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BooksTable extends Books with TableInfo<$BooksTable, Book> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BooksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('unread'));
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('other'));
  static const VerificationMeta _whyMeta = const VerificationMeta('why');
  @override
  late final GeneratedColumn<String> why = GeneratedColumn<String>(
      'why', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _summaryMeta =
      const VerificationMeta('summary');
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
      'summary', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _impressionsMeta =
      const VerificationMeta('impressions');
  @override
  late final GeneratedColumn<String> impressions = GeneratedColumn<String>(
      'impressions', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _completedDateMeta =
      const VerificationMeta('completedDate');
  @override
  late final GeneratedColumn<DateTime> completedDate =
      GeneratedColumn<DateTime>('completed_date', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _startDateMeta =
      const VerificationMeta('startDate');
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
      'start_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _endDateMeta =
      const VerificationMeta('endDate');
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
      'end_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _progressMeta =
      const VerificationMeta('progress');
  @override
  late final GeneratedColumn<int> progress = GeneratedColumn<int>(
      'progress', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        status,
        category,
        why,
        description,
        summary,
        impressions,
        completedDate,
        startDate,
        endDate,
        progress,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'books';
  @override
  VerificationContext validateIntegrity(Insertable<Book> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    }
    if (data.containsKey('why')) {
      context.handle(
          _whyMeta, why.isAcceptableOrUnknown(data['why']!, _whyMeta));
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('summary')) {
      context.handle(_summaryMeta,
          summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta));
    }
    if (data.containsKey('impressions')) {
      context.handle(
          _impressionsMeta,
          impressions.isAcceptableOrUnknown(
              data['impressions']!, _impressionsMeta));
    }
    if (data.containsKey('completed_date')) {
      context.handle(
          _completedDateMeta,
          completedDate.isAcceptableOrUnknown(
              data['completed_date']!, _completedDateMeta));
    }
    if (data.containsKey('start_date')) {
      context.handle(_startDateMeta,
          startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta));
    }
    if (data.containsKey('end_date')) {
      context.handle(_endDateMeta,
          endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta));
    }
    if (data.containsKey('progress')) {
      context.handle(_progressMeta,
          progress.isAcceptableOrUnknown(data['progress']!, _progressMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Book map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Book(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      why: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}why'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      summary: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}summary'])!,
      impressions: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}impressions'])!,
      completedDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}completed_date']),
      startDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_date']),
      endDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end_date']),
      progress: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}progress'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $BooksTable createAlias(String alias) {
    return $BooksTable(attachedDatabase, alias);
  }
}

class Book extends DataClass implements Insertable<Book> {
  /// 一意識別子.
  final String id;

  /// 書籍名.
  final String title;

  /// ステータス（unread, reading, completed）.
  final String status;

  /// カテゴリ.
  final String category;

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
  const Book(
      {required this.id,
      required this.title,
      required this.status,
      required this.category,
      required this.why,
      required this.description,
      required this.summary,
      required this.impressions,
      this.completedDate,
      this.startDate,
      this.endDate,
      required this.progress,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['status'] = Variable<String>(status);
    map['category'] = Variable<String>(category);
    map['why'] = Variable<String>(why);
    map['description'] = Variable<String>(description);
    map['summary'] = Variable<String>(summary);
    map['impressions'] = Variable<String>(impressions);
    if (!nullToAbsent || completedDate != null) {
      map['completed_date'] = Variable<DateTime>(completedDate);
    }
    if (!nullToAbsent || startDate != null) {
      map['start_date'] = Variable<DateTime>(startDate);
    }
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<DateTime>(endDate);
    }
    map['progress'] = Variable<int>(progress);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BooksCompanion toCompanion(bool nullToAbsent) {
    return BooksCompanion(
      id: Value(id),
      title: Value(title),
      status: Value(status),
      category: Value(category),
      why: Value(why),
      description: Value(description),
      summary: Value(summary),
      impressions: Value(impressions),
      completedDate: completedDate == null && nullToAbsent
          ? const Value.absent()
          : Value(completedDate),
      startDate: startDate == null && nullToAbsent
          ? const Value.absent()
          : Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      progress: Value(progress),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Book.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Book(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      status: serializer.fromJson<String>(json['status']),
      category: serializer.fromJson<String>(json['category']),
      why: serializer.fromJson<String>(json['why']),
      description: serializer.fromJson<String>(json['description']),
      summary: serializer.fromJson<String>(json['summary']),
      impressions: serializer.fromJson<String>(json['impressions']),
      completedDate: serializer.fromJson<DateTime?>(json['completedDate']),
      startDate: serializer.fromJson<DateTime?>(json['startDate']),
      endDate: serializer.fromJson<DateTime?>(json['endDate']),
      progress: serializer.fromJson<int>(json['progress']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'status': serializer.toJson<String>(status),
      'category': serializer.toJson<String>(category),
      'why': serializer.toJson<String>(why),
      'description': serializer.toJson<String>(description),
      'summary': serializer.toJson<String>(summary),
      'impressions': serializer.toJson<String>(impressions),
      'completedDate': serializer.toJson<DateTime?>(completedDate),
      'startDate': serializer.toJson<DateTime?>(startDate),
      'endDate': serializer.toJson<DateTime?>(endDate),
      'progress': serializer.toJson<int>(progress),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Book copyWith(
          {String? id,
          String? title,
          String? status,
          String? category,
          String? why,
          String? description,
          String? summary,
          String? impressions,
          Value<DateTime?> completedDate = const Value.absent(),
          Value<DateTime?> startDate = const Value.absent(),
          Value<DateTime?> endDate = const Value.absent(),
          int? progress,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Book(
        id: id ?? this.id,
        title: title ?? this.title,
        status: status ?? this.status,
        category: category ?? this.category,
        why: why ?? this.why,
        description: description ?? this.description,
        summary: summary ?? this.summary,
        impressions: impressions ?? this.impressions,
        completedDate:
            completedDate.present ? completedDate.value : this.completedDate,
        startDate: startDate.present ? startDate.value : this.startDate,
        endDate: endDate.present ? endDate.value : this.endDate,
        progress: progress ?? this.progress,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Book copyWithCompanion(BooksCompanion data) {
    return Book(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      status: data.status.present ? data.status.value : this.status,
      category: data.category.present ? data.category.value : this.category,
      why: data.why.present ? data.why.value : this.why,
      description:
          data.description.present ? data.description.value : this.description,
      summary: data.summary.present ? data.summary.value : this.summary,
      impressions:
          data.impressions.present ? data.impressions.value : this.impressions,
      completedDate: data.completedDate.present
          ? data.completedDate.value
          : this.completedDate,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      progress: data.progress.present ? data.progress.value : this.progress,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Book(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('status: $status, ')
          ..write('category: $category, ')
          ..write('why: $why, ')
          ..write('description: $description, ')
          ..write('summary: $summary, ')
          ..write('impressions: $impressions, ')
          ..write('completedDate: $completedDate, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('progress: $progress, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      title,
      status,
      category,
      why,
      description,
      summary,
      impressions,
      completedDate,
      startDate,
      endDate,
      progress,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Book &&
          other.id == this.id &&
          other.title == this.title &&
          other.status == this.status &&
          other.category == this.category &&
          other.why == this.why &&
          other.description == this.description &&
          other.summary == this.summary &&
          other.impressions == this.impressions &&
          other.completedDate == this.completedDate &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.progress == this.progress &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BooksCompanion extends UpdateCompanion<Book> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> status;
  final Value<String> category;
  final Value<String> why;
  final Value<String> description;
  final Value<String> summary;
  final Value<String> impressions;
  final Value<DateTime?> completedDate;
  final Value<DateTime?> startDate;
  final Value<DateTime?> endDate;
  final Value<int> progress;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const BooksCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.status = const Value.absent(),
    this.category = const Value.absent(),
    this.why = const Value.absent(),
    this.description = const Value.absent(),
    this.summary = const Value.absent(),
    this.impressions = const Value.absent(),
    this.completedDate = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.progress = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BooksCompanion.insert({
    required String id,
    required String title,
    this.status = const Value.absent(),
    this.category = const Value.absent(),
    this.why = const Value.absent(),
    this.description = const Value.absent(),
    this.summary = const Value.absent(),
    this.impressions = const Value.absent(),
    this.completedDate = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.progress = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Book> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? status,
    Expression<String>? category,
    Expression<String>? why,
    Expression<String>? description,
    Expression<String>? summary,
    Expression<String>? impressions,
    Expression<DateTime>? completedDate,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
    Expression<int>? progress,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (status != null) 'status': status,
      if (category != null) 'category': category,
      if (why != null) 'why': why,
      if (description != null) 'description': description,
      if (summary != null) 'summary': summary,
      if (impressions != null) 'impressions': impressions,
      if (completedDate != null) 'completed_date': completedDate,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (progress != null) 'progress': progress,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BooksCompanion copyWith(
      {Value<String>? id,
      Value<String>? title,
      Value<String>? status,
      Value<String>? category,
      Value<String>? why,
      Value<String>? description,
      Value<String>? summary,
      Value<String>? impressions,
      Value<DateTime?>? completedDate,
      Value<DateTime?>? startDate,
      Value<DateTime?>? endDate,
      Value<int>? progress,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return BooksCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      status: status ?? this.status,
      category: category ?? this.category,
      why: why ?? this.why,
      description: description ?? this.description,
      summary: summary ?? this.summary,
      impressions: impressions ?? this.impressions,
      completedDate: completedDate ?? this.completedDate,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      progress: progress ?? this.progress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (why.present) {
      map['why'] = Variable<String>(why.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (impressions.present) {
      map['impressions'] = Variable<String>(impressions.value);
    }
    if (completedDate.present) {
      map['completed_date'] = Variable<DateTime>(completedDate.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (progress.present) {
      map['progress'] = Variable<int>(progress.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BooksCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('status: $status, ')
          ..write('category: $category, ')
          ..write('why: $why, ')
          ..write('description: $description, ')
          ..write('summary: $summary, ')
          ..write('impressions: $impressions, ')
          ..write('completedDate: $completedDate, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('progress: $progress, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StudyLogsTable extends StudyLogs
    with TableInfo<$StudyLogsTable, StudyLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StudyLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
      'task_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _studyDateMeta =
      const VerificationMeta('studyDate');
  @override
  late final GeneratedColumn<DateTime> studyDate = GeneratedColumn<DateTime>(
      'study_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _durationMinutesMeta =
      const VerificationMeta('durationMinutes');
  @override
  late final GeneratedColumn<int> durationMinutes = GeneratedColumn<int>(
      'duration_minutes', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  @override
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
      'memo', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _taskNameMeta =
      const VerificationMeta('taskName');
  @override
  late final GeneratedColumn<String> taskName = GeneratedColumn<String>(
      'task_name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, taskId, studyDate, durationMinutes, memo, taskName, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'study_logs';
  @override
  VerificationContext validateIntegrity(Insertable<StudyLog> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('task_id')) {
      context.handle(_taskIdMeta,
          taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta));
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('study_date')) {
      context.handle(_studyDateMeta,
          studyDate.isAcceptableOrUnknown(data['study_date']!, _studyDateMeta));
    } else if (isInserting) {
      context.missing(_studyDateMeta);
    }
    if (data.containsKey('duration_minutes')) {
      context.handle(
          _durationMinutesMeta,
          durationMinutes.isAcceptableOrUnknown(
              data['duration_minutes']!, _durationMinutesMeta));
    } else if (isInserting) {
      context.missing(_durationMinutesMeta);
    }
    if (data.containsKey('memo')) {
      context.handle(
          _memoMeta, memo.isAcceptableOrUnknown(data['memo']!, _memoMeta));
    }
    if (data.containsKey('task_name')) {
      context.handle(_taskNameMeta,
          taskName.isAcceptableOrUnknown(data['task_name']!, _taskNameMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StudyLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StudyLog(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      taskId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}task_id'])!,
      studyDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}study_date'])!,
      durationMinutes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_minutes'])!,
      memo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}memo'])!,
      taskName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}task_name'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $StudyLogsTable createAlias(String alias) {
    return $StudyLogsTable(attachedDatabase, alias);
  }
}

class StudyLog extends DataClass implements Insertable<StudyLog> {
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
  const StudyLog(
      {required this.id,
      required this.taskId,
      required this.studyDate,
      required this.durationMinutes,
      required this.memo,
      required this.taskName,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['task_id'] = Variable<String>(taskId);
    map['study_date'] = Variable<DateTime>(studyDate);
    map['duration_minutes'] = Variable<int>(durationMinutes);
    map['memo'] = Variable<String>(memo);
    map['task_name'] = Variable<String>(taskName);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  StudyLogsCompanion toCompanion(bool nullToAbsent) {
    return StudyLogsCompanion(
      id: Value(id),
      taskId: Value(taskId),
      studyDate: Value(studyDate),
      durationMinutes: Value(durationMinutes),
      memo: Value(memo),
      taskName: Value(taskName),
      createdAt: Value(createdAt),
    );
  }

  factory StudyLog.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StudyLog(
      id: serializer.fromJson<String>(json['id']),
      taskId: serializer.fromJson<String>(json['taskId']),
      studyDate: serializer.fromJson<DateTime>(json['studyDate']),
      durationMinutes: serializer.fromJson<int>(json['durationMinutes']),
      memo: serializer.fromJson<String>(json['memo']),
      taskName: serializer.fromJson<String>(json['taskName']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'taskId': serializer.toJson<String>(taskId),
      'studyDate': serializer.toJson<DateTime>(studyDate),
      'durationMinutes': serializer.toJson<int>(durationMinutes),
      'memo': serializer.toJson<String>(memo),
      'taskName': serializer.toJson<String>(taskName),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  StudyLog copyWith(
          {String? id,
          String? taskId,
          DateTime? studyDate,
          int? durationMinutes,
          String? memo,
          String? taskName,
          DateTime? createdAt}) =>
      StudyLog(
        id: id ?? this.id,
        taskId: taskId ?? this.taskId,
        studyDate: studyDate ?? this.studyDate,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        memo: memo ?? this.memo,
        taskName: taskName ?? this.taskName,
        createdAt: createdAt ?? this.createdAt,
      );
  StudyLog copyWithCompanion(StudyLogsCompanion data) {
    return StudyLog(
      id: data.id.present ? data.id.value : this.id,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      studyDate: data.studyDate.present ? data.studyDate.value : this.studyDate,
      durationMinutes: data.durationMinutes.present
          ? data.durationMinutes.value
          : this.durationMinutes,
      memo: data.memo.present ? data.memo.value : this.memo,
      taskName: data.taskName.present ? data.taskName.value : this.taskName,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StudyLog(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('studyDate: $studyDate, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('memo: $memo, ')
          ..write('taskName: $taskName, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, taskId, studyDate, durationMinutes, memo, taskName, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StudyLog &&
          other.id == this.id &&
          other.taskId == this.taskId &&
          other.studyDate == this.studyDate &&
          other.durationMinutes == this.durationMinutes &&
          other.memo == this.memo &&
          other.taskName == this.taskName &&
          other.createdAt == this.createdAt);
}

class StudyLogsCompanion extends UpdateCompanion<StudyLog> {
  final Value<String> id;
  final Value<String> taskId;
  final Value<DateTime> studyDate;
  final Value<int> durationMinutes;
  final Value<String> memo;
  final Value<String> taskName;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const StudyLogsCompanion({
    this.id = const Value.absent(),
    this.taskId = const Value.absent(),
    this.studyDate = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.memo = const Value.absent(),
    this.taskName = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StudyLogsCompanion.insert({
    required String id,
    required String taskId,
    required DateTime studyDate,
    required int durationMinutes,
    this.memo = const Value.absent(),
    this.taskName = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        taskId = Value(taskId),
        studyDate = Value(studyDate),
        durationMinutes = Value(durationMinutes),
        createdAt = Value(createdAt);
  static Insertable<StudyLog> custom({
    Expression<String>? id,
    Expression<String>? taskId,
    Expression<DateTime>? studyDate,
    Expression<int>? durationMinutes,
    Expression<String>? memo,
    Expression<String>? taskName,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskId != null) 'task_id': taskId,
      if (studyDate != null) 'study_date': studyDate,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (memo != null) 'memo': memo,
      if (taskName != null) 'task_name': taskName,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StudyLogsCompanion copyWith(
      {Value<String>? id,
      Value<String>? taskId,
      Value<DateTime>? studyDate,
      Value<int>? durationMinutes,
      Value<String>? memo,
      Value<String>? taskName,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return StudyLogsCompanion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      studyDate: studyDate ?? this.studyDate,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      memo: memo ?? this.memo,
      taskName: taskName ?? this.taskName,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (studyDate.present) {
      map['study_date'] = Variable<DateTime>(studyDate.value);
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<int>(durationMinutes.value);
    }
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    if (taskName.present) {
      map['task_name'] = Variable<String>(taskName.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StudyLogsCompanion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('studyDate: $studyDate, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('memo: $memo, ')
          ..write('taskName: $taskName, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NotificationsTable extends Notifications
    with TableInfo<$NotificationsTable, Notification> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotificationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _notificationTypeMeta =
      const VerificationMeta('notificationType');
  @override
  late final GeneratedColumn<String> notificationType = GeneratedColumn<String>(
      'notification_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _messageMeta =
      const VerificationMeta('message');
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
      'message', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isReadMeta = const VerificationMeta('isRead');
  @override
  late final GeneratedColumn<bool> isRead = GeneratedColumn<bool>(
      'is_read', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_read" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _dedupKeyMeta =
      const VerificationMeta('dedupKey');
  @override
  late final GeneratedColumn<String> dedupKey = GeneratedColumn<String>(
      'dedup_key', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  @override
  List<GeneratedColumn> get $columns =>
      [id, notificationType, title, message, isRead, createdAt, dedupKey];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notifications';
  @override
  VerificationContext validateIntegrity(Insertable<Notification> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('notification_type')) {
      context.handle(
          _notificationTypeMeta,
          notificationType.isAcceptableOrUnknown(
              data['notification_type']!, _notificationTypeMeta));
    } else if (isInserting) {
      context.missing(_notificationTypeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('message')) {
      context.handle(_messageMeta,
          message.isAcceptableOrUnknown(data['message']!, _messageMeta));
    } else if (isInserting) {
      context.missing(_messageMeta);
    }
    if (data.containsKey('is_read')) {
      context.handle(_isReadMeta,
          isRead.isAcceptableOrUnknown(data['is_read']!, _isReadMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('dedup_key')) {
      context.handle(_dedupKeyMeta,
          dedupKey.isAcceptableOrUnknown(data['dedup_key']!, _dedupKeyMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Notification map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Notification(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      notificationType: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}notification_type'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      message: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message'])!,
      isRead: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_read'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      dedupKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}dedup_key'])!,
    );
  }

  @override
  $NotificationsTable createAlias(String alias) {
    return $NotificationsTable(attachedDatabase, alias);
  }
}

class Notification extends DataClass implements Insertable<Notification> {
  /// 一意識別子.
  final String id;

  /// 通知種別（system, achievement）.
  final String notificationType;

  /// 通知タイトル.
  final String title;

  /// 通知メッセージ.
  final String message;

  /// 既読フラグ.
  final bool isRead;

  /// 作成日時.
  final DateTime createdAt;

  /// 重複防止キー.
  final String dedupKey;
  const Notification(
      {required this.id,
      required this.notificationType,
      required this.title,
      required this.message,
      required this.isRead,
      required this.createdAt,
      required this.dedupKey});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['notification_type'] = Variable<String>(notificationType);
    map['title'] = Variable<String>(title);
    map['message'] = Variable<String>(message);
    map['is_read'] = Variable<bool>(isRead);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['dedup_key'] = Variable<String>(dedupKey);
    return map;
  }

  NotificationsCompanion toCompanion(bool nullToAbsent) {
    return NotificationsCompanion(
      id: Value(id),
      notificationType: Value(notificationType),
      title: Value(title),
      message: Value(message),
      isRead: Value(isRead),
      createdAt: Value(createdAt),
      dedupKey: Value(dedupKey),
    );
  }

  factory Notification.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Notification(
      id: serializer.fromJson<String>(json['id']),
      notificationType: serializer.fromJson<String>(json['notificationType']),
      title: serializer.fromJson<String>(json['title']),
      message: serializer.fromJson<String>(json['message']),
      isRead: serializer.fromJson<bool>(json['isRead']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      dedupKey: serializer.fromJson<String>(json['dedupKey']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'notificationType': serializer.toJson<String>(notificationType),
      'title': serializer.toJson<String>(title),
      'message': serializer.toJson<String>(message),
      'isRead': serializer.toJson<bool>(isRead),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'dedupKey': serializer.toJson<String>(dedupKey),
    };
  }

  Notification copyWith(
          {String? id,
          String? notificationType,
          String? title,
          String? message,
          bool? isRead,
          DateTime? createdAt,
          String? dedupKey}) =>
      Notification(
        id: id ?? this.id,
        notificationType: notificationType ?? this.notificationType,
        title: title ?? this.title,
        message: message ?? this.message,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt ?? this.createdAt,
        dedupKey: dedupKey ?? this.dedupKey,
      );
  Notification copyWithCompanion(NotificationsCompanion data) {
    return Notification(
      id: data.id.present ? data.id.value : this.id,
      notificationType: data.notificationType.present
          ? data.notificationType.value
          : this.notificationType,
      title: data.title.present ? data.title.value : this.title,
      message: data.message.present ? data.message.value : this.message,
      isRead: data.isRead.present ? data.isRead.value : this.isRead,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      dedupKey: data.dedupKey.present ? data.dedupKey.value : this.dedupKey,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Notification(')
          ..write('id: $id, ')
          ..write('notificationType: $notificationType, ')
          ..write('title: $title, ')
          ..write('message: $message, ')
          ..write('isRead: $isRead, ')
          ..write('createdAt: $createdAt, ')
          ..write('dedupKey: $dedupKey')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, notificationType, title, message, isRead, createdAt, dedupKey);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Notification &&
          other.id == this.id &&
          other.notificationType == this.notificationType &&
          other.title == this.title &&
          other.message == this.message &&
          other.isRead == this.isRead &&
          other.createdAt == this.createdAt &&
          other.dedupKey == this.dedupKey);
}

class NotificationsCompanion extends UpdateCompanion<Notification> {
  final Value<String> id;
  final Value<String> notificationType;
  final Value<String> title;
  final Value<String> message;
  final Value<bool> isRead;
  final Value<DateTime> createdAt;
  final Value<String> dedupKey;
  final Value<int> rowid;
  const NotificationsCompanion({
    this.id = const Value.absent(),
    this.notificationType = const Value.absent(),
    this.title = const Value.absent(),
    this.message = const Value.absent(),
    this.isRead = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.dedupKey = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotificationsCompanion.insert({
    required String id,
    required String notificationType,
    required String title,
    required String message,
    this.isRead = const Value.absent(),
    required DateTime createdAt,
    this.dedupKey = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        notificationType = Value(notificationType),
        title = Value(title),
        message = Value(message),
        createdAt = Value(createdAt);
  static Insertable<Notification> custom({
    Expression<String>? id,
    Expression<String>? notificationType,
    Expression<String>? title,
    Expression<String>? message,
    Expression<bool>? isRead,
    Expression<DateTime>? createdAt,
    Expression<String>? dedupKey,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (notificationType != null) 'notification_type': notificationType,
      if (title != null) 'title': title,
      if (message != null) 'message': message,
      if (isRead != null) 'is_read': isRead,
      if (createdAt != null) 'created_at': createdAt,
      if (dedupKey != null) 'dedup_key': dedupKey,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotificationsCompanion copyWith(
      {Value<String>? id,
      Value<String>? notificationType,
      Value<String>? title,
      Value<String>? message,
      Value<bool>? isRead,
      Value<DateTime>? createdAt,
      Value<String>? dedupKey,
      Value<int>? rowid}) {
    return NotificationsCompanion(
      id: id ?? this.id,
      notificationType: notificationType ?? this.notificationType,
      title: title ?? this.title,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      dedupKey: dedupKey ?? this.dedupKey,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (notificationType.present) {
      map['notification_type'] = Variable<String>(notificationType.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (isRead.present) {
      map['is_read'] = Variable<bool>(isRead.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (dedupKey.present) {
      map['dedup_key'] = Variable<String>(dedupKey.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotificationsCompanion(')
          ..write('id: $id, ')
          ..write('notificationType: $notificationType, ')
          ..write('title: $title, ')
          ..write('message: $message, ')
          ..write('isRead: $isRead, ')
          ..write('createdAt: $createdAt, ')
          ..write('dedupKey: $dedupKey, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DreamsTable dreams = $DreamsTable(this);
  late final $GoalsTable goals = $GoalsTable(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $BooksTable books = $BooksTable(this);
  late final $StudyLogsTable studyLogs = $StudyLogsTable(this);
  late final $NotificationsTable notifications = $NotificationsTable(this);
  late final DreamDao dreamDao = DreamDao(this as AppDatabase);
  late final GoalDao goalDao = GoalDao(this as AppDatabase);
  late final TaskDao taskDao = TaskDao(this as AppDatabase);
  late final BookDao bookDao = BookDao(this as AppDatabase);
  late final StudyLogDao studyLogDao = StudyLogDao(this as AppDatabase);
  late final NotificationDao notificationDao =
      NotificationDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [dreams, goals, tasks, books, studyLogs, notifications];
}

typedef $$DreamsTableCreateCompanionBuilder = DreamsCompanion Function({
  required String id,
  required String title,
  Value<String> description,
  Value<String> why,
  Value<String> category,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$DreamsTableUpdateCompanionBuilder = DreamsCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String> description,
  Value<String> why,
  Value<String> category,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$DreamsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DreamsTable,
    Dream,
    $$DreamsTableFilterComposer,
    $$DreamsTableOrderingComposer,
    $$DreamsTableCreateCompanionBuilder,
    $$DreamsTableUpdateCompanionBuilder> {
  $$DreamsTableTableManager(_$AppDatabase db, $DreamsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$DreamsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$DreamsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String> why = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DreamsCompanion(
            id: id,
            title: title,
            description: description,
            why: why,
            category: category,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String title,
            Value<String> description = const Value.absent(),
            Value<String> why = const Value.absent(),
            Value<String> category = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              DreamsCompanion.insert(
            id: id,
            title: title,
            description: description,
            why: why,
            category: category,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
        ));
}

class $$DreamsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $DreamsTable> {
  $$DreamsTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get description => $state.composableBuilder(
      column: $state.table.description,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get why => $state.composableBuilder(
      column: $state.table.why,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get category => $state.composableBuilder(
      column: $state.table.category,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$DreamsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $DreamsTable> {
  $$DreamsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get description => $state.composableBuilder(
      column: $state.table.description,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get why => $state.composableBuilder(
      column: $state.table.why,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get category => $state.composableBuilder(
      column: $state.table.category,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$GoalsTableCreateCompanionBuilder = GoalsCompanion Function({
  required String id,
  Value<String> dreamId,
  required String why,
  required String whenTarget,
  required String whenType,
  required String what,
  required String how,
  Value<String> color,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$GoalsTableUpdateCompanionBuilder = GoalsCompanion Function({
  Value<String> id,
  Value<String> dreamId,
  Value<String> why,
  Value<String> whenTarget,
  Value<String> whenType,
  Value<String> what,
  Value<String> how,
  Value<String> color,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$GoalsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GoalsTable,
    Goal,
    $$GoalsTableFilterComposer,
    $$GoalsTableOrderingComposer,
    $$GoalsTableCreateCompanionBuilder,
    $$GoalsTableUpdateCompanionBuilder> {
  $$GoalsTableTableManager(_$AppDatabase db, $GoalsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$GoalsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$GoalsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> dreamId = const Value.absent(),
            Value<String> why = const Value.absent(),
            Value<String> whenTarget = const Value.absent(),
            Value<String> whenType = const Value.absent(),
            Value<String> what = const Value.absent(),
            Value<String> how = const Value.absent(),
            Value<String> color = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GoalsCompanion(
            id: id,
            dreamId: dreamId,
            why: why,
            whenTarget: whenTarget,
            whenType: whenType,
            what: what,
            how: how,
            color: color,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String> dreamId = const Value.absent(),
            required String why,
            required String whenTarget,
            required String whenType,
            required String what,
            required String how,
            Value<String> color = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              GoalsCompanion.insert(
            id: id,
            dreamId: dreamId,
            why: why,
            whenTarget: whenTarget,
            whenType: whenType,
            what: what,
            how: how,
            color: color,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
        ));
}

class $$GoalsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get dreamId => $state.composableBuilder(
      column: $state.table.dreamId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get why => $state.composableBuilder(
      column: $state.table.why,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get whenTarget => $state.composableBuilder(
      column: $state.table.whenTarget,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get whenType => $state.composableBuilder(
      column: $state.table.whenType,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get what => $state.composableBuilder(
      column: $state.table.what,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get how => $state.composableBuilder(
      column: $state.table.how,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get color => $state.composableBuilder(
      column: $state.table.color,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$GoalsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get dreamId => $state.composableBuilder(
      column: $state.table.dreamId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get why => $state.composableBuilder(
      column: $state.table.why,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get whenTarget => $state.composableBuilder(
      column: $state.table.whenTarget,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get whenType => $state.composableBuilder(
      column: $state.table.whenType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get what => $state.composableBuilder(
      column: $state.table.what,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get how => $state.composableBuilder(
      column: $state.table.how,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get color => $state.composableBuilder(
      column: $state.table.color,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$TasksTableCreateCompanionBuilder = TasksCompanion Function({
  required String id,
  required String goalId,
  required String title,
  required DateTime startDate,
  required DateTime endDate,
  Value<String> status,
  Value<int> progress,
  Value<String> memo,
  Value<String> bookId,
  Value<int> order,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$TasksTableUpdateCompanionBuilder = TasksCompanion Function({
  Value<String> id,
  Value<String> goalId,
  Value<String> title,
  Value<DateTime> startDate,
  Value<DateTime> endDate,
  Value<String> status,
  Value<int> progress,
  Value<String> memo,
  Value<String> bookId,
  Value<int> order,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$TasksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TasksTable,
    Task,
    $$TasksTableFilterComposer,
    $$TasksTableOrderingComposer,
    $$TasksTableCreateCompanionBuilder,
    $$TasksTableUpdateCompanionBuilder> {
  $$TasksTableTableManager(_$AppDatabase db, $TasksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$TasksTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$TasksTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> goalId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<DateTime> startDate = const Value.absent(),
            Value<DateTime> endDate = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> progress = const Value.absent(),
            Value<String> memo = const Value.absent(),
            Value<String> bookId = const Value.absent(),
            Value<int> order = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TasksCompanion(
            id: id,
            goalId: goalId,
            title: title,
            startDate: startDate,
            endDate: endDate,
            status: status,
            progress: progress,
            memo: memo,
            bookId: bookId,
            order: order,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String goalId,
            required String title,
            required DateTime startDate,
            required DateTime endDate,
            Value<String> status = const Value.absent(),
            Value<int> progress = const Value.absent(),
            Value<String> memo = const Value.absent(),
            Value<String> bookId = const Value.absent(),
            Value<int> order = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              TasksCompanion.insert(
            id: id,
            goalId: goalId,
            title: title,
            startDate: startDate,
            endDate: endDate,
            status: status,
            progress: progress,
            memo: memo,
            bookId: bookId,
            order: order,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
        ));
}

class $$TasksTableFilterComposer
    extends FilterComposer<_$AppDatabase, $TasksTable> {
  $$TasksTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get goalId => $state.composableBuilder(
      column: $state.table.goalId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get startDate => $state.composableBuilder(
      column: $state.table.startDate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get endDate => $state.composableBuilder(
      column: $state.table.endDate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get progress => $state.composableBuilder(
      column: $state.table.progress,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get memo => $state.composableBuilder(
      column: $state.table.memo,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get bookId => $state.composableBuilder(
      column: $state.table.bookId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get order => $state.composableBuilder(
      column: $state.table.order,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$TasksTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $TasksTable> {
  $$TasksTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get goalId => $state.composableBuilder(
      column: $state.table.goalId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get startDate => $state.composableBuilder(
      column: $state.table.startDate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get endDate => $state.composableBuilder(
      column: $state.table.endDate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get progress => $state.composableBuilder(
      column: $state.table.progress,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get memo => $state.composableBuilder(
      column: $state.table.memo,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get bookId => $state.composableBuilder(
      column: $state.table.bookId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get order => $state.composableBuilder(
      column: $state.table.order,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$BooksTableCreateCompanionBuilder = BooksCompanion Function({
  required String id,
  required String title,
  Value<String> status,
  Value<String> category,
  Value<String> why,
  Value<String> description,
  Value<String> summary,
  Value<String> impressions,
  Value<DateTime?> completedDate,
  Value<DateTime?> startDate,
  Value<DateTime?> endDate,
  Value<int> progress,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$BooksTableUpdateCompanionBuilder = BooksCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String> status,
  Value<String> category,
  Value<String> why,
  Value<String> description,
  Value<String> summary,
  Value<String> impressions,
  Value<DateTime?> completedDate,
  Value<DateTime?> startDate,
  Value<DateTime?> endDate,
  Value<int> progress,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$BooksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BooksTable,
    Book,
    $$BooksTableFilterComposer,
    $$BooksTableOrderingComposer,
    $$BooksTableCreateCompanionBuilder,
    $$BooksTableUpdateCompanionBuilder> {
  $$BooksTableTableManager(_$AppDatabase db, $BooksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$BooksTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$BooksTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<String> why = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String> summary = const Value.absent(),
            Value<String> impressions = const Value.absent(),
            Value<DateTime?> completedDate = const Value.absent(),
            Value<DateTime?> startDate = const Value.absent(),
            Value<DateTime?> endDate = const Value.absent(),
            Value<int> progress = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BooksCompanion(
            id: id,
            title: title,
            status: status,
            category: category,
            why: why,
            description: description,
            summary: summary,
            impressions: impressions,
            completedDate: completedDate,
            startDate: startDate,
            endDate: endDate,
            progress: progress,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String title,
            Value<String> status = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<String> why = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String> summary = const Value.absent(),
            Value<String> impressions = const Value.absent(),
            Value<DateTime?> completedDate = const Value.absent(),
            Value<DateTime?> startDate = const Value.absent(),
            Value<DateTime?> endDate = const Value.absent(),
            Value<int> progress = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              BooksCompanion.insert(
            id: id,
            title: title,
            status: status,
            category: category,
            why: why,
            description: description,
            summary: summary,
            impressions: impressions,
            completedDate: completedDate,
            startDate: startDate,
            endDate: endDate,
            progress: progress,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
        ));
}

class $$BooksTableFilterComposer
    extends FilterComposer<_$AppDatabase, $BooksTable> {
  $$BooksTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get category => $state.composableBuilder(
      column: $state.table.category,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get why => $state.composableBuilder(
      column: $state.table.why,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get description => $state.composableBuilder(
      column: $state.table.description,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get summary => $state.composableBuilder(
      column: $state.table.summary,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get impressions => $state.composableBuilder(
      column: $state.table.impressions,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get completedDate => $state.composableBuilder(
      column: $state.table.completedDate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get startDate => $state.composableBuilder(
      column: $state.table.startDate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get endDate => $state.composableBuilder(
      column: $state.table.endDate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get progress => $state.composableBuilder(
      column: $state.table.progress,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$BooksTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $BooksTable> {
  $$BooksTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get category => $state.composableBuilder(
      column: $state.table.category,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get why => $state.composableBuilder(
      column: $state.table.why,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get description => $state.composableBuilder(
      column: $state.table.description,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get summary => $state.composableBuilder(
      column: $state.table.summary,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get impressions => $state.composableBuilder(
      column: $state.table.impressions,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get completedDate => $state.composableBuilder(
      column: $state.table.completedDate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get startDate => $state.composableBuilder(
      column: $state.table.startDate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get endDate => $state.composableBuilder(
      column: $state.table.endDate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get progress => $state.composableBuilder(
      column: $state.table.progress,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$StudyLogsTableCreateCompanionBuilder = StudyLogsCompanion Function({
  required String id,
  required String taskId,
  required DateTime studyDate,
  required int durationMinutes,
  Value<String> memo,
  Value<String> taskName,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$StudyLogsTableUpdateCompanionBuilder = StudyLogsCompanion Function({
  Value<String> id,
  Value<String> taskId,
  Value<DateTime> studyDate,
  Value<int> durationMinutes,
  Value<String> memo,
  Value<String> taskName,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$StudyLogsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $StudyLogsTable,
    StudyLog,
    $$StudyLogsTableFilterComposer,
    $$StudyLogsTableOrderingComposer,
    $$StudyLogsTableCreateCompanionBuilder,
    $$StudyLogsTableUpdateCompanionBuilder> {
  $$StudyLogsTableTableManager(_$AppDatabase db, $StudyLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$StudyLogsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$StudyLogsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> taskId = const Value.absent(),
            Value<DateTime> studyDate = const Value.absent(),
            Value<int> durationMinutes = const Value.absent(),
            Value<String> memo = const Value.absent(),
            Value<String> taskName = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StudyLogsCompanion(
            id: id,
            taskId: taskId,
            studyDate: studyDate,
            durationMinutes: durationMinutes,
            memo: memo,
            taskName: taskName,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String taskId,
            required DateTime studyDate,
            required int durationMinutes,
            Value<String> memo = const Value.absent(),
            Value<String> taskName = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              StudyLogsCompanion.insert(
            id: id,
            taskId: taskId,
            studyDate: studyDate,
            durationMinutes: durationMinutes,
            memo: memo,
            taskName: taskName,
            createdAt: createdAt,
            rowid: rowid,
          ),
        ));
}

class $$StudyLogsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $StudyLogsTable> {
  $$StudyLogsTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get taskId => $state.composableBuilder(
      column: $state.table.taskId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get studyDate => $state.composableBuilder(
      column: $state.table.studyDate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get durationMinutes => $state.composableBuilder(
      column: $state.table.durationMinutes,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get memo => $state.composableBuilder(
      column: $state.table.memo,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get taskName => $state.composableBuilder(
      column: $state.table.taskName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$StudyLogsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $StudyLogsTable> {
  $$StudyLogsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get taskId => $state.composableBuilder(
      column: $state.table.taskId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get studyDate => $state.composableBuilder(
      column: $state.table.studyDate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get durationMinutes => $state.composableBuilder(
      column: $state.table.durationMinutes,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get memo => $state.composableBuilder(
      column: $state.table.memo,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get taskName => $state.composableBuilder(
      column: $state.table.taskName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$NotificationsTableCreateCompanionBuilder = NotificationsCompanion
    Function({
  required String id,
  required String notificationType,
  required String title,
  required String message,
  Value<bool> isRead,
  required DateTime createdAt,
  Value<String> dedupKey,
  Value<int> rowid,
});
typedef $$NotificationsTableUpdateCompanionBuilder = NotificationsCompanion
    Function({
  Value<String> id,
  Value<String> notificationType,
  Value<String> title,
  Value<String> message,
  Value<bool> isRead,
  Value<DateTime> createdAt,
  Value<String> dedupKey,
  Value<int> rowid,
});

class $$NotificationsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $NotificationsTable,
    Notification,
    $$NotificationsTableFilterComposer,
    $$NotificationsTableOrderingComposer,
    $$NotificationsTableCreateCompanionBuilder,
    $$NotificationsTableUpdateCompanionBuilder> {
  $$NotificationsTableTableManager(_$AppDatabase db, $NotificationsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$NotificationsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$NotificationsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> notificationType = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> message = const Value.absent(),
            Value<bool> isRead = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<String> dedupKey = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              NotificationsCompanion(
            id: id,
            notificationType: notificationType,
            title: title,
            message: message,
            isRead: isRead,
            createdAt: createdAt,
            dedupKey: dedupKey,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String notificationType,
            required String title,
            required String message,
            Value<bool> isRead = const Value.absent(),
            required DateTime createdAt,
            Value<String> dedupKey = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              NotificationsCompanion.insert(
            id: id,
            notificationType: notificationType,
            title: title,
            message: message,
            isRead: isRead,
            createdAt: createdAt,
            dedupKey: dedupKey,
            rowid: rowid,
          ),
        ));
}

class $$NotificationsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $NotificationsTable> {
  $$NotificationsTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get notificationType => $state.composableBuilder(
      column: $state.table.notificationType,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get message => $state.composableBuilder(
      column: $state.table.message,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isRead => $state.composableBuilder(
      column: $state.table.isRead,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get dedupKey => $state.composableBuilder(
      column: $state.table.dedupKey,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$NotificationsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $NotificationsTable> {
  $$NotificationsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get notificationType => $state.composableBuilder(
      column: $state.table.notificationType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get message => $state.composableBuilder(
      column: $state.table.message,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isRead => $state.composableBuilder(
      column: $state.table.isRead,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get dedupKey => $state.composableBuilder(
      column: $state.table.dedupKey,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DreamsTableTableManager get dreams =>
      $$DreamsTableTableManager(_db, _db.dreams);
  $$GoalsTableTableManager get goals =>
      $$GoalsTableTableManager(_db, _db.goals);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$BooksTableTableManager get books =>
      $$BooksTableTableManager(_db, _db.books);
  $$StudyLogsTableTableManager get studyLogs =>
      $$StudyLogsTableTableManager(_db, _db.studyLogs);
  $$NotificationsTableTableManager get notifications =>
      $$NotificationsTableTableManager(_db, _db.notifications);
}
