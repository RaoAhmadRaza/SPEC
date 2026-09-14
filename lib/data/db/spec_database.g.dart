// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'spec_database.dart';

// ignore_for_file: type=lint
class Zones extends Table with TableInfo<Zones, Zone> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Zones(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY AUTOINCREMENT',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL COLLATE NOCASE UNIQUE',
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, sortOrder, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'zones';
  @override
  VerificationContext validateIntegrity(
    Insertable<Zone> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Zone map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Zone(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  Zones createAlias(String alias) {
    return Zones(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Zone extends DataClass implements Insertable<Zone> {
  final int id;
  final String name;
  final int sortOrder;
  final DateTime createdAt;
  const Zone({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ZonesCompanion toCompanion(bool nullToAbsent) {
    return ZonesCompanion(
      id: Value(id),
      name: Value(name),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
    );
  }

  factory Zone.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Zone(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      sortOrder: serializer.fromJson<int>(json['sort_order']),
      createdAt: serializer.fromJson<DateTime>(json['created_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'sort_order': serializer.toJson<int>(sortOrder),
      'created_at': serializer.toJson<DateTime>(createdAt),
    };
  }

  Zone copyWith({int? id, String? name, int? sortOrder, DateTime? createdAt}) =>
      Zone(
        id: id ?? this.id,
        name: name ?? this.name,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt ?? this.createdAt,
      );
  Zone copyWithCompanion(ZonesCompanion data) {
    return Zone(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Zone(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, sortOrder, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Zone &&
          other.id == this.id &&
          other.name == this.name &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt);
}

class ZonesCompanion extends UpdateCompanion<Zone> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  const ZonesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ZonesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int sortOrder,
    required DateTime createdAt,
  }) : name = Value(name),
       sortOrder = Value(sortOrder),
       createdAt = Value(createdAt);
  static Insertable<Zone> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ZonesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? sortOrder,
    Value<DateTime>? createdAt,
  }) {
    return ZonesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ZonesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class Objects extends Table with TableInfo<Objects, SpecObject> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Objects(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY AUTOINCREMENT',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _zoneIdMeta = const VerificationMeta('zoneId');
  late final GeneratedColumn<int> zoneId = GeneratedColumn<int>(
    'zone_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES zones(id)ON DELETE SET NULL',
  );
  static const VerificationMeta _subLocationMeta = const VerificationMeta(
    'subLocation',
  );
  late final GeneratedColumn<String> subLocation = GeneratedColumn<String>(
    'sub_location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _specKindMeta = const VerificationMeta(
    'specKind',
  );
  late final GeneratedColumn<String> specKind = GeneratedColumn<String>(
    'spec_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _specValueMeta = const VerificationMeta(
    'specValue',
  );
  late final GeneratedColumn<String> specValue = GeneratedColumn<String>(
    'spec_value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _subtitleMeta = const VerificationMeta(
    'subtitle',
  );
  late final GeneratedColumn<String> subtitle = GeneratedColumn<String>(
    'subtitle',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _libraryTermMeta = const VerificationMeta(
    'libraryTerm',
  );
  late final GeneratedColumn<String> libraryTerm = GeneratedColumn<String>(
    'library_term',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _attributesMeta = const VerificationMeta(
    'attributes',
  );
  late final GeneratedColumn<String> attributes = GeneratedColumn<String>(
    'attributes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'[]\'',
    defaultValue: const CustomExpression('\'[]\''),
  );
  static const VerificationMeta _purchasedFromMeta = const VerificationMeta(
    'purchasedFrom',
  );
  late final GeneratedColumn<String> purchasedFrom = GeneratedColumn<String>(
    'purchased_from',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _replacedOnMeta = const VerificationMeta(
    'replacedOn',
  );
  late final GeneratedColumn<String> replacedOn = GeneratedColumn<String>(
    'replaced_on',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _remindEveryMonthsMeta = const VerificationMeta(
    'remindEveryMonths',
  );
  late final GeneratedColumn<int> remindEveryMonths = GeneratedColumn<int>(
    'remind_every_months',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    type,
    zoneId,
    subLocation,
    specKind,
    specValue,
    subtitle,
    libraryTerm,
    attributes,
    purchasedFrom,
    replacedOn,
    remindEveryMonths,
    createdAt,
    updatedAt,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'objects';
  @override
  VerificationContext validateIntegrity(
    Insertable<SpecObject> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('zone_id')) {
      context.handle(
        _zoneIdMeta,
        zoneId.isAcceptableOrUnknown(data['zone_id']!, _zoneIdMeta),
      );
    }
    if (data.containsKey('sub_location')) {
      context.handle(
        _subLocationMeta,
        subLocation.isAcceptableOrUnknown(
          data['sub_location']!,
          _subLocationMeta,
        ),
      );
    }
    if (data.containsKey('spec_kind')) {
      context.handle(
        _specKindMeta,
        specKind.isAcceptableOrUnknown(data['spec_kind']!, _specKindMeta),
      );
    } else if (isInserting) {
      context.missing(_specKindMeta);
    }
    if (data.containsKey('spec_value')) {
      context.handle(
        _specValueMeta,
        specValue.isAcceptableOrUnknown(data['spec_value']!, _specValueMeta),
      );
    } else if (isInserting) {
      context.missing(_specValueMeta);
    }
    if (data.containsKey('subtitle')) {
      context.handle(
        _subtitleMeta,
        subtitle.isAcceptableOrUnknown(data['subtitle']!, _subtitleMeta),
      );
    }
    if (data.containsKey('library_term')) {
      context.handle(
        _libraryTermMeta,
        libraryTerm.isAcceptableOrUnknown(
          data['library_term']!,
          _libraryTermMeta,
        ),
      );
    }
    if (data.containsKey('attributes')) {
      context.handle(
        _attributesMeta,
        attributes.isAcceptableOrUnknown(data['attributes']!, _attributesMeta),
      );
    }
    if (data.containsKey('purchased_from')) {
      context.handle(
        _purchasedFromMeta,
        purchasedFrom.isAcceptableOrUnknown(
          data['purchased_from']!,
          _purchasedFromMeta,
        ),
      );
    }
    if (data.containsKey('replaced_on')) {
      context.handle(
        _replacedOnMeta,
        replacedOn.isAcceptableOrUnknown(data['replaced_on']!, _replacedOnMeta),
      );
    }
    if (data.containsKey('remind_every_months')) {
      context.handle(
        _remindEveryMonthsMeta,
        remindEveryMonths.isAcceptableOrUnknown(
          data['remind_every_months']!,
          _remindEveryMonthsMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SpecObject map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SpecObject(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      zoneId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}zone_id'],
      ),
      subLocation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sub_location'],
      ),
      specKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}spec_kind'],
      )!,
      specValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}spec_value'],
      )!,
      subtitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subtitle'],
      ),
      libraryTerm: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}library_term'],
      ),
      attributes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attributes'],
      )!,
      purchasedFrom: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}purchased_from'],
      ),
      replacedOn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}replaced_on'],
      ),
      remindEveryMonths: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}remind_every_months'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  Objects createAlias(String alias) {
    return Objects(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class SpecObject extends DataClass implements Insertable<SpecObject> {
  final int id;
  final String name;
  final String type;

  /// product|device|car|home|clothing|other
  final int? zoneId;
  final String? subLocation;
  final String specKind;

  /// model|serial|filter|battery|other
  final String specValue;

  /// 'B22', the hero string
  final String? subtitle;

  /// A copied string, never a foreign key: it is what makes `bulb` return
  /// Headlight, and a copy lets the shipped catalogue change between releases
  /// without touching user rows.
  final String? libraryTerm;
  final String attributes;

  /// JSON, only ever read as one ordered set
  final String? purchasedFrom;

  /// 'IKEA', a vendor not a date
  final String? replacedOn;

  /// '2026-08-14', a calendar date
  final int? remindEveryMonths;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Last on purpose: schema v2 adds it with ALTER TABLE, which appends, so a
  /// migrated database and a fresh one have the same column order.
  final String? notes;
  const SpecObject({
    required this.id,
    required this.name,
    required this.type,
    this.zoneId,
    this.subLocation,
    required this.specKind,
    required this.specValue,
    this.subtitle,
    this.libraryTerm,
    required this.attributes,
    this.purchasedFrom,
    this.replacedOn,
    this.remindEveryMonths,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || zoneId != null) {
      map['zone_id'] = Variable<int>(zoneId);
    }
    if (!nullToAbsent || subLocation != null) {
      map['sub_location'] = Variable<String>(subLocation);
    }
    map['spec_kind'] = Variable<String>(specKind);
    map['spec_value'] = Variable<String>(specValue);
    if (!nullToAbsent || subtitle != null) {
      map['subtitle'] = Variable<String>(subtitle);
    }
    if (!nullToAbsent || libraryTerm != null) {
      map['library_term'] = Variable<String>(libraryTerm);
    }
    map['attributes'] = Variable<String>(attributes);
    if (!nullToAbsent || purchasedFrom != null) {
      map['purchased_from'] = Variable<String>(purchasedFrom);
    }
    if (!nullToAbsent || replacedOn != null) {
      map['replaced_on'] = Variable<String>(replacedOn);
    }
    if (!nullToAbsent || remindEveryMonths != null) {
      map['remind_every_months'] = Variable<int>(remindEveryMonths);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  ObjectsCompanion toCompanion(bool nullToAbsent) {
    return ObjectsCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      zoneId: zoneId == null && nullToAbsent
          ? const Value.absent()
          : Value(zoneId),
      subLocation: subLocation == null && nullToAbsent
          ? const Value.absent()
          : Value(subLocation),
      specKind: Value(specKind),
      specValue: Value(specValue),
      subtitle: subtitle == null && nullToAbsent
          ? const Value.absent()
          : Value(subtitle),
      libraryTerm: libraryTerm == null && nullToAbsent
          ? const Value.absent()
          : Value(libraryTerm),
      attributes: Value(attributes),
      purchasedFrom: purchasedFrom == null && nullToAbsent
          ? const Value.absent()
          : Value(purchasedFrom),
      replacedOn: replacedOn == null && nullToAbsent
          ? const Value.absent()
          : Value(replacedOn),
      remindEveryMonths: remindEveryMonths == null && nullToAbsent
          ? const Value.absent()
          : Value(remindEveryMonths),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory SpecObject.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SpecObject(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      zoneId: serializer.fromJson<int?>(json['zone_id']),
      subLocation: serializer.fromJson<String?>(json['sub_location']),
      specKind: serializer.fromJson<String>(json['spec_kind']),
      specValue: serializer.fromJson<String>(json['spec_value']),
      subtitle: serializer.fromJson<String?>(json['subtitle']),
      libraryTerm: serializer.fromJson<String?>(json['library_term']),
      attributes: serializer.fromJson<String>(json['attributes']),
      purchasedFrom: serializer.fromJson<String?>(json['purchased_from']),
      replacedOn: serializer.fromJson<String?>(json['replaced_on']),
      remindEveryMonths: serializer.fromJson<int?>(json['remind_every_months']),
      createdAt: serializer.fromJson<DateTime>(json['created_at']),
      updatedAt: serializer.fromJson<DateTime>(json['updated_at']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'zone_id': serializer.toJson<int?>(zoneId),
      'sub_location': serializer.toJson<String?>(subLocation),
      'spec_kind': serializer.toJson<String>(specKind),
      'spec_value': serializer.toJson<String>(specValue),
      'subtitle': serializer.toJson<String?>(subtitle),
      'library_term': serializer.toJson<String?>(libraryTerm),
      'attributes': serializer.toJson<String>(attributes),
      'purchased_from': serializer.toJson<String?>(purchasedFrom),
      'replaced_on': serializer.toJson<String?>(replacedOn),
      'remind_every_months': serializer.toJson<int?>(remindEveryMonths),
      'created_at': serializer.toJson<DateTime>(createdAt),
      'updated_at': serializer.toJson<DateTime>(updatedAt),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  SpecObject copyWith({
    int? id,
    String? name,
    String? type,
    Value<int?> zoneId = const Value.absent(),
    Value<String?> subLocation = const Value.absent(),
    String? specKind,
    String? specValue,
    Value<String?> subtitle = const Value.absent(),
    Value<String?> libraryTerm = const Value.absent(),
    String? attributes,
    Value<String?> purchasedFrom = const Value.absent(),
    Value<String?> replacedOn = const Value.absent(),
    Value<int?> remindEveryMonths = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<String?> notes = const Value.absent(),
  }) => SpecObject(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    zoneId: zoneId.present ? zoneId.value : this.zoneId,
    subLocation: subLocation.present ? subLocation.value : this.subLocation,
    specKind: specKind ?? this.specKind,
    specValue: specValue ?? this.specValue,
    subtitle: subtitle.present ? subtitle.value : this.subtitle,
    libraryTerm: libraryTerm.present ? libraryTerm.value : this.libraryTerm,
    attributes: attributes ?? this.attributes,
    purchasedFrom: purchasedFrom.present
        ? purchasedFrom.value
        : this.purchasedFrom,
    replacedOn: replacedOn.present ? replacedOn.value : this.replacedOn,
    remindEveryMonths: remindEveryMonths.present
        ? remindEveryMonths.value
        : this.remindEveryMonths,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    notes: notes.present ? notes.value : this.notes,
  );
  SpecObject copyWithCompanion(ObjectsCompanion data) {
    return SpecObject(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      zoneId: data.zoneId.present ? data.zoneId.value : this.zoneId,
      subLocation: data.subLocation.present
          ? data.subLocation.value
          : this.subLocation,
      specKind: data.specKind.present ? data.specKind.value : this.specKind,
      specValue: data.specValue.present ? data.specValue.value : this.specValue,
      subtitle: data.subtitle.present ? data.subtitle.value : this.subtitle,
      libraryTerm: data.libraryTerm.present
          ? data.libraryTerm.value
          : this.libraryTerm,
      attributes: data.attributes.present
          ? data.attributes.value
          : this.attributes,
      purchasedFrom: data.purchasedFrom.present
          ? data.purchasedFrom.value
          : this.purchasedFrom,
      replacedOn: data.replacedOn.present
          ? data.replacedOn.value
          : this.replacedOn,
      remindEveryMonths: data.remindEveryMonths.present
          ? data.remindEveryMonths.value
          : this.remindEveryMonths,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SpecObject(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('zoneId: $zoneId, ')
          ..write('subLocation: $subLocation, ')
          ..write('specKind: $specKind, ')
          ..write('specValue: $specValue, ')
          ..write('subtitle: $subtitle, ')
          ..write('libraryTerm: $libraryTerm, ')
          ..write('attributes: $attributes, ')
          ..write('purchasedFrom: $purchasedFrom, ')
          ..write('replacedOn: $replacedOn, ')
          ..write('remindEveryMonths: $remindEveryMonths, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    type,
    zoneId,
    subLocation,
    specKind,
    specValue,
    subtitle,
    libraryTerm,
    attributes,
    purchasedFrom,
    replacedOn,
    remindEveryMonths,
    createdAt,
    updatedAt,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SpecObject &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.zoneId == this.zoneId &&
          other.subLocation == this.subLocation &&
          other.specKind == this.specKind &&
          other.specValue == this.specValue &&
          other.subtitle == this.subtitle &&
          other.libraryTerm == this.libraryTerm &&
          other.attributes == this.attributes &&
          other.purchasedFrom == this.purchasedFrom &&
          other.replacedOn == this.replacedOn &&
          other.remindEveryMonths == this.remindEveryMonths &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.notes == this.notes);
}

class ObjectsCompanion extends UpdateCompanion<SpecObject> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> type;
  final Value<int?> zoneId;
  final Value<String?> subLocation;
  final Value<String> specKind;
  final Value<String> specValue;
  final Value<String?> subtitle;
  final Value<String?> libraryTerm;
  final Value<String> attributes;
  final Value<String?> purchasedFrom;
  final Value<String?> replacedOn;
  final Value<int?> remindEveryMonths;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String?> notes;
  const ObjectsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.zoneId = const Value.absent(),
    this.subLocation = const Value.absent(),
    this.specKind = const Value.absent(),
    this.specValue = const Value.absent(),
    this.subtitle = const Value.absent(),
    this.libraryTerm = const Value.absent(),
    this.attributes = const Value.absent(),
    this.purchasedFrom = const Value.absent(),
    this.replacedOn = const Value.absent(),
    this.remindEveryMonths = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.notes = const Value.absent(),
  });
  ObjectsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String type,
    this.zoneId = const Value.absent(),
    this.subLocation = const Value.absent(),
    required String specKind,
    required String specValue,
    this.subtitle = const Value.absent(),
    this.libraryTerm = const Value.absent(),
    this.attributes = const Value.absent(),
    this.purchasedFrom = const Value.absent(),
    this.replacedOn = const Value.absent(),
    this.remindEveryMonths = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.notes = const Value.absent(),
  }) : name = Value(name),
       type = Value(type),
       specKind = Value(specKind),
       specValue = Value(specValue),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<SpecObject> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<int>? zoneId,
    Expression<String>? subLocation,
    Expression<String>? specKind,
    Expression<String>? specValue,
    Expression<String>? subtitle,
    Expression<String>? libraryTerm,
    Expression<String>? attributes,
    Expression<String>? purchasedFrom,
    Expression<String>? replacedOn,
    Expression<int>? remindEveryMonths,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? notes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (zoneId != null) 'zone_id': zoneId,
      if (subLocation != null) 'sub_location': subLocation,
      if (specKind != null) 'spec_kind': specKind,
      if (specValue != null) 'spec_value': specValue,
      if (subtitle != null) 'subtitle': subtitle,
      if (libraryTerm != null) 'library_term': libraryTerm,
      if (attributes != null) 'attributes': attributes,
      if (purchasedFrom != null) 'purchased_from': purchasedFrom,
      if (replacedOn != null) 'replaced_on': replacedOn,
      if (remindEveryMonths != null) 'remind_every_months': remindEveryMonths,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (notes != null) 'notes': notes,
    });
  }

  ObjectsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? type,
    Value<int?>? zoneId,
    Value<String?>? subLocation,
    Value<String>? specKind,
    Value<String>? specValue,
    Value<String?>? subtitle,
    Value<String?>? libraryTerm,
    Value<String>? attributes,
    Value<String?>? purchasedFrom,
    Value<String?>? replacedOn,
    Value<int?>? remindEveryMonths,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String?>? notes,
  }) {
    return ObjectsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      zoneId: zoneId ?? this.zoneId,
      subLocation: subLocation ?? this.subLocation,
      specKind: specKind ?? this.specKind,
      specValue: specValue ?? this.specValue,
      subtitle: subtitle ?? this.subtitle,
      libraryTerm: libraryTerm ?? this.libraryTerm,
      attributes: attributes ?? this.attributes,
      purchasedFrom: purchasedFrom ?? this.purchasedFrom,
      replacedOn: replacedOn ?? this.replacedOn,
      remindEveryMonths: remindEveryMonths ?? this.remindEveryMonths,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (zoneId.present) {
      map['zone_id'] = Variable<int>(zoneId.value);
    }
    if (subLocation.present) {
      map['sub_location'] = Variable<String>(subLocation.value);
    }
    if (specKind.present) {
      map['spec_kind'] = Variable<String>(specKind.value);
    }
    if (specValue.present) {
      map['spec_value'] = Variable<String>(specValue.value);
    }
    if (subtitle.present) {
      map['subtitle'] = Variable<String>(subtitle.value);
    }
    if (libraryTerm.present) {
      map['library_term'] = Variable<String>(libraryTerm.value);
    }
    if (attributes.present) {
      map['attributes'] = Variable<String>(attributes.value);
    }
    if (purchasedFrom.present) {
      map['purchased_from'] = Variable<String>(purchasedFrom.value);
    }
    if (replacedOn.present) {
      map['replaced_on'] = Variable<String>(replacedOn.value);
    }
    if (remindEveryMonths.present) {
      map['remind_every_months'] = Variable<int>(remindEveryMonths.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ObjectsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('zoneId: $zoneId, ')
          ..write('subLocation: $subLocation, ')
          ..write('specKind: $specKind, ')
          ..write('specValue: $specValue, ')
          ..write('subtitle: $subtitle, ')
          ..write('libraryTerm: $libraryTerm, ')
          ..write('attributes: $attributes, ')
          ..write('purchasedFrom: $purchasedFrom, ')
          ..write('replacedOn: $replacedOn, ')
          ..write('remindEveryMonths: $remindEveryMonths, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }
}

class Photos extends Table with TableInfo<Photos, Photo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Photos(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY AUTOINCREMENT',
  );
  static const VerificationMeta _objectIdMeta = const VerificationMeta(
    'objectId',
  );
  late final GeneratedColumn<int> objectId = GeneratedColumn<int>(
    'object_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES objects(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL UNIQUE',
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    objectId,
    fileName,
    sortOrder,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'photos';
  @override
  VerificationContext validateIntegrity(
    Insertable<Photo> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('object_id')) {
      context.handle(
        _objectIdMeta,
        objectId.isAcceptableOrUnknown(data['object_id']!, _objectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_objectIdMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Photo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Photo(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      objectId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}object_id'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  Photos createAlias(String alias) {
    return Photos(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Photo extends DataClass implements Insertable<Photo> {
  final int id;
  final int objectId;
  final String fileName;
  final int sortOrder;
  final DateTime createdAt;
  const Photo({
    required this.id,
    required this.objectId,
    required this.fileName,
    required this.sortOrder,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['object_id'] = Variable<int>(objectId);
    map['file_name'] = Variable<String>(fileName);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PhotosCompanion toCompanion(bool nullToAbsent) {
    return PhotosCompanion(
      id: Value(id),
      objectId: Value(objectId),
      fileName: Value(fileName),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
    );
  }

  factory Photo.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Photo(
      id: serializer.fromJson<int>(json['id']),
      objectId: serializer.fromJson<int>(json['object_id']),
      fileName: serializer.fromJson<String>(json['file_name']),
      sortOrder: serializer.fromJson<int>(json['sort_order']),
      createdAt: serializer.fromJson<DateTime>(json['created_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'object_id': serializer.toJson<int>(objectId),
      'file_name': serializer.toJson<String>(fileName),
      'sort_order': serializer.toJson<int>(sortOrder),
      'created_at': serializer.toJson<DateTime>(createdAt),
    };
  }

  Photo copyWith({
    int? id,
    int? objectId,
    String? fileName,
    int? sortOrder,
    DateTime? createdAt,
  }) => Photo(
    id: id ?? this.id,
    objectId: objectId ?? this.objectId,
    fileName: fileName ?? this.fileName,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
  );
  Photo copyWithCompanion(PhotosCompanion data) {
    return Photo(
      id: data.id.present ? data.id.value : this.id,
      objectId: data.objectId.present ? data.objectId.value : this.objectId,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Photo(')
          ..write('id: $id, ')
          ..write('objectId: $objectId, ')
          ..write('fileName: $fileName, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, objectId, fileName, sortOrder, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Photo &&
          other.id == this.id &&
          other.objectId == this.objectId &&
          other.fileName == this.fileName &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt);
}

class PhotosCompanion extends UpdateCompanion<Photo> {
  final Value<int> id;
  final Value<int> objectId;
  final Value<String> fileName;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  const PhotosCompanion({
    this.id = const Value.absent(),
    this.objectId = const Value.absent(),
    this.fileName = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PhotosCompanion.insert({
    this.id = const Value.absent(),
    required int objectId,
    required String fileName,
    required int sortOrder,
    required DateTime createdAt,
  }) : objectId = Value(objectId),
       fileName = Value(fileName),
       sortOrder = Value(sortOrder),
       createdAt = Value(createdAt);
  static Insertable<Photo> custom({
    Expression<int>? id,
    Expression<int>? objectId,
    Expression<String>? fileName,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (objectId != null) 'object_id': objectId,
      if (fileName != null) 'file_name': fileName,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PhotosCompanion copyWith({
    Value<int>? id,
    Value<int>? objectId,
    Value<String>? fileName,
    Value<int>? sortOrder,
    Value<DateTime>? createdAt,
  }) {
    return PhotosCompanion(
      id: id ?? this.id,
      objectId: objectId ?? this.objectId,
      fileName: fileName ?? this.fileName,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (objectId.present) {
      map['object_id'] = Variable<int>(objectId.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PhotosCompanion(')
          ..write('id: $id, ')
          ..write('objectId: $objectId, ')
          ..write('fileName: $fileName, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$SpecDatabase extends GeneratedDatabase {
  _$SpecDatabase(QueryExecutor e) : super(e);
  $SpecDatabaseManager get managers => $SpecDatabaseManager(this);
  late final Zones zones = Zones(this);
  late final Objects objects = Objects(this);
  late final Photos photos = Photos(this);
  late final Index objectsZone = Index(
    'objects_zone',
    'CREATE INDEX objects_zone ON objects (zone_id)',
  );
  late final Index objectsUpdated = Index(
    'objects_updated',
    'CREATE INDEX objects_updated ON objects (updated_at DESC)',
  );
  late final Index photosObject = Index(
    'photos_object',
    'CREATE INDEX photos_object ON photos (object_id, sort_order)',
  );
  Selectable<ObjectSummariesResult> objectSummaries() {
    return customSelect(
      'SELECT"o"."id" AS "nested_0.id", "o"."name" AS "nested_0.name", "o"."type" AS "nested_0.type", "o"."zone_id" AS "nested_0.zone_id", "o"."sub_location" AS "nested_0.sub_location", "o"."spec_kind" AS "nested_0.spec_kind", "o"."spec_value" AS "nested_0.spec_value", "o"."subtitle" AS "nested_0.subtitle", "o"."library_term" AS "nested_0.library_term", "o"."attributes" AS "nested_0.attributes", "o"."purchased_from" AS "nested_0.purchased_from", "o"."replaced_on" AS "nested_0.replaced_on", "o"."remind_every_months" AS "nested_0.remind_every_months", "o"."created_at" AS "nested_0.created_at", "o"."updated_at" AS "nested_0.updated_at", "o"."notes" AS "nested_0.notes", z.name AS zone_name, (SELECT p.file_name FROM photos AS p WHERE p.object_id = o.id ORDER BY p.sort_order LIMIT 1) AS photo_file_name FROM objects AS o LEFT JOIN zones AS z ON z.id = o.zone_id ORDER BY o.updated_at DESC',
      variables: [],
      readsFrom: {this.zones, this.photos, this.objects},
    ).asyncMap(
      (QueryRow row) async => ObjectSummariesResult(
        o: await this.objects.mapFromRow(row, tablePrefix: 'nested_0'),
        zoneName: row.readNullable<String>('zone_name'),
        photoFileName: row.readNullable<String>('photo_file_name'),
      ),
    );
  }

  Selectable<ObjectSummaryResult> objectSummary(int id) {
    return customSelect(
      'SELECT"o"."id" AS "nested_0.id", "o"."name" AS "nested_0.name", "o"."type" AS "nested_0.type", "o"."zone_id" AS "nested_0.zone_id", "o"."sub_location" AS "nested_0.sub_location", "o"."spec_kind" AS "nested_0.spec_kind", "o"."spec_value" AS "nested_0.spec_value", "o"."subtitle" AS "nested_0.subtitle", "o"."library_term" AS "nested_0.library_term", "o"."attributes" AS "nested_0.attributes", "o"."purchased_from" AS "nested_0.purchased_from", "o"."replaced_on" AS "nested_0.replaced_on", "o"."remind_every_months" AS "nested_0.remind_every_months", "o"."created_at" AS "nested_0.created_at", "o"."updated_at" AS "nested_0.updated_at", "o"."notes" AS "nested_0.notes", z.name AS zone_name, (SELECT p.file_name FROM photos AS p WHERE p.object_id = o.id ORDER BY p.sort_order LIMIT 1) AS photo_file_name FROM objects AS o LEFT JOIN zones AS z ON z.id = o.zone_id WHERE o.id = ?1',
      variables: [Variable<int>(id)],
      readsFrom: {this.zones, this.photos, this.objects},
    ).asyncMap(
      (QueryRow row) async => ObjectSummaryResult(
        o: await this.objects.mapFromRow(row, tablePrefix: 'nested_0'),
        zoneName: row.readNullable<String>('zone_name'),
        photoFileName: row.readNullable<String>('photo_file_name'),
      ),
    );
  }

  Selectable<String> objectPhotoNames(int id) {
    return customSelect(
      'SELECT file_name FROM photos WHERE object_id = ?1 ORDER BY sort_order',
      variables: [Variable<int>(id)],
      readsFrom: {this.photos},
    ).map((QueryRow row) => row.read<String>('file_name'));
  }

  Selectable<ArchiveCountsResult> archiveCounts() {
    return customSelect(
      'SELECT (SELECT COUNT(*) FROM objects) AS object_count, (SELECT COUNT(*) FROM photos) AS photo_count',
      variables: [],
      readsFrom: {this.objects, this.photos},
    ).map(
      (QueryRow row) => ArchiveCountsResult(
        objectCount: row.read<int>('object_count'),
        photoCount: row.read<int>('photo_count'),
      ),
    );
  }

  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    zones,
    objects,
    photos,
    objectsZone,
    objectsUpdated,
    photosObject,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'zones',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('objects', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'objects',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('photos', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $ZonesCreateCompanionBuilder = ZonesCompanion Function({
  Value<int> id,
  required String name,
  required int sortOrder,
  required DateTime createdAt,
});
typedef $ZonesUpdateCompanionBuilder = ZonesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<int> sortOrder,
  Value<DateTime> createdAt,
});

final class $ZonesReferences
    extends BaseReferences<_$SpecDatabase, Zones, Zone> {
  $ZonesReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<Objects, List<SpecObject>> _objectsRefsTable(
    _$SpecDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.objects,
    aliasName: 'zones__id__objects__zone_id',
  );

  $ObjectsProcessedTableManager get objectsRefs {
    final manager = $ObjectsTableManager(
      $_db,
      $_db.objects,
    ).filter((f) => f.zoneId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_objectsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $ZonesFilterComposer extends Composer<_$SpecDatabase, Zones> {
  $ZonesFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> objectsRefs(
    Expression<bool> Function($ObjectsFilterComposer f) f,
  ) {
    final $ObjectsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.objects,
      getReferencedColumn: (t) => t.zoneId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ObjectsFilterComposer(
            $db: $db,
            $table: $db.objects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $ZonesOrderingComposer extends Composer<_$SpecDatabase, Zones> {
  $ZonesOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $ZonesAnnotationComposer extends Composer<_$SpecDatabase, Zones> {
  $ZonesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> objectsRefs<T extends Object>(
    Expression<T> Function($ObjectsAnnotationComposer a) f,
  ) {
    final $ObjectsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.objects,
      getReferencedColumn: (t) => t.zoneId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ObjectsAnnotationComposer(
            $db: $db,
            $table: $db.objects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $ZonesTableManager
    extends
        RootTableManager<
          _$SpecDatabase,
          Zones,
          Zone,
          $ZonesFilterComposer,
          $ZonesOrderingComposer,
          $ZonesAnnotationComposer,
          $ZonesCreateCompanionBuilder,
          $ZonesUpdateCompanionBuilder,
          (Zone, $ZonesReferences),
          Zone,
          PrefetchHooks Function({bool objectsRefs})
        > {
  $ZonesTableManager(_$SpecDatabase db, Zones table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $ZonesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $ZonesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $ZonesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ZonesCompanion(
                id: id,
                name: name,
                sortOrder: sortOrder,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required int sortOrder,
                required DateTime createdAt,
              }) => ZonesCompanion.insert(
                id: id,
                name: name,
                sortOrder: sortOrder,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Zones, Zone>(table),
                  $ZonesReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({objectsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (objectsRefs) db.objects],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (objectsRefs)
                    await $_getPrefetchedData<Zone, Zones, SpecObject>(
                      currentTable: table,
                      referencedTable: $ZonesReferences._objectsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $ZonesReferences(db, table, p0).objectsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.zoneId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $ZonesProcessedTableManager =
    ProcessedTableManager<
      _$SpecDatabase,
      Zones,
      Zone,
      $ZonesFilterComposer,
      $ZonesOrderingComposer,
      $ZonesAnnotationComposer,
      $ZonesCreateCompanionBuilder,
      $ZonesUpdateCompanionBuilder,
      (Zone, $ZonesReferences),
      Zone,
      PrefetchHooks Function({bool objectsRefs})
    >;
typedef $ObjectsCreateCompanionBuilder = ObjectsCompanion Function({
  Value<int> id,
  required String name,
  required String type,
  Value<int?> zoneId,
  Value<String?> subLocation,
  required String specKind,
  required String specValue,
  Value<String?> subtitle,
  Value<String?> libraryTerm,
  Value<String> attributes,
  Value<String?> purchasedFrom,
  Value<String?> replacedOn,
  Value<int?> remindEveryMonths,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<String?> notes,
});
typedef $ObjectsUpdateCompanionBuilder = ObjectsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> type,
  Value<int?> zoneId,
  Value<String?> subLocation,
  Value<String> specKind,
  Value<String> specValue,
  Value<String?> subtitle,
  Value<String?> libraryTerm,
  Value<String> attributes,
  Value<String?> purchasedFrom,
  Value<String?> replacedOn,
  Value<int?> remindEveryMonths,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<String?> notes,
});

final class $ObjectsReferences
    extends BaseReferences<_$SpecDatabase, Objects, SpecObject> {
  $ObjectsReferences(super.$_db, super.$_table, super.$_typedResult);

  static Zones _zoneIdTable(_$SpecDatabase db) =>
      db.zones.createAlias('objects__zone_id__zones__id');

  $ZonesProcessedTableManager? get zoneId {
    final $_column = $_itemColumn<int>('zone_id');
    if ($_column == null) return null;
    final manager = $ZonesTableManager(
      $_db,
      $_db.zones,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_zoneIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<Photos, List<Photo>> _photosRefsTable(
    _$SpecDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.photos,
    aliasName: 'objects__id__photos__object_id',
  );

  $PhotosProcessedTableManager get photosRefs {
    final manager = $PhotosTableManager(
      $_db,
      $_db.photos,
    ).filter((f) => f.objectId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_photosRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $ObjectsFilterComposer extends Composer<_$SpecDatabase, Objects> {
  $ObjectsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subLocation => $composableBuilder(
    column: $table.subLocation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get specKind => $composableBuilder(
    column: $table.specKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get specValue => $composableBuilder(
    column: $table.specValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subtitle => $composableBuilder(
    column: $table.subtitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get libraryTerm => $composableBuilder(
    column: $table.libraryTerm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attributes => $composableBuilder(
    column: $table.attributes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get purchasedFrom => $composableBuilder(
    column: $table.purchasedFrom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get replacedOn => $composableBuilder(
    column: $table.replacedOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get remindEveryMonths => $composableBuilder(
    column: $table.remindEveryMonths,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  $ZonesFilterComposer get zoneId {
    final $ZonesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.zoneId,
      referencedTable: $db.zones,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ZonesFilterComposer(
            $db: $db,
            $table: $db.zones,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> photosRefs(
    Expression<bool> Function($PhotosFilterComposer f) f,
  ) {
    final $PhotosFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.photos,
      getReferencedColumn: (t) => t.objectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $PhotosFilterComposer(
            $db: $db,
            $table: $db.photos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $ObjectsOrderingComposer extends Composer<_$SpecDatabase, Objects> {
  $ObjectsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subLocation => $composableBuilder(
    column: $table.subLocation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get specKind => $composableBuilder(
    column: $table.specKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get specValue => $composableBuilder(
    column: $table.specValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subtitle => $composableBuilder(
    column: $table.subtitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get libraryTerm => $composableBuilder(
    column: $table.libraryTerm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attributes => $composableBuilder(
    column: $table.attributes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get purchasedFrom => $composableBuilder(
    column: $table.purchasedFrom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get replacedOn => $composableBuilder(
    column: $table.replacedOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get remindEveryMonths => $composableBuilder(
    column: $table.remindEveryMonths,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  $ZonesOrderingComposer get zoneId {
    final $ZonesOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.zoneId,
      referencedTable: $db.zones,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ZonesOrderingComposer(
            $db: $db,
            $table: $db.zones,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ObjectsAnnotationComposer extends Composer<_$SpecDatabase, Objects> {
  $ObjectsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get subLocation => $composableBuilder(
    column: $table.subLocation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get specKind =>
      $composableBuilder(column: $table.specKind, builder: (column) => column);

  GeneratedColumn<String> get specValue =>
      $composableBuilder(column: $table.specValue, builder: (column) => column);

  GeneratedColumn<String> get subtitle =>
      $composableBuilder(column: $table.subtitle, builder: (column) => column);

  GeneratedColumn<String> get libraryTerm => $composableBuilder(
    column: $table.libraryTerm,
    builder: (column) => column,
  );

  GeneratedColumn<String> get attributes => $composableBuilder(
    column: $table.attributes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get purchasedFrom => $composableBuilder(
    column: $table.purchasedFrom,
    builder: (column) => column,
  );

  GeneratedColumn<String> get replacedOn => $composableBuilder(
    column: $table.replacedOn,
    builder: (column) => column,
  );

  GeneratedColumn<int> get remindEveryMonths => $composableBuilder(
    column: $table.remindEveryMonths,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  $ZonesAnnotationComposer get zoneId {
    final $ZonesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.zoneId,
      referencedTable: $db.zones,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ZonesAnnotationComposer(
            $db: $db,
            $table: $db.zones,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> photosRefs<T extends Object>(
    Expression<T> Function($PhotosAnnotationComposer a) f,
  ) {
    final $PhotosAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.photos,
      getReferencedColumn: (t) => t.objectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $PhotosAnnotationComposer(
            $db: $db,
            $table: $db.photos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $ObjectsTableManager
    extends
        RootTableManager<
          _$SpecDatabase,
          Objects,
          SpecObject,
          $ObjectsFilterComposer,
          $ObjectsOrderingComposer,
          $ObjectsAnnotationComposer,
          $ObjectsCreateCompanionBuilder,
          $ObjectsUpdateCompanionBuilder,
          (SpecObject, $ObjectsReferences),
          SpecObject,
          PrefetchHooks Function({bool zoneId, bool photosRefs})
        > {
  $ObjectsTableManager(_$SpecDatabase db, Objects table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $ObjectsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $ObjectsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $ObjectsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int?> zoneId = const Value.absent(),
                Value<String?> subLocation = const Value.absent(),
                Value<String> specKind = const Value.absent(),
                Value<String> specValue = const Value.absent(),
                Value<String?> subtitle = const Value.absent(),
                Value<String?> libraryTerm = const Value.absent(),
                Value<String> attributes = const Value.absent(),
                Value<String?> purchasedFrom = const Value.absent(),
                Value<String?> replacedOn = const Value.absent(),
                Value<int?> remindEveryMonths = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => ObjectsCompanion(
                id: id,
                name: name,
                type: type,
                zoneId: zoneId,
                subLocation: subLocation,
                specKind: specKind,
                specValue: specValue,
                subtitle: subtitle,
                libraryTerm: libraryTerm,
                attributes: attributes,
                purchasedFrom: purchasedFrom,
                replacedOn: replacedOn,
                remindEveryMonths: remindEveryMonths,
                createdAt: createdAt,
                updatedAt: updatedAt,
                notes: notes,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String type,
                Value<int?> zoneId = const Value.absent(),
                Value<String?> subLocation = const Value.absent(),
                required String specKind,
                required String specValue,
                Value<String?> subtitle = const Value.absent(),
                Value<String?> libraryTerm = const Value.absent(),
                Value<String> attributes = const Value.absent(),
                Value<String?> purchasedFrom = const Value.absent(),
                Value<String?> replacedOn = const Value.absent(),
                Value<int?> remindEveryMonths = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<String?> notes = const Value.absent(),
              }) => ObjectsCompanion.insert(
                id: id,
                name: name,
                type: type,
                zoneId: zoneId,
                subLocation: subLocation,
                specKind: specKind,
                specValue: specValue,
                subtitle: subtitle,
                libraryTerm: libraryTerm,
                attributes: attributes,
                purchasedFrom: purchasedFrom,
                replacedOn: replacedOn,
                remindEveryMonths: remindEveryMonths,
                createdAt: createdAt,
                updatedAt: updatedAt,
                notes: notes,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Objects, SpecObject>(table),
                  $ObjectsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({zoneId = false, photosRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (photosRefs) db.photos],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (zoneId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.zoneId,
                        referencedTable: $ObjectsReferences._zoneIdTable(db),
                        referencedColumn: $ObjectsReferences
                            ._zoneIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (photosRefs)
                    await $_getPrefetchedData<SpecObject, Objects, Photo>(
                      currentTable: table,
                      referencedTable: $ObjectsReferences._photosRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $ObjectsReferences(db, table, p0).photosRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.objectId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $ObjectsProcessedTableManager =
    ProcessedTableManager<
      _$SpecDatabase,
      Objects,
      SpecObject,
      $ObjectsFilterComposer,
      $ObjectsOrderingComposer,
      $ObjectsAnnotationComposer,
      $ObjectsCreateCompanionBuilder,
      $ObjectsUpdateCompanionBuilder,
      (SpecObject, $ObjectsReferences),
      SpecObject,
      PrefetchHooks Function({bool zoneId, bool photosRefs})
    >;
typedef $PhotosCreateCompanionBuilder = PhotosCompanion Function({
  Value<int> id,
  required int objectId,
  required String fileName,
  required int sortOrder,
  required DateTime createdAt,
});
typedef $PhotosUpdateCompanionBuilder = PhotosCompanion Function({
  Value<int> id,
  Value<int> objectId,
  Value<String> fileName,
  Value<int> sortOrder,
  Value<DateTime> createdAt,
});

final class $PhotosReferences
    extends BaseReferences<_$SpecDatabase, Photos, Photo> {
  $PhotosReferences(super.$_db, super.$_table, super.$_typedResult);

  static Objects _objectIdTable(_$SpecDatabase db) =>
      db.objects.createAlias('photos__object_id__objects__id');

  $ObjectsProcessedTableManager get objectId {
    final $_column = $_itemColumn<int>('object_id')!;

    final manager = $ObjectsTableManager(
      $_db,
      $_db.objects,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_objectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $PhotosFilterComposer extends Composer<_$SpecDatabase, Photos> {
  $PhotosFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $ObjectsFilterComposer get objectId {
    final $ObjectsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.objectId,
      referencedTable: $db.objects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ObjectsFilterComposer(
            $db: $db,
            $table: $db.objects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $PhotosOrderingComposer extends Composer<_$SpecDatabase, Photos> {
  $PhotosOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $ObjectsOrderingComposer get objectId {
    final $ObjectsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.objectId,
      referencedTable: $db.objects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ObjectsOrderingComposer(
            $db: $db,
            $table: $db.objects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $PhotosAnnotationComposer extends Composer<_$SpecDatabase, Photos> {
  $PhotosAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $ObjectsAnnotationComposer get objectId {
    final $ObjectsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.objectId,
      referencedTable: $db.objects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ObjectsAnnotationComposer(
            $db: $db,
            $table: $db.objects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $PhotosTableManager
    extends
        RootTableManager<
          _$SpecDatabase,
          Photos,
          Photo,
          $PhotosFilterComposer,
          $PhotosOrderingComposer,
          $PhotosAnnotationComposer,
          $PhotosCreateCompanionBuilder,
          $PhotosUpdateCompanionBuilder,
          (Photo, $PhotosReferences),
          Photo,
          PrefetchHooks Function({bool objectId})
        > {
  $PhotosTableManager(_$SpecDatabase db, Photos table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $PhotosFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $PhotosOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $PhotosAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> objectId = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => PhotosCompanion(
                id: id,
                objectId: objectId,
                fileName: fileName,
                sortOrder: sortOrder,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int objectId,
                required String fileName,
                required int sortOrder,
                required DateTime createdAt,
              }) => PhotosCompanion.insert(
                id: id,
                objectId: objectId,
                fileName: fileName,
                sortOrder: sortOrder,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Photos, Photo>(table),
                  $PhotosReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({objectId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (objectId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.objectId,
                        referencedTable: $PhotosReferences._objectIdTable(db),
                        referencedColumn: $PhotosReferences
                            ._objectIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $PhotosProcessedTableManager =
    ProcessedTableManager<
      _$SpecDatabase,
      Photos,
      Photo,
      $PhotosFilterComposer,
      $PhotosOrderingComposer,
      $PhotosAnnotationComposer,
      $PhotosCreateCompanionBuilder,
      $PhotosUpdateCompanionBuilder,
      (Photo, $PhotosReferences),
      Photo,
      PrefetchHooks Function({bool objectId})
    >;

class $SpecDatabaseManager {
  final _$SpecDatabase _db;
  $SpecDatabaseManager(this._db);
  $ZonesTableManager get zones => $ZonesTableManager(_db, _db.zones);
  $ObjectsTableManager get objects => $ObjectsTableManager(_db, _db.objects);
  $PhotosTableManager get photos => $PhotosTableManager(_db, _db.photos);
}

class ObjectSummariesResult {
  final SpecObject o;
  final String? zoneName;
  final String? photoFileName;
  ObjectSummariesResult({required this.o, this.zoneName, this.photoFileName});
}

class ObjectSummaryResult {
  final SpecObject o;
  final String? zoneName;
  final String? photoFileName;
  ObjectSummaryResult({required this.o, this.zoneName, this.photoFileName});
}

class ArchiveCountsResult {
  final int objectCount;
  final int photoCount;
  ArchiveCountsResult({required this.objectCount, required this.photoCount});
}
