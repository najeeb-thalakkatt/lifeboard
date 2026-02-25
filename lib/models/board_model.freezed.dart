// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'board_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BoardModel {

 String get id; String get name; String get theme; List<String> get columns; String get createdBy; DateTime get createdAt;
/// Create a copy of BoardModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BoardModelCopyWith<BoardModel> get copyWith => _$BoardModelCopyWithImpl<BoardModel>(this as BoardModel, _$identity);

  /// Serializes this BoardModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BoardModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.theme, theme) || other.theme == theme)&&const DeepCollectionEquality().equals(other.columns, columns)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,theme,const DeepCollectionEquality().hash(columns),createdBy,createdAt);

@override
String toString() {
  return 'BoardModel(id: $id, name: $name, theme: $theme, columns: $columns, createdBy: $createdBy, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $BoardModelCopyWith<$Res>  {
  factory $BoardModelCopyWith(BoardModel value, $Res Function(BoardModel) _then) = _$BoardModelCopyWithImpl;
@useResult
$Res call({
 String id, String name, String theme, List<String> columns, String createdBy, DateTime createdAt
});




}
/// @nodoc
class _$BoardModelCopyWithImpl<$Res>
    implements $BoardModelCopyWith<$Res> {
  _$BoardModelCopyWithImpl(this._self, this._then);

  final BoardModel _self;
  final $Res Function(BoardModel) _then;

/// Create a copy of BoardModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? theme = null,Object? columns = null,Object? createdBy = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,theme: null == theme ? _self.theme : theme // ignore: cast_nullable_to_non_nullable
as String,columns: null == columns ? _self.columns : columns // ignore: cast_nullable_to_non_nullable
as List<String>,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [BoardModel].
extension BoardModelPatterns on BoardModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BoardModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BoardModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BoardModel value)  $default,){
final _that = this;
switch (_that) {
case _BoardModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BoardModel value)?  $default,){
final _that = this;
switch (_that) {
case _BoardModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String theme,  List<String> columns,  String createdBy,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BoardModel() when $default != null:
return $default(_that.id,_that.name,_that.theme,_that.columns,_that.createdBy,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String theme,  List<String> columns,  String createdBy,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _BoardModel():
return $default(_that.id,_that.name,_that.theme,_that.columns,_that.createdBy,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String theme,  List<String> columns,  String createdBy,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _BoardModel() when $default != null:
return $default(_that.id,_that.name,_that.theme,_that.columns,_that.createdBy,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BoardModel implements BoardModel {
  const _BoardModel({required this.id, required this.name, this.theme = '', final  List<String> columns = const ['todo', 'in_progress', 'done'], required this.createdBy, required this.createdAt}): _columns = columns;
  factory _BoardModel.fromJson(Map<String, dynamic> json) => _$BoardModelFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey() final  String theme;
 final  List<String> _columns;
@override@JsonKey() List<String> get columns {
  if (_columns is EqualUnmodifiableListView) return _columns;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_columns);
}

@override final  String createdBy;
@override final  DateTime createdAt;

/// Create a copy of BoardModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BoardModelCopyWith<_BoardModel> get copyWith => __$BoardModelCopyWithImpl<_BoardModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BoardModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BoardModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.theme, theme) || other.theme == theme)&&const DeepCollectionEquality().equals(other._columns, _columns)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,theme,const DeepCollectionEquality().hash(_columns),createdBy,createdAt);

@override
String toString() {
  return 'BoardModel(id: $id, name: $name, theme: $theme, columns: $columns, createdBy: $createdBy, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$BoardModelCopyWith<$Res> implements $BoardModelCopyWith<$Res> {
  factory _$BoardModelCopyWith(_BoardModel value, $Res Function(_BoardModel) _then) = __$BoardModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String theme, List<String> columns, String createdBy, DateTime createdAt
});




}
/// @nodoc
class __$BoardModelCopyWithImpl<$Res>
    implements _$BoardModelCopyWith<$Res> {
  __$BoardModelCopyWithImpl(this._self, this._then);

  final _BoardModel _self;
  final $Res Function(_BoardModel) _then;

/// Create a copy of BoardModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? theme = null,Object? columns = null,Object? createdBy = null,Object? createdAt = null,}) {
  return _then(_BoardModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,theme: null == theme ? _self.theme : theme // ignore: cast_nullable_to_non_nullable
as String,columns: null == columns ? _self._columns : columns // ignore: cast_nullable_to_non_nullable
as List<String>,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
