// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'activity_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ActivityModel {

 String get id; String get type;// 'task_moved' | 'task_created' | 'task_completed' | 'comment_added' | 'member_joined'
 String get actorId; String? get taskId; String get spaceId; String get message; Map<String, List<String>> get reactions;// emoji → [userIds]
 DateTime get createdAt;
/// Create a copy of ActivityModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActivityModelCopyWith<ActivityModel> get copyWith => _$ActivityModelCopyWithImpl<ActivityModel>(this as ActivityModel, _$identity);

  /// Serializes this ActivityModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActivityModel&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.actorId, actorId) || other.actorId == actorId)&&(identical(other.taskId, taskId) || other.taskId == taskId)&&(identical(other.spaceId, spaceId) || other.spaceId == spaceId)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other.reactions, reactions)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,actorId,taskId,spaceId,message,const DeepCollectionEquality().hash(reactions),createdAt);

@override
String toString() {
  return 'ActivityModel(id: $id, type: $type, actorId: $actorId, taskId: $taskId, spaceId: $spaceId, message: $message, reactions: $reactions, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $ActivityModelCopyWith<$Res>  {
  factory $ActivityModelCopyWith(ActivityModel value, $Res Function(ActivityModel) _then) = _$ActivityModelCopyWithImpl;
@useResult
$Res call({
 String id, String type, String actorId, String? taskId, String spaceId, String message, Map<String, List<String>> reactions, DateTime createdAt
});




}
/// @nodoc
class _$ActivityModelCopyWithImpl<$Res>
    implements $ActivityModelCopyWith<$Res> {
  _$ActivityModelCopyWithImpl(this._self, this._then);

  final ActivityModel _self;
  final $Res Function(ActivityModel) _then;

/// Create a copy of ActivityModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? actorId = null,Object? taskId = freezed,Object? spaceId = null,Object? message = null,Object? reactions = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,actorId: null == actorId ? _self.actorId : actorId // ignore: cast_nullable_to_non_nullable
as String,taskId: freezed == taskId ? _self.taskId : taskId // ignore: cast_nullable_to_non_nullable
as String?,spaceId: null == spaceId ? _self.spaceId : spaceId // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,reactions: null == reactions ? _self.reactions : reactions // ignore: cast_nullable_to_non_nullable
as Map<String, List<String>>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ActivityModel].
extension ActivityModelPatterns on ActivityModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ActivityModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ActivityModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ActivityModel value)  $default,){
final _that = this;
switch (_that) {
case _ActivityModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ActivityModel value)?  $default,){
final _that = this;
switch (_that) {
case _ActivityModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String type,  String actorId,  String? taskId,  String spaceId,  String message,  Map<String, List<String>> reactions,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ActivityModel() when $default != null:
return $default(_that.id,_that.type,_that.actorId,_that.taskId,_that.spaceId,_that.message,_that.reactions,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String type,  String actorId,  String? taskId,  String spaceId,  String message,  Map<String, List<String>> reactions,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _ActivityModel():
return $default(_that.id,_that.type,_that.actorId,_that.taskId,_that.spaceId,_that.message,_that.reactions,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String type,  String actorId,  String? taskId,  String spaceId,  String message,  Map<String, List<String>> reactions,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _ActivityModel() when $default != null:
return $default(_that.id,_that.type,_that.actorId,_that.taskId,_that.spaceId,_that.message,_that.reactions,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ActivityModel implements ActivityModel {
  const _ActivityModel({required this.id, required this.type, required this.actorId, this.taskId, required this.spaceId, required this.message, final  Map<String, List<String>> reactions = const {}, required this.createdAt}): _reactions = reactions;
  factory _ActivityModel.fromJson(Map<String, dynamic> json) => _$ActivityModelFromJson(json);

@override final  String id;
@override final  String type;
// 'task_moved' | 'task_created' | 'task_completed' | 'comment_added' | 'member_joined'
@override final  String actorId;
@override final  String? taskId;
@override final  String spaceId;
@override final  String message;
 final  Map<String, List<String>> _reactions;
@override@JsonKey() Map<String, List<String>> get reactions {
  if (_reactions is EqualUnmodifiableMapView) return _reactions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_reactions);
}

// emoji → [userIds]
@override final  DateTime createdAt;

/// Create a copy of ActivityModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActivityModelCopyWith<_ActivityModel> get copyWith => __$ActivityModelCopyWithImpl<_ActivityModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ActivityModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ActivityModel&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.actorId, actorId) || other.actorId == actorId)&&(identical(other.taskId, taskId) || other.taskId == taskId)&&(identical(other.spaceId, spaceId) || other.spaceId == spaceId)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other._reactions, _reactions)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,actorId,taskId,spaceId,message,const DeepCollectionEquality().hash(_reactions),createdAt);

@override
String toString() {
  return 'ActivityModel(id: $id, type: $type, actorId: $actorId, taskId: $taskId, spaceId: $spaceId, message: $message, reactions: $reactions, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$ActivityModelCopyWith<$Res> implements $ActivityModelCopyWith<$Res> {
  factory _$ActivityModelCopyWith(_ActivityModel value, $Res Function(_ActivityModel) _then) = __$ActivityModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String type, String actorId, String? taskId, String spaceId, String message, Map<String, List<String>> reactions, DateTime createdAt
});




}
/// @nodoc
class __$ActivityModelCopyWithImpl<$Res>
    implements _$ActivityModelCopyWith<$Res> {
  __$ActivityModelCopyWithImpl(this._self, this._then);

  final _ActivityModel _self;
  final $Res Function(_ActivityModel) _then;

/// Create a copy of ActivityModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? actorId = null,Object? taskId = freezed,Object? spaceId = null,Object? message = null,Object? reactions = null,Object? createdAt = null,}) {
  return _then(_ActivityModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,actorId: null == actorId ? _self.actorId : actorId // ignore: cast_nullable_to_non_nullable
as String,taskId: freezed == taskId ? _self.taskId : taskId // ignore: cast_nullable_to_non_nullable
as String?,spaceId: null == spaceId ? _self.spaceId : spaceId // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,reactions: null == reactions ? _self._reactions : reactions // ignore: cast_nullable_to_non_nullable
as Map<String, List<String>>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
