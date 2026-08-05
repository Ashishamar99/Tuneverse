// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'queue_entity.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetQueueEntityCollection on Isar {
  IsarCollection<QueueEntity> get queueEntitys => this.collection();
}

const QueueEntitySchema = CollectionSchema(
  name: r'QueueEntity',
  id: -1911240929921321666,
  properties: {
    r'currentIndex': PropertySchema(
      id: 0,
      name: r'currentIndex',
      type: IsarType.long,
    ),
    r'loopMode': PropertySchema(
      id: 1,
      name: r'loopMode',
      type: IsarType.byte,
      enumMap: _QueueEntityloopModeEnumValueMap,
    ),
    r'profileId': PropertySchema(
      id: 2,
      name: r'profileId',
      type: IsarType.string,
    ),
    r'shuffled': PropertySchema(
      id: 3,
      name: r'shuffled',
      type: IsarType.bool,
    ),
    r'trackIds': PropertySchema(
      id: 4,
      name: r'trackIds',
      type: IsarType.longList,
    )
  },
  estimateSize: _queueEntityEstimateSize,
  serialize: _queueEntitySerialize,
  deserialize: _queueEntityDeserialize,
  deserializeProp: _queueEntityDeserializeProp,
  idName: r'id',
  indexes: {
    r'profileId': IndexSchema(
      id: 6052971939042612300,
      name: r'profileId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'profileId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _queueEntityGetId,
  getLinks: _queueEntityGetLinks,
  attach: _queueEntityAttach,
  version: '3.1.0+1',
);

int _queueEntityEstimateSize(
  QueueEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.profileId.length * 3;
  bytesCount += 3 + object.trackIds.length * 8;
  return bytesCount;
}

void _queueEntitySerialize(
  QueueEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.currentIndex);
  writer.writeByte(offsets[1], object.loopMode.index);
  writer.writeString(offsets[2], object.profileId);
  writer.writeBool(offsets[3], object.shuffled);
  writer.writeLongList(offsets[4], object.trackIds);
}

QueueEntity _queueEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = QueueEntity();
  object.currentIndex = reader.readLong(offsets[0]);
  object.id = id;
  object.loopMode =
      _QueueEntityloopModeValueEnumMap[reader.readByteOrNull(offsets[1])] ??
          LoopMode.off;
  object.profileId = reader.readString(offsets[2]);
  object.shuffled = reader.readBool(offsets[3]);
  object.trackIds = reader.readLongList(offsets[4]) ?? [];
  return object;
}

P _queueEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (_QueueEntityloopModeValueEnumMap[reader.readByteOrNull(offset)] ??
          LoopMode.off) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readLongList(offset) ?? []) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _QueueEntityloopModeEnumValueMap = {
  'off': 0,
  'one': 1,
  'all': 2,
};
const _QueueEntityloopModeValueEnumMap = {
  0: LoopMode.off,
  1: LoopMode.one,
  2: LoopMode.all,
};

Id _queueEntityGetId(QueueEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _queueEntityGetLinks(QueueEntity object) {
  return [];
}

void _queueEntityAttach(
    IsarCollection<dynamic> col, Id id, QueueEntity object) {
  object.id = id;
}

extension QueueEntityByIndex on IsarCollection<QueueEntity> {
  Future<QueueEntity?> getByProfileId(String profileId) {
    return getByIndex(r'profileId', [profileId]);
  }

  QueueEntity? getByProfileIdSync(String profileId) {
    return getByIndexSync(r'profileId', [profileId]);
  }

  Future<bool> deleteByProfileId(String profileId) {
    return deleteByIndex(r'profileId', [profileId]);
  }

  bool deleteByProfileIdSync(String profileId) {
    return deleteByIndexSync(r'profileId', [profileId]);
  }

  Future<List<QueueEntity?>> getAllByProfileId(List<String> profileIdValues) {
    final values = profileIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'profileId', values);
  }

  List<QueueEntity?> getAllByProfileIdSync(List<String> profileIdValues) {
    final values = profileIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'profileId', values);
  }

  Future<int> deleteAllByProfileId(List<String> profileIdValues) {
    final values = profileIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'profileId', values);
  }

  int deleteAllByProfileIdSync(List<String> profileIdValues) {
    final values = profileIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'profileId', values);
  }

  Future<Id> putByProfileId(QueueEntity object) {
    return putByIndex(r'profileId', object);
  }

  Id putByProfileIdSync(QueueEntity object, {bool saveLinks = true}) {
    return putByIndexSync(r'profileId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByProfileId(List<QueueEntity> objects) {
    return putAllByIndex(r'profileId', objects);
  }

  List<Id> putAllByProfileIdSync(List<QueueEntity> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'profileId', objects, saveLinks: saveLinks);
  }
}

extension QueueEntityQueryWhereSort
    on QueryBuilder<QueueEntity, QueueEntity, QWhere> {
  QueryBuilder<QueueEntity, QueueEntity, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension QueueEntityQueryWhere
    on QueryBuilder<QueueEntity, QueueEntity, QWhereClause> {
  QueryBuilder<QueueEntity, QueueEntity, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<QueueEntity, QueueEntity, QAfterWhereClause> idNotEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<QueueEntity, QueueEntity, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<QueueEntity, QueueEntity, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<QueueEntity, QueueEntity, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<QueueEntity, QueueEntity, QAfterWhereClause> profileIdEqualTo(
      String profileId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'profileId',
        value: [profileId],
      ));
    });
  }

  QueryBuilder<QueueEntity, QueueEntity, QAfterWhereClause> profileIdNotEqualTo(
      String profileId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'profileId',
              lower: [],
              upper: [profileId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'profileId',
              lower: [profileId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'profileId',
              lower: [profileId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'profileId',
              lower: [],
              upper: [profileId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension QueueEntityQueryFilter
    on QueryBuilder<QueueEntity, QueueEntity, QFilterCondition> {
  QueryBuilder<QueueEntity, QueueEntity, QAfterFilterCondition>
      currentIndexEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currentIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<QueueEntity, QueueEntity, QAfterFilterCondition>
      currentIndexGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'currentIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<QueueEntity, QueueEntity, QAfterFilterCondition>
      currentIndexLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'currentIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<QueueEntity, QueueEntity, QAfterFilterCondition>
      currentIndexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'currentIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<QueueEntity, QueueEntity, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<QueueEntity, QueueEntity, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<QueueEntity, QueueEntity, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<QueueEntity, QueueEntity, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<QueueEntity, QueueEntity, QAfterFilterCondition> loopModeEqualTo(
      LoopMode value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'loopMode',
        value: value,
      ));
    });
  }

  QueryBuilder<QueueEntity, QueueEntity, QAfterFilterCondition>
      loopModeGreaterThan(
    LoopMode value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'loopMode',
        value: value,
      ));
    });
  }

  QueryBuilder<QueueEntity, QueueEntity, QAfterFilterCondition>
      loopModeLessThan(
    LoopMode value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'loopMode',
        value: value,
      ));
    });
  }

  QueryBuilder<QueueEntity, QueueEntity, QAfterFilterCondition> loopModeBetween(
    LoopMode lower,
    LoopMode upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'loopMode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<QueueEntity, QueueEntity, QAfterFilterCondition>
      profileIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'profileId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueueEntity, QueueEntity, QAfterFilterCondition>
      profileIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'profileId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueueEntity, QueueEntity, QAfterFilterCondition>
      profileIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'profileId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueueEntity, QueueEntity, QAfterFilterCondition>
      profileIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'profileId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueueEntity, QueueEntity, QAfterFilterCondition>
      profileIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'profileId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueueEntity, QueueEntity, QAfterFilterCondition>
      profileIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'profileId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueueEntity, QueueEntity, QAfterFilterCondition>
      profileIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'profileId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueueEntity, QueueEntity, QAfterFilterCondition>
      profileIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'profileId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QueueEntity, QueueEntity, QAfterFilterCondition>
      profileIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'profileId',
        value: '',
      ));
    });
  }

  QueryBuilder<QueueEntity, QueueEntity, QAfterFilterCondition>
      profileIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'profileId',
        value: '',
      ));
    });
  }

  QueryBuilder<QueueEntity, QueueEntity, QAfterFilterCondition> shuffledEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'shuffled',
        value: value,
      ));
    });
  }

  QueryBuilder<QueueEntity, QueueEntity, QAfterFilterCondition>
      trackIdsElementEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'trackIds',
        value: value,
      ));
    });
  }

  QueryBuilder<QueueEntity, QueueEntity, QAfterFilterCondition>
      trackIdsElementGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'trackIds',
        value: value,
      ));
    });
  }

  QueryBuilder<QueueEntity, QueueEntity, QAfterFilterCondition>
      trackIdsElementLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'trackIds',
        value: value,
      ));
    });
  }

  QueryBuilder<QueueEntity, QueueEntity, QAfterFilterCondition>
      trackIdsElementBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'trackIds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<QueueEntity, QueueEntity, QAfterFilterCondition>
      trackIdsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'trackIds',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<QueueEntity, QueueEntity, QAfterFilterCondition>
      trackIdsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'trackIds',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<QueueEntity, QueueEntity, QAfterFilterCondition>
      trackIdsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'trackIds',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<QueueEntity, QueueEntity, QAfterFilterCondition>
      trackIdsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'trackIds',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<QueueEntity, QueueEntity, QAfterFilterCondition>
      trackIdsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'trackIds',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<QueueEntity, QueueEntity, QAfterFilterCondition>
      trackIdsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'trackIds',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }
}

extension QueueEntityQueryObject
    on QueryBuilder<QueueEntity, QueueEntity, QFilterCondition> {}

extension QueueEntityQueryLinks
    on QueryBuilder<QueueEntity, QueueEntity, QFilterCondition> {}

extension QueueEntityQuerySortBy
    on QueryBuilder<QueueEntity, QueueEntity, QSortBy> {
  QueryBuilder<QueueEntity, QueueEntity, QAfterSortBy> sortByCurrentIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentIndex', Sort.asc);
    });
  }

  QueryBuilder<QueueEntity, QueueEntity, QAfterSortBy>
      sortByCurrentIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentIndex', Sort.desc);
    });
  }

  QueryBuilder<QueueEntity, QueueEntity, QAfterSortBy> sortByLoopMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'loopMode', Sort.asc);
    });
  }

  QueryBuilder<QueueEntity, QueueEntity, QAfterSortBy> sortByLoopModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'loopMode', Sort.desc);
    });
  }

  QueryBuilder<QueueEntity, QueueEntity, QAfterSortBy> sortByProfileId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profileId', Sort.asc);
    });
  }

  QueryBuilder<QueueEntity, QueueEntity, QAfterSortBy> sortByProfileIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profileId', Sort.desc);
    });
  }

  QueryBuilder<QueueEntity, QueueEntity, QAfterSortBy> sortByShuffled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shuffled', Sort.asc);
    });
  }

  QueryBuilder<QueueEntity, QueueEntity, QAfterSortBy> sortByShuffledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shuffled', Sort.desc);
    });
  }
}

extension QueueEntityQuerySortThenBy
    on QueryBuilder<QueueEntity, QueueEntity, QSortThenBy> {
  QueryBuilder<QueueEntity, QueueEntity, QAfterSortBy> thenByCurrentIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentIndex', Sort.asc);
    });
  }

  QueryBuilder<QueueEntity, QueueEntity, QAfterSortBy>
      thenByCurrentIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentIndex', Sort.desc);
    });
  }

  QueryBuilder<QueueEntity, QueueEntity, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<QueueEntity, QueueEntity, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<QueueEntity, QueueEntity, QAfterSortBy> thenByLoopMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'loopMode', Sort.asc);
    });
  }

  QueryBuilder<QueueEntity, QueueEntity, QAfterSortBy> thenByLoopModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'loopMode', Sort.desc);
    });
  }

  QueryBuilder<QueueEntity, QueueEntity, QAfterSortBy> thenByProfileId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profileId', Sort.asc);
    });
  }

  QueryBuilder<QueueEntity, QueueEntity, QAfterSortBy> thenByProfileIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profileId', Sort.desc);
    });
  }

  QueryBuilder<QueueEntity, QueueEntity, QAfterSortBy> thenByShuffled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shuffled', Sort.asc);
    });
  }

  QueryBuilder<QueueEntity, QueueEntity, QAfterSortBy> thenByShuffledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'shuffled', Sort.desc);
    });
  }
}

extension QueueEntityQueryWhereDistinct
    on QueryBuilder<QueueEntity, QueueEntity, QDistinct> {
  QueryBuilder<QueueEntity, QueueEntity, QDistinct> distinctByCurrentIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currentIndex');
    });
  }

  QueryBuilder<QueueEntity, QueueEntity, QDistinct> distinctByLoopMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'loopMode');
    });
  }

  QueryBuilder<QueueEntity, QueueEntity, QDistinct> distinctByProfileId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'profileId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<QueueEntity, QueueEntity, QDistinct> distinctByShuffled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'shuffled');
    });
  }

  QueryBuilder<QueueEntity, QueueEntity, QDistinct> distinctByTrackIds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'trackIds');
    });
  }
}

extension QueueEntityQueryProperty
    on QueryBuilder<QueueEntity, QueueEntity, QQueryProperty> {
  QueryBuilder<QueueEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<QueueEntity, int, QQueryOperations> currentIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currentIndex');
    });
  }

  QueryBuilder<QueueEntity, LoopMode, QQueryOperations> loopModeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'loopMode');
    });
  }

  QueryBuilder<QueueEntity, String, QQueryOperations> profileIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'profileId');
    });
  }

  QueryBuilder<QueueEntity, bool, QQueryOperations> shuffledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'shuffled');
    });
  }

  QueryBuilder<QueueEntity, List<int>, QQueryOperations> trackIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'trackIds');
    });
  }
}
