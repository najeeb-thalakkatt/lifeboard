// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chore_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Chore {

 String get id; String get name; String get emoji;// ── Recurrence ────────────────────────────────────────────
/// "one_off" | "daily" | "every_n_days" | "weekly" | "biweekly" | "monthly"
 String get recurrenceType;/// Interval for "every_n_days" (e.g. 3 = every 3 days).
 int get recurrenceInterval;/// Days of week for "weekly" recurrence (1=Mon..7=Sun).
 List<int> get recurrenceDaysOfWeek;/// Day of month for "monthly" recurrence.
 int get recurrenceDayOfMonth;/// "fixed" = next due from schedule, "floating" = next due from completion.
 String get recurrenceMode;// ── Assignment & Status ───────────────────────────────────
/// Null means "anyone can claim it".
 String? get assigneeId;/// When the chore is next due.
 DateTime get nextDueDate;/// When the chore was last completed.
 DateTime? get lastCompletedAt;/// Who last completed this chore.
 String? get lastCompletedBy;/// "now" | "regular" | "whenever"
 String get priority;// ── Metadata ──────────────────────────────────────────────
 String get createdBy; DateTime get createdAt; int get order;/// Whether the chore is archived (e.g. completed one-off chores).
 bool get isArchived;
/// Create a copy of Chore
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChoreCopyWith<Chore> get copyWith => _$ChoreCopyWithImpl<Chore>(this as Chore, _$identity);

  /// Serializes this Chore to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Chore&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.emoji, emoji) || other.emoji == emoji)&&(identical(other.recurrenceType, recurrenceType) || other.recurrenceType == recurrenceType)&&(identical(other.recurrenceInterval, recurrenceInterval) || other.recurrenceInterval == recurrenceInterval)&&const DeepCollectionEquality().equals(other.recurrenceDaysOfWeek, recurrenceDaysOfWeek)&&(identical(other.recurrenceDayOfMonth, recurrenceDayOfMonth) || other.recurrenceDayOfMonth == recurrenceDayOfMonth)&&(identical(other.recurrenceMode, recurrenceMode) || other.recurrenceMode == recurrenceMode)&&(identical(other.assigneeId, assigneeId) || other.assigneeId == assigneeId)&&(identical(other.nextDueDate, nextDueDate) || other.nextDueDate == nextDueDate)&&(identical(other.lastCompletedAt, lastCompletedAt) || other.lastCompletedAt == lastCompletedAt)&&(identical(other.lastCompletedBy, lastCompletedBy) || other.lastCompletedBy == lastCompletedBy)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.order, order) || other.order == order)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,emoji,recurrenceType,recurrenceInterval,const DeepCollectionEquality().hash(recurrenceDaysOfWeek),recurrenceDayOfMonth,recurrenceMode,assigneeId,nextDueDate,lastCompletedAt,lastCompletedBy,priority,createdBy,createdAt,order,isArchived);

@override
String toString() {
  return 'Chore(id: $id, name: $name, emoji: $emoji, recurrenceType: $recurrenceType, recurrenceInterval: $recurrenceInterval, recurrenceDaysOfWeek: $recurrenceDaysOfWeek, recurrenceDayOfMonth: $recurrenceDayOfMonth, recurrenceMode: $recurrenceMode, assigneeId: $assigneeId, nextDueDate: $nextDueDate, lastCompletedAt: $lastCompletedAt, lastCompletedBy: $lastCompletedBy, priority: $priority, createdBy: $createdBy, createdAt: $createdAt, order: $order, isArchived: $isArchived)';
}


}

/// @nodoc
abstract mixin class $ChoreCopyWith<$Res>  {
  factory $ChoreCopyWith(Chore value, $Res Function(Chore) _then) = _$ChoreCopyWithImpl;
@useResult
$Res call({
 String id, String name, String emoji, String recurrenceType, int recurrenceInterval, List<int> recurrenceDaysOfWeek, int recurrenceDayOfMonth, String recurrenceMode, String? assigneeId, DateTime nextDueDate, DateTime? lastCompletedAt, String? lastCompletedBy, String priority, String createdBy, DateTime createdAt, int order, bool isArchived
});




}
/// @nodoc
class _$ChoreCopyWithImpl<$Res>
    implements $ChoreCopyWith<$Res> {
  _$ChoreCopyWithImpl(this._self, this._then);

  final Chore _self;
  final $Res Function(Chore) _then;

/// Create a copy of Chore
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? emoji = null,Object? recurrenceType = null,Object? recurrenceInterval = null,Object? recurrenceDaysOfWeek = null,Object? recurrenceDayOfMonth = null,Object? recurrenceMode = null,Object? assigneeId = freezed,Object? nextDueDate = null,Object? lastCompletedAt = freezed,Object? lastCompletedBy = freezed,Object? priority = null,Object? createdBy = null,Object? createdAt = null,Object? order = null,Object? isArchived = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,emoji: null == emoji ? _self.emoji : emoji // ignore: cast_nullable_to_non_nullable
as String,recurrenceType: null == recurrenceType ? _self.recurrenceType : recurrenceType // ignore: cast_nullable_to_non_nullable
as String,recurrenceInterval: null == recurrenceInterval ? _self.recurrenceInterval : recurrenceInterval // ignore: cast_nullable_to_non_nullable
as int,recurrenceDaysOfWeek: null == recurrenceDaysOfWeek ? _self.recurrenceDaysOfWeek : recurrenceDaysOfWeek // ignore: cast_nullable_to_non_nullable
as List<int>,recurrenceDayOfMonth: null == recurrenceDayOfMonth ? _self.recurrenceDayOfMonth : recurrenceDayOfMonth // ignore: cast_nullable_to_non_nullable
as int,recurrenceMode: null == recurrenceMode ? _self.recurrenceMode : recurrenceMode // ignore: cast_nullable_to_non_nullable
as String,assigneeId: freezed == assigneeId ? _self.assigneeId : assigneeId // ignore: cast_nullable_to_non_nullable
as String?,nextDueDate: null == nextDueDate ? _self.nextDueDate : nextDueDate // ignore: cast_nullable_to_non_nullable
as DateTime,lastCompletedAt: freezed == lastCompletedAt ? _self.lastCompletedAt : lastCompletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastCompletedBy: freezed == lastCompletedBy ? _self.lastCompletedBy : lastCompletedBy // ignore: cast_nullable_to_non_nullable
as String?,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as String,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Chore].
extension ChorePatterns on Chore {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Chore value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Chore() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Chore value)  $default,){
final _that = this;
switch (_that) {
case _Chore():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Chore value)?  $default,){
final _that = this;
switch (_that) {
case _Chore() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String emoji,  String recurrenceType,  int recurrenceInterval,  List<int> recurrenceDaysOfWeek,  int recurrenceDayOfMonth,  String recurrenceMode,  String? assigneeId,  DateTime nextDueDate,  DateTime? lastCompletedAt,  String? lastCompletedBy,  String priority,  String createdBy,  DateTime createdAt,  int order,  bool isArchived)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Chore() when $default != null:
return $default(_that.id,_that.name,_that.emoji,_that.recurrenceType,_that.recurrenceInterval,_that.recurrenceDaysOfWeek,_that.recurrenceDayOfMonth,_that.recurrenceMode,_that.assigneeId,_that.nextDueDate,_that.lastCompletedAt,_that.lastCompletedBy,_that.priority,_that.createdBy,_that.createdAt,_that.order,_that.isArchived);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String emoji,  String recurrenceType,  int recurrenceInterval,  List<int> recurrenceDaysOfWeek,  int recurrenceDayOfMonth,  String recurrenceMode,  String? assigneeId,  DateTime nextDueDate,  DateTime? lastCompletedAt,  String? lastCompletedBy,  String priority,  String createdBy,  DateTime createdAt,  int order,  bool isArchived)  $default,) {final _that = this;
switch (_that) {
case _Chore():
return $default(_that.id,_that.name,_that.emoji,_that.recurrenceType,_that.recurrenceInterval,_that.recurrenceDaysOfWeek,_that.recurrenceDayOfMonth,_that.recurrenceMode,_that.assigneeId,_that.nextDueDate,_that.lastCompletedAt,_that.lastCompletedBy,_that.priority,_that.createdBy,_that.createdAt,_that.order,_that.isArchived);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String emoji,  String recurrenceType,  int recurrenceInterval,  List<int> recurrenceDaysOfWeek,  int recurrenceDayOfMonth,  String recurrenceMode,  String? assigneeId,  DateTime nextDueDate,  DateTime? lastCompletedAt,  String? lastCompletedBy,  String priority,  String createdBy,  DateTime createdAt,  int order,  bool isArchived)?  $default,) {final _that = this;
switch (_that) {
case _Chore() when $default != null:
return $default(_that.id,_that.name,_that.emoji,_that.recurrenceType,_that.recurrenceInterval,_that.recurrenceDaysOfWeek,_that.recurrenceDayOfMonth,_that.recurrenceMode,_that.assigneeId,_that.nextDueDate,_that.lastCompletedAt,_that.lastCompletedBy,_that.priority,_that.createdBy,_that.createdAt,_that.order,_that.isArchived);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Chore implements Chore {
  const _Chore({required this.id, required this.name, this.emoji = '✅', this.recurrenceType = 'weekly', this.recurrenceInterval = 1, final  List<int> recurrenceDaysOfWeek = const [], this.recurrenceDayOfMonth = 1, this.recurrenceMode = 'floating', this.assigneeId, required this.nextDueDate, this.lastCompletedAt, this.lastCompletedBy, this.priority = 'regular', required this.createdBy, required this.createdAt, this.order = 0, this.isArchived = false}): _recurrenceDaysOfWeek = recurrenceDaysOfWeek;
  factory _Chore.fromJson(Map<String, dynamic> json) => _$ChoreFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey() final  String emoji;
// ── Recurrence ────────────────────────────────────────────
/// "one_off" | "daily" | "every_n_days" | "weekly" | "biweekly" | "monthly"
@override@JsonKey() final  String recurrenceType;
/// Interval for "every_n_days" (e.g. 3 = every 3 days).
@override@JsonKey() final  int recurrenceInterval;
/// Days of week for "weekly" recurrence (1=Mon..7=Sun).
 final  List<int> _recurrenceDaysOfWeek;
/// Days of week for "weekly" recurrence (1=Mon..7=Sun).
@override@JsonKey() List<int> get recurrenceDaysOfWeek {
  if (_recurrenceDaysOfWeek is EqualUnmodifiableListView) return _recurrenceDaysOfWeek;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recurrenceDaysOfWeek);
}

/// Day of month for "monthly" recurrence.
@override@JsonKey() final  int recurrenceDayOfMonth;
/// "fixed" = next due from schedule, "floating" = next due from completion.
@override@JsonKey() final  String recurrenceMode;
// ── Assignment & Status ───────────────────────────────────
/// Null means "anyone can claim it".
@override final  String? assigneeId;
/// When the chore is next due.
@override final  DateTime nextDueDate;
/// When the chore was last completed.
@override final  DateTime? lastCompletedAt;
/// Who last completed this chore.
@override final  String? lastCompletedBy;
/// "now" | "regular" | "whenever"
@override@JsonKey() final  String priority;
// ── Metadata ──────────────────────────────────────────────
@override final  String createdBy;
@override final  DateTime createdAt;
@override@JsonKey() final  int order;
/// Whether the chore is archived (e.g. completed one-off chores).
@override@JsonKey() final  bool isArchived;

/// Create a copy of Chore
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChoreCopyWith<_Chore> get copyWith => __$ChoreCopyWithImpl<_Chore>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChoreToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Chore&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.emoji, emoji) || other.emoji == emoji)&&(identical(other.recurrenceType, recurrenceType) || other.recurrenceType == recurrenceType)&&(identical(other.recurrenceInterval, recurrenceInterval) || other.recurrenceInterval == recurrenceInterval)&&const DeepCollectionEquality().equals(other._recurrenceDaysOfWeek, _recurrenceDaysOfWeek)&&(identical(other.recurrenceDayOfMonth, recurrenceDayOfMonth) || other.recurrenceDayOfMonth == recurrenceDayOfMonth)&&(identical(other.recurrenceMode, recurrenceMode) || other.recurrenceMode == recurrenceMode)&&(identical(other.assigneeId, assigneeId) || other.assigneeId == assigneeId)&&(identical(other.nextDueDate, nextDueDate) || other.nextDueDate == nextDueDate)&&(identical(other.lastCompletedAt, lastCompletedAt) || other.lastCompletedAt == lastCompletedAt)&&(identical(other.lastCompletedBy, lastCompletedBy) || other.lastCompletedBy == lastCompletedBy)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.order, order) || other.order == order)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,emoji,recurrenceType,recurrenceInterval,const DeepCollectionEquality().hash(_recurrenceDaysOfWeek),recurrenceDayOfMonth,recurrenceMode,assigneeId,nextDueDate,lastCompletedAt,lastCompletedBy,priority,createdBy,createdAt,order,isArchived);

@override
String toString() {
  return 'Chore(id: $id, name: $name, emoji: $emoji, recurrenceType: $recurrenceType, recurrenceInterval: $recurrenceInterval, recurrenceDaysOfWeek: $recurrenceDaysOfWeek, recurrenceDayOfMonth: $recurrenceDayOfMonth, recurrenceMode: $recurrenceMode, assigneeId: $assigneeId, nextDueDate: $nextDueDate, lastCompletedAt: $lastCompletedAt, lastCompletedBy: $lastCompletedBy, priority: $priority, createdBy: $createdBy, createdAt: $createdAt, order: $order, isArchived: $isArchived)';
}


}

/// @nodoc
abstract mixin class _$ChoreCopyWith<$Res> implements $ChoreCopyWith<$Res> {
  factory _$ChoreCopyWith(_Chore value, $Res Function(_Chore) _then) = __$ChoreCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String emoji, String recurrenceType, int recurrenceInterval, List<int> recurrenceDaysOfWeek, int recurrenceDayOfMonth, String recurrenceMode, String? assigneeId, DateTime nextDueDate, DateTime? lastCompletedAt, String? lastCompletedBy, String priority, String createdBy, DateTime createdAt, int order, bool isArchived
});




}
/// @nodoc
class __$ChoreCopyWithImpl<$Res>
    implements _$ChoreCopyWith<$Res> {
  __$ChoreCopyWithImpl(this._self, this._then);

  final _Chore _self;
  final $Res Function(_Chore) _then;

/// Create a copy of Chore
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? emoji = null,Object? recurrenceType = null,Object? recurrenceInterval = null,Object? recurrenceDaysOfWeek = null,Object? recurrenceDayOfMonth = null,Object? recurrenceMode = null,Object? assigneeId = freezed,Object? nextDueDate = null,Object? lastCompletedAt = freezed,Object? lastCompletedBy = freezed,Object? priority = null,Object? createdBy = null,Object? createdAt = null,Object? order = null,Object? isArchived = null,}) {
  return _then(_Chore(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,emoji: null == emoji ? _self.emoji : emoji // ignore: cast_nullable_to_non_nullable
as String,recurrenceType: null == recurrenceType ? _self.recurrenceType : recurrenceType // ignore: cast_nullable_to_non_nullable
as String,recurrenceInterval: null == recurrenceInterval ? _self.recurrenceInterval : recurrenceInterval // ignore: cast_nullable_to_non_nullable
as int,recurrenceDaysOfWeek: null == recurrenceDaysOfWeek ? _self._recurrenceDaysOfWeek : recurrenceDaysOfWeek // ignore: cast_nullable_to_non_nullable
as List<int>,recurrenceDayOfMonth: null == recurrenceDayOfMonth ? _self.recurrenceDayOfMonth : recurrenceDayOfMonth // ignore: cast_nullable_to_non_nullable
as int,recurrenceMode: null == recurrenceMode ? _self.recurrenceMode : recurrenceMode // ignore: cast_nullable_to_non_nullable
as String,assigneeId: freezed == assigneeId ? _self.assigneeId : assigneeId // ignore: cast_nullable_to_non_nullable
as String?,nextDueDate: null == nextDueDate ? _self.nextDueDate : nextDueDate // ignore: cast_nullable_to_non_nullable
as DateTime,lastCompletedAt: freezed == lastCompletedAt ? _self.lastCompletedAt : lastCompletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastCompletedBy: freezed == lastCompletedBy ? _self.lastCompletedBy : lastCompletedBy // ignore: cast_nullable_to_non_nullable
as String?,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as String,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
