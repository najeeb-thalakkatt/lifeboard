// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'space_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SpaceMember {

 String get role;// 'owner' | 'member'
 DateTime get joinedAt;
/// Create a copy of SpaceMember
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SpaceMemberCopyWith<SpaceMember> get copyWith => _$SpaceMemberCopyWithImpl<SpaceMember>(this as SpaceMember, _$identity);

  /// Serializes this SpaceMember to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SpaceMember&&(identical(other.role, role) || other.role == role)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,role,joinedAt);

@override
String toString() {
  return 'SpaceMember(role: $role, joinedAt: $joinedAt)';
}


}

/// @nodoc
abstract mixin class $SpaceMemberCopyWith<$Res>  {
  factory $SpaceMemberCopyWith(SpaceMember value, $Res Function(SpaceMember) _then) = _$SpaceMemberCopyWithImpl;
@useResult
$Res call({
 String role, DateTime joinedAt
});




}
/// @nodoc
class _$SpaceMemberCopyWithImpl<$Res>
    implements $SpaceMemberCopyWith<$Res> {
  _$SpaceMemberCopyWithImpl(this._self, this._then);

  final SpaceMember _self;
  final $Res Function(SpaceMember) _then;

/// Create a copy of SpaceMember
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? role = null,Object? joinedAt = null,}) {
  return _then(_self.copyWith(
role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [SpaceMember].
extension SpaceMemberPatterns on SpaceMember {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SpaceMember value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SpaceMember() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SpaceMember value)  $default,){
final _that = this;
switch (_that) {
case _SpaceMember():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SpaceMember value)?  $default,){
final _that = this;
switch (_that) {
case _SpaceMember() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String role,  DateTime joinedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SpaceMember() when $default != null:
return $default(_that.role,_that.joinedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String role,  DateTime joinedAt)  $default,) {final _that = this;
switch (_that) {
case _SpaceMember():
return $default(_that.role,_that.joinedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String role,  DateTime joinedAt)?  $default,) {final _that = this;
switch (_that) {
case _SpaceMember() when $default != null:
return $default(_that.role,_that.joinedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SpaceMember implements SpaceMember {
  const _SpaceMember({required this.role, required this.joinedAt});
  factory _SpaceMember.fromJson(Map<String, dynamic> json) => _$SpaceMemberFromJson(json);

@override final  String role;
// 'owner' | 'member'
@override final  DateTime joinedAt;

/// Create a copy of SpaceMember
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SpaceMemberCopyWith<_SpaceMember> get copyWith => __$SpaceMemberCopyWithImpl<_SpaceMember>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SpaceMemberToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SpaceMember&&(identical(other.role, role) || other.role == role)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,role,joinedAt);

@override
String toString() {
  return 'SpaceMember(role: $role, joinedAt: $joinedAt)';
}


}

/// @nodoc
abstract mixin class _$SpaceMemberCopyWith<$Res> implements $SpaceMemberCopyWith<$Res> {
  factory _$SpaceMemberCopyWith(_SpaceMember value, $Res Function(_SpaceMember) _then) = __$SpaceMemberCopyWithImpl;
@override @useResult
$Res call({
 String role, DateTime joinedAt
});




}
/// @nodoc
class __$SpaceMemberCopyWithImpl<$Res>
    implements _$SpaceMemberCopyWith<$Res> {
  __$SpaceMemberCopyWithImpl(this._self, this._then);

  final _SpaceMember _self;
  final $Res Function(_SpaceMember) _then;

/// Create a copy of SpaceMember
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? role = null,Object? joinedAt = null,}) {
  return _then(_SpaceMember(
role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$SpaceModel {

 String get id; String get name; Map<String, SpaceMember> get members; String get inviteCode; List<String> get themes; DateTime get createdAt;
/// Create a copy of SpaceModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SpaceModelCopyWith<SpaceModel> get copyWith => _$SpaceModelCopyWithImpl<SpaceModel>(this as SpaceModel, _$identity);

  /// Serializes this SpaceModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SpaceModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.members, members)&&(identical(other.inviteCode, inviteCode) || other.inviteCode == inviteCode)&&const DeepCollectionEquality().equals(other.themes, themes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(members),inviteCode,const DeepCollectionEquality().hash(themes),createdAt);

@override
String toString() {
  return 'SpaceModel(id: $id, name: $name, members: $members, inviteCode: $inviteCode, themes: $themes, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $SpaceModelCopyWith<$Res>  {
  factory $SpaceModelCopyWith(SpaceModel value, $Res Function(SpaceModel) _then) = _$SpaceModelCopyWithImpl;
@useResult
$Res call({
 String id, String name, Map<String, SpaceMember> members, String inviteCode, List<String> themes, DateTime createdAt
});




}
/// @nodoc
class _$SpaceModelCopyWithImpl<$Res>
    implements $SpaceModelCopyWith<$Res> {
  _$SpaceModelCopyWithImpl(this._self, this._then);

  final SpaceModel _self;
  final $Res Function(SpaceModel) _then;

/// Create a copy of SpaceModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? members = null,Object? inviteCode = null,Object? themes = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,members: null == members ? _self.members : members // ignore: cast_nullable_to_non_nullable
as Map<String, SpaceMember>,inviteCode: null == inviteCode ? _self.inviteCode : inviteCode // ignore: cast_nullable_to_non_nullable
as String,themes: null == themes ? _self.themes : themes // ignore: cast_nullable_to_non_nullable
as List<String>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [SpaceModel].
extension SpaceModelPatterns on SpaceModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SpaceModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SpaceModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SpaceModel value)  $default,){
final _that = this;
switch (_that) {
case _SpaceModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SpaceModel value)?  $default,){
final _that = this;
switch (_that) {
case _SpaceModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  Map<String, SpaceMember> members,  String inviteCode,  List<String> themes,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SpaceModel() when $default != null:
return $default(_that.id,_that.name,_that.members,_that.inviteCode,_that.themes,_that.createdAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  Map<String, SpaceMember> members,  String inviteCode,  List<String> themes,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _SpaceModel():
return $default(_that.id,_that.name,_that.members,_that.inviteCode,_that.themes,_that.createdAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  Map<String, SpaceMember> members,  String inviteCode,  List<String> themes,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _SpaceModel() when $default != null:
return $default(_that.id,_that.name,_that.members,_that.inviteCode,_that.themes,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SpaceModel implements SpaceModel {
  const _SpaceModel({required this.id, required this.name, required final  Map<String, SpaceMember> members, required this.inviteCode, final  List<String> themes = const [], required this.createdAt}): _members = members,_themes = themes;
  factory _SpaceModel.fromJson(Map<String, dynamic> json) => _$SpaceModelFromJson(json);

@override final  String id;
@override final  String name;
 final  Map<String, SpaceMember> _members;
@override Map<String, SpaceMember> get members {
  if (_members is EqualUnmodifiableMapView) return _members;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_members);
}

@override final  String inviteCode;
 final  List<String> _themes;
@override@JsonKey() List<String> get themes {
  if (_themes is EqualUnmodifiableListView) return _themes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_themes);
}

@override final  DateTime createdAt;

/// Create a copy of SpaceModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SpaceModelCopyWith<_SpaceModel> get copyWith => __$SpaceModelCopyWithImpl<_SpaceModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SpaceModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SpaceModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._members, _members)&&(identical(other.inviteCode, inviteCode) || other.inviteCode == inviteCode)&&const DeepCollectionEquality().equals(other._themes, _themes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(_members),inviteCode,const DeepCollectionEquality().hash(_themes),createdAt);

@override
String toString() {
  return 'SpaceModel(id: $id, name: $name, members: $members, inviteCode: $inviteCode, themes: $themes, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$SpaceModelCopyWith<$Res> implements $SpaceModelCopyWith<$Res> {
  factory _$SpaceModelCopyWith(_SpaceModel value, $Res Function(_SpaceModel) _then) = __$SpaceModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, Map<String, SpaceMember> members, String inviteCode, List<String> themes, DateTime createdAt
});




}
/// @nodoc
class __$SpaceModelCopyWithImpl<$Res>
    implements _$SpaceModelCopyWith<$Res> {
  __$SpaceModelCopyWithImpl(this._self, this._then);

  final _SpaceModel _self;
  final $Res Function(_SpaceModel) _then;

/// Create a copy of SpaceModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? members = null,Object? inviteCode = null,Object? themes = null,Object? createdAt = null,}) {
  return _then(_SpaceModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,members: null == members ? _self._members : members // ignore: cast_nullable_to_non_nullable
as Map<String, SpaceMember>,inviteCode: null == inviteCode ? _self.inviteCode : inviteCode // ignore: cast_nullable_to_non_nullable
as String,themes: null == themes ? _self._themes : themes // ignore: cast_nullable_to_non_nullable
as List<String>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
