// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_entity.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetProfileEntityCollection on Isar {
  IsarCollection<ProfileEntity> get profileEntitys => this.collection();
}

const ProfileEntitySchema = CollectionSchema(
  name: r'ProfileEntity',
  id: 2239510315175863988,
  properties: {
    r'accentColorValue': PropertySchema(
      id: 0,
      name: r'accentColorValue',
      type: IsarType.long,
    ),
    r'avatarEmoji': PropertySchema(
      id: 1,
      name: r'avatarEmoji',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 2,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'favoriteSourceIds': PropertySchema(
      id: 3,
      name: r'favoriteSourceIds',
      type: IsarType.stringList,
    ),
    r'isActive': PropertySchema(
      id: 4,
      name: r'isActive',
      type: IsarType.bool,
    ),
    r'name': PropertySchema(
      id: 5,
      name: r'name',
      type: IsarType.string,
    )
  },
  estimateSize: _profileEntityEstimateSize,
  serialize: _profileEntitySerialize,
  deserialize: _profileEntityDeserialize,
  deserializeProp: _profileEntityDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _profileEntityGetId,
  getLinks: _profileEntityGetLinks,
  attach: _profileEntityAttach,
  version: '3.1.0+1',
);

int _profileEntityEstimateSize(
  ProfileEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.avatarEmoji.length * 3;
  bytesCount += 3 + object.favoriteSourceIds.length * 3;
  {
    for (var i = 0; i < object.favoriteSourceIds.length; i++) {
      final value = object.favoriteSourceIds[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.name.length * 3;
  return bytesCount;
}

void _profileEntitySerialize(
  ProfileEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.accentColorValue);
  writer.writeString(offsets[1], object.avatarEmoji);
  writer.writeDateTime(offsets[2], object.createdAt);
  writer.writeStringList(offsets[3], object.favoriteSourceIds);
  writer.writeBool(offsets[4], object.isActive);
  writer.writeString(offsets[5], object.name);
}

ProfileEntity _profileEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ProfileEntity();
  object.accentColorValue = reader.readLong(offsets[0]);
  object.avatarEmoji = reader.readString(offsets[1]);
  object.createdAt = reader.readDateTime(offsets[2]);
  object.favoriteSourceIds = reader.readStringList(offsets[3]) ?? [];
  object.id = id;
  object.isActive = reader.readBool(offsets[4]);
  object.name = reader.readString(offsets[5]);
  return object;
}

P _profileEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readStringList(offset) ?? []) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _profileEntityGetId(ProfileEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _profileEntityGetLinks(ProfileEntity object) {
  return [];
}

void _profileEntityAttach(
    IsarCollection<dynamic> col, Id id, ProfileEntity object) {
  object.id = id;
}

extension ProfileEntityQueryWhereSort
    on QueryBuilder<ProfileEntity, ProfileEntity, QWhere> {
  QueryBuilder<ProfileEntity, ProfileEntity, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ProfileEntityQueryWhere
    on QueryBuilder<ProfileEntity, ProfileEntity, QWhereClause> {
  QueryBuilder<ProfileEntity, ProfileEntity, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterWhereClause> idBetween(
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
}

extension ProfileEntityQueryFilter
    on QueryBuilder<ProfileEntity, ProfileEntity, QFilterCondition> {
  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
      accentColorValueEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'accentColorValue',
        value: value,
      ));
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
      accentColorValueGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'accentColorValue',
        value: value,
      ));
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
      accentColorValueLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'accentColorValue',
        value: value,
      ));
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
      accentColorValueBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'accentColorValue',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
      avatarEmojiEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'avatarEmoji',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
      avatarEmojiGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'avatarEmoji',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
      avatarEmojiLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'avatarEmoji',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
      avatarEmojiBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'avatarEmoji',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
      avatarEmojiStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'avatarEmoji',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
      avatarEmojiEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'avatarEmoji',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
      avatarEmojiContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'avatarEmoji',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
      avatarEmojiMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'avatarEmoji',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
      avatarEmojiIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'avatarEmoji',
        value: '',
      ));
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
      avatarEmojiIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'avatarEmoji',
        value: '',
      ));
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
      createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
      createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
      favoriteSourceIdsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'favoriteSourceIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
      favoriteSourceIdsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'favoriteSourceIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
      favoriteSourceIdsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'favoriteSourceIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
      favoriteSourceIdsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'favoriteSourceIds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
      favoriteSourceIdsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'favoriteSourceIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
      favoriteSourceIdsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'favoriteSourceIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
      favoriteSourceIdsElementContains(String value,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'favoriteSourceIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
      favoriteSourceIdsElementMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'favoriteSourceIds',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
      favoriteSourceIdsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'favoriteSourceIds',
        value: '',
      ));
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
      favoriteSourceIdsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'favoriteSourceIds',
        value: '',
      ));
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
      favoriteSourceIdsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'favoriteSourceIds',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
      favoriteSourceIdsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'favoriteSourceIds',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
      favoriteSourceIdsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'favoriteSourceIds',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
      favoriteSourceIdsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'favoriteSourceIds',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
      favoriteSourceIdsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'favoriteSourceIds',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
      favoriteSourceIdsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'favoriteSourceIds',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition> idBetween(
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

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
      isActiveEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isActive',
        value: value,
      ));
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
      nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
      nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
      nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
      nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
      nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition> nameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
      nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }
}

extension ProfileEntityQueryObject
    on QueryBuilder<ProfileEntity, ProfileEntity, QFilterCondition> {}

extension ProfileEntityQueryLinks
    on QueryBuilder<ProfileEntity, ProfileEntity, QFilterCondition> {}

extension ProfileEntityQuerySortBy
    on QueryBuilder<ProfileEntity, ProfileEntity, QSortBy> {
  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy>
      sortByAccentColorValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accentColorValue', Sort.asc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy>
      sortByAccentColorValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accentColorValue', Sort.desc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy> sortByAvatarEmoji() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avatarEmoji', Sort.asc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy>
      sortByAvatarEmojiDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avatarEmoji', Sort.desc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy> sortByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.asc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy>
      sortByIsActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.desc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }
}

extension ProfileEntityQuerySortThenBy
    on QueryBuilder<ProfileEntity, ProfileEntity, QSortThenBy> {
  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy>
      thenByAccentColorValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accentColorValue', Sort.asc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy>
      thenByAccentColorValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accentColorValue', Sort.desc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy> thenByAvatarEmoji() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avatarEmoji', Sort.asc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy>
      thenByAvatarEmojiDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avatarEmoji', Sort.desc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy> thenByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.asc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy>
      thenByIsActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.desc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }
}

extension ProfileEntityQueryWhereDistinct
    on QueryBuilder<ProfileEntity, ProfileEntity, QDistinct> {
  QueryBuilder<ProfileEntity, ProfileEntity, QDistinct>
      distinctByAccentColorValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'accentColorValue');
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QDistinct> distinctByAvatarEmoji(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'avatarEmoji', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QDistinct>
      distinctByFavoriteSourceIds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'favoriteSourceIds');
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QDistinct> distinctByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isActive');
    });
  }

  QueryBuilder<ProfileEntity, ProfileEntity, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }
}

extension ProfileEntityQueryProperty
    on QueryBuilder<ProfileEntity, ProfileEntity, QQueryProperty> {
  QueryBuilder<ProfileEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ProfileEntity, int, QQueryOperations>
      accentColorValueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'accentColorValue');
    });
  }

  QueryBuilder<ProfileEntity, String, QQueryOperations> avatarEmojiProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'avatarEmoji');
    });
  }

  QueryBuilder<ProfileEntity, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<ProfileEntity, List<String>, QQueryOperations>
      favoriteSourceIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'favoriteSourceIds');
    });
  }

  QueryBuilder<ProfileEntity, bool, QQueryOperations> isActiveProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isActive');
    });
  }

  QueryBuilder<ProfileEntity, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }
}
