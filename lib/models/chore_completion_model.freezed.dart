// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chore_completion_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChoreCompletion {

 String get id; String get choreId;/// Denormalized for activity feed display.
 String get choreName; String get choreEmoji; String get completedBy; DateTime get completedAt;/// YYYY-MM-DD string for querying completions by date.
 String get date;/// UserId who acknowledged ("hat-tipped") this completion.
 String? get hatTipBy;
/// Create a copy of ChoreCompletion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChoreCompletionCopyWith<ChoreCompletion> get copyWith => _$ChoreCompletionCopyWithImpl<ChoreCompletion>(this as ChoreCompletion, _$identity);

  /// Serializes this ChoreCompletion to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChoreCompletion&&(identical(other.id, id) || other.id == id)&&(identical(other.choreId, choreId) || other.choreId == choreId)&&(identical(other.choreName, choreName) || other.choreName == choreName)&&(identical(other.choreEmoji, choreEmoji) || other.choreEmoji == choreEmoji)&&(identical(other.completedBy, completedBy) || other.completedBy == completedBy)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.date, date) || other.date == date)&&(identical(other.hatTipBy, hatTipBy) || other.hatTipBy == hatTipBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,choreId,choreName,choreEmoji,completedBy,completedAt,date,hatTipBy);

@override
String toString() {
  return 'ChoreCompletion(id: $id, choreId: $choreId, choreName: $choreName, choreEmoji: $choreEmoji, completedBy: $completedBy, completedAt: $completedAt, date: $date, hatTipBy: $hatTipBy)';
}


}

/// @nodoc
abstract mixin class $ChoreCompletionCopyWith<$Res>  {
  factory $ChoreCompletionCopyWith(ChoreCompletion value, $Res Function(ChoreCompletion) _then) = _$ChoreCompletionCopyWithImpl;
@useResult
$Res call({
 String id, String choreId, String choreName, String choreEmoji, String completedBy, DateTime completedAt, String date, String? hatTipBy
});




}
/// @nodoc
class _$ChoreCompletionCopyWithImpl<$Res>
    implements $ChoreCompletionCopyWith<$Res> {
  _$ChoreCompletionCopyWithImpl(this._self, this._then);

  final ChoreCompletion _self;
  final $Res Function(ChoreCompletion) _then;

/// Create a copy of ChoreCompletion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? choreId = null,Object? choreName = null,Object? choreEmoji = null,Object? completedBy = null,Object? completedAt = null,Object? date = null,Object? hatTipBy = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,choreId: null == choreId ? _self.choreId : choreId // ignore: cast_nullable_to_non_nullable
as String,choreName: null == choreName ? _self.choreName : choreName // ignore: cast_nullable_to_non_nullable
as String,choreEmoji: null == choreEmoji ? _self.choreEmoji : choreEmoji // ignore: cast_nullable_to_non_nullable
as String,completedBy: null == completedBy ? _self.completedBy : completedBy // ignore: cast_nullable_to_non_nullable
as String,completedAt: null == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,hatTipBy: freezed == hatTipBy ? _self.hatTipBy : hatTipBy // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ChoreCompletion].
extension ChoreCompletionPatterns on ChoreCompletion {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChoreCompletion value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChoreCompletion() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChoreCompletion value)  $default,){
final _that = this;
switch (_that) {
case _ChoreCompletion():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChoreCompletion value)?  $default,){
final _that = this;
switch (_that) {
case _ChoreCompletion() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String choreId,  String choreName,  String choreEmoji,  String completedBy,  DateTime completedAt,  String date,  String? hatTipBy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChoreCompletion() when $default != null:
return $default(_that.id,_that.choreId,_that.choreName,_that.choreEmoji,_that.completedBy,_that.completedAt,_that.date,_that.hatTipBy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String choreId,  String choreName,  String choreEmoji,  String completedBy,  DateTime completedAt,  String date,  String? hatTipBy)  $default,) {final _that = this;
switch (_that) {
case _ChoreCompletion():
return $default(_that.id,_that.choreId,_that.choreName,_that.choreEmoji,_that.completedBy,_that.completedAt,_that.date,_that.hatTipBy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String choreId,  String choreName,  String choreEmoji,  String completedBy,  DateTime completedAt,  String date,  String? hatTipBy)?  $default,) {final _that = this;
switch (_that) {
case _ChoreCompletion() when $default != null:
return $default(_that.id,_that.choreId,_that.choreName,_that.choreEmoji,_that.completedBy,_that.completedAt,_that.date,_that.hatTipBy);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChoreCompletion implements ChoreCompletion {
  const _ChoreCompletion({required this.id, required this.choreId, required this.choreName, required this.choreEmoji, required this.completedBy, required this.completedAt, required this.date, this.hatTipBy});
  factory _ChoreCompletion.fromJson(Map<String, dynamic> json) => _$ChoreCompletionFromJson(json);

@override final  String id;
@override final  String choreId;
/// Denormalized for activity feed display.
@override final  String choreName;
@override final  String choreEmoji;
@override final  String completedBy;
@override final  DateTime completedAt;
/// YYYY-MM-DD string for querying completions by date.
@override final  String date;
/// UserId who acknowledged ("hat-tipped") this completion.
@override final  String? hatTipBy;

/// Create a copy of ChoreCompletion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChoreCompletionCopyWith<_ChoreCompletion> get copyWith => __$ChoreCompletionCopyWithImpl<_ChoreCompletion>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChoreCompletionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChoreCompletion&&(identical(other.id, id) || other.id == id)&&(identical(other.choreId, choreId) || other.choreId == choreId)&&(identical(other.choreName, choreName) || other.choreName == choreName)&&(identical(other.choreEmoji, choreEmoji) || other.choreEmoji == choreEmoji)&&(identical(other.completedBy, completedBy) || other.completedBy == completedBy)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.date, date) || other.date == date)&&(identical(other.hatTipBy, hatTipBy) || other.hatTipBy == hatTipBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,choreId,choreName,choreEmoji,completedBy,completedAt,date,hatTipBy);

@override
String toString() {
  return 'ChoreCompletion(id: $id, choreId: $choreId, choreName: $choreName, choreEmoji: $choreEmoji, completedBy: $completedBy, completedAt: $completedAt, date: $date, hatTipBy: $hatTipBy)';
}


}

/// @nodoc
abstract mixin class _$ChoreCompletionCopyWith<$Res> implements $ChoreCompletionCopyWith<$Res> {
  factory _$ChoreCompletionCopyWith(_ChoreCompletion value, $Res Function(_ChoreCompletion) _then) = __$ChoreCompletionCopyWithImpl;
@override @useResult
$Res call({
 String id, String choreId, String choreName, String choreEmoji, String completedBy, DateTime completedAt, String date, String? hatTipBy
});




}
/// @nodoc
class __$ChoreCompletionCopyWithImpl<$Res>
    implements _$ChoreCompletionCopyWith<$Res> {
  __$ChoreCompletionCopyWithImpl(this._self, this._then);

  final _ChoreCompletion _self;
  final $Res Function(_ChoreCompletion) _then;

/// Create a copy of ChoreCompletion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? choreId = null,Object? choreName = null,Object? choreEmoji = null,Object? completedBy = null,Object? completedAt = null,Object? date = null,Object? hatTipBy = freezed,}) {
  return _then(_ChoreCompletion(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,choreId: null == choreId ? _self.choreId : choreId // ignore: cast_nullable_to_non_nullable
as String,choreName: null == choreName ? _self.choreName : choreName // ignore: cast_nullable_to_non_nullable
as String,choreEmoji: null == choreEmoji ? _self.choreEmoji : choreEmoji // ignore: cast_nullable_to_non_nullable
as String,completedBy: null == completedBy ? _self.completedBy : completedBy // ignore: cast_nullable_to_non_nullable
as String,completedAt: null == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,hatTipBy: freezed == hatTipBy ? _self.hatTipBy : hatTipBy // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
