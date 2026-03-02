// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Subtask {

 String get id; String get title; bool get completed;
/// Create a copy of Subtask
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubtaskCopyWith<Subtask> get copyWith => _$SubtaskCopyWithImpl<Subtask>(this as Subtask, _$identity);

  /// Serializes this Subtask to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Subtask&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.completed, completed) || other.completed == completed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,completed);

@override
String toString() {
  return 'Subtask(id: $id, title: $title, completed: $completed)';
}


}

/// @nodoc
abstract mixin class $SubtaskCopyWith<$Res>  {
  factory $SubtaskCopyWith(Subtask value, $Res Function(Subtask) _then) = _$SubtaskCopyWithImpl;
@useResult
$Res call({
 String id, String title, bool completed
});




}
/// @nodoc
class _$SubtaskCopyWithImpl<$Res>
    implements $SubtaskCopyWith<$Res> {
  _$SubtaskCopyWithImpl(this._self, this._then);

  final Subtask _self;
  final $Res Function(Subtask) _then;

/// Create a copy of Subtask
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? completed = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,completed: null == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Subtask].
extension SubtaskPatterns on Subtask {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Subtask value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Subtask() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Subtask value)  $default,){
final _that = this;
switch (_that) {
case _Subtask():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Subtask value)?  $default,){
final _that = this;
switch (_that) {
case _Subtask() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  bool completed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Subtask() when $default != null:
return $default(_that.id,_that.title,_that.completed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  bool completed)  $default,) {final _that = this;
switch (_that) {
case _Subtask():
return $default(_that.id,_that.title,_that.completed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  bool completed)?  $default,) {final _that = this;
switch (_that) {
case _Subtask() when $default != null:
return $default(_that.id,_that.title,_that.completed);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Subtask implements Subtask {
  const _Subtask({required this.id, required this.title, this.completed = false});
  factory _Subtask.fromJson(Map<String, dynamic> json) => _$SubtaskFromJson(json);

@override final  String id;
@override final  String title;
@override@JsonKey() final  bool completed;

/// Create a copy of Subtask
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubtaskCopyWith<_Subtask> get copyWith => __$SubtaskCopyWithImpl<_Subtask>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubtaskToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Subtask&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.completed, completed) || other.completed == completed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,completed);

@override
String toString() {
  return 'Subtask(id: $id, title: $title, completed: $completed)';
}


}

/// @nodoc
abstract mixin class _$SubtaskCopyWith<$Res> implements $SubtaskCopyWith<$Res> {
  factory _$SubtaskCopyWith(_Subtask value, $Res Function(_Subtask) _then) = __$SubtaskCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, bool completed
});




}
/// @nodoc
class __$SubtaskCopyWithImpl<$Res>
    implements _$SubtaskCopyWith<$Res> {
  __$SubtaskCopyWithImpl(this._self, this._then);

  final _Subtask _self;
  final $Res Function(_Subtask) _then;

/// Create a copy of Subtask
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? completed = null,}) {
  return _then(_Subtask(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,completed: null == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$Attachment {

 String get url; String get type; String get name;
/// Create a copy of Attachment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AttachmentCopyWith<Attachment> get copyWith => _$AttachmentCopyWithImpl<Attachment>(this as Attachment, _$identity);

  /// Serializes this Attachment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Attachment&&(identical(other.url, url) || other.url == url)&&(identical(other.type, type) || other.type == type)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,url,type,name);

@override
String toString() {
  return 'Attachment(url: $url, type: $type, name: $name)';
}


}

/// @nodoc
abstract mixin class $AttachmentCopyWith<$Res>  {
  factory $AttachmentCopyWith(Attachment value, $Res Function(Attachment) _then) = _$AttachmentCopyWithImpl;
@useResult
$Res call({
 String url, String type, String name
});




}
/// @nodoc
class _$AttachmentCopyWithImpl<$Res>
    implements $AttachmentCopyWith<$Res> {
  _$AttachmentCopyWithImpl(this._self, this._then);

  final Attachment _self;
  final $Res Function(Attachment) _then;

/// Create a copy of Attachment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? url = null,Object? type = null,Object? name = null,}) {
  return _then(_self.copyWith(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Attachment].
extension AttachmentPatterns on Attachment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Attachment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Attachment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Attachment value)  $default,){
final _that = this;
switch (_that) {
case _Attachment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Attachment value)?  $default,){
final _that = this;
switch (_that) {
case _Attachment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String url,  String type,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Attachment() when $default != null:
return $default(_that.url,_that.type,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String url,  String type,  String name)  $default,) {final _that = this;
switch (_that) {
case _Attachment():
return $default(_that.url,_that.type,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String url,  String type,  String name)?  $default,) {final _that = this;
switch (_that) {
case _Attachment() when $default != null:
return $default(_that.url,_that.type,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Attachment implements Attachment {
  const _Attachment({required this.url, required this.type, required this.name});
  factory _Attachment.fromJson(Map<String, dynamic> json) => _$AttachmentFromJson(json);

@override final  String url;
@override final  String type;
@override final  String name;

/// Create a copy of Attachment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AttachmentCopyWith<_Attachment> get copyWith => __$AttachmentCopyWithImpl<_Attachment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AttachmentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Attachment&&(identical(other.url, url) || other.url == url)&&(identical(other.type, type) || other.type == type)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,url,type,name);

@override
String toString() {
  return 'Attachment(url: $url, type: $type, name: $name)';
}


}

/// @nodoc
abstract mixin class _$AttachmentCopyWith<$Res> implements $AttachmentCopyWith<$Res> {
  factory _$AttachmentCopyWith(_Attachment value, $Res Function(_Attachment) _then) = __$AttachmentCopyWithImpl;
@override @useResult
$Res call({
 String url, String type, String name
});




}
/// @nodoc
class __$AttachmentCopyWithImpl<$Res>
    implements _$AttachmentCopyWith<$Res> {
  __$AttachmentCopyWithImpl(this._self, this._then);

  final _Attachment _self;
  final $Res Function(_Attachment) _then;

/// Create a copy of Attachment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? url = null,Object? type = null,Object? name = null,}) {
  return _then(_Attachment(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$TaskModel {

 String get id; String get title; String? get description; String get status;// 'todo' | 'in_progress' | 'done'
 String get boardId; List<String> get assignees; DateTime? get dueDate; String? get emojiTag; List<Subtask> get subtasks; List<Attachment> get attachments; bool get isWeeklyTask; DateTime? get weekStart; int get order; DateTime? get completedAt;/// When non-null, the task is archived and hidden from the board.
 DateTime? get archivedAt;/// Whether this task is blocked.
 bool get isBlocked;/// Reason why the task is blocked.
 String? get blockedReason;/// Recurrence rule: 'never' | 'daily' | 'weekly' | 'biweekly' | 'monthly'
 String get recurrenceRule; String get createdBy; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of TaskModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskModelCopyWith<TaskModel> get copyWith => _$TaskModelCopyWithImpl<TaskModel>(this as TaskModel, _$identity);

  /// Serializes this TaskModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskModel&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.status, status) || other.status == status)&&(identical(other.boardId, boardId) || other.boardId == boardId)&&const DeepCollectionEquality().equals(other.assignees, assignees)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.emojiTag, emojiTag) || other.emojiTag == emojiTag)&&const DeepCollectionEquality().equals(other.subtasks, subtasks)&&const DeepCollectionEquality().equals(other.attachments, attachments)&&(identical(other.isWeeklyTask, isWeeklyTask) || other.isWeeklyTask == isWeeklyTask)&&(identical(other.weekStart, weekStart) || other.weekStart == weekStart)&&(identical(other.order, order) || other.order == order)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt)&&(identical(other.isBlocked, isBlocked) || other.isBlocked == isBlocked)&&(identical(other.blockedReason, blockedReason) || other.blockedReason == blockedReason)&&(identical(other.recurrenceRule, recurrenceRule) || other.recurrenceRule == recurrenceRule)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,title,description,status,boardId,const DeepCollectionEquality().hash(assignees),dueDate,emojiTag,const DeepCollectionEquality().hash(subtasks),const DeepCollectionEquality().hash(attachments),isWeeklyTask,weekStart,order,completedAt,archivedAt,isBlocked,blockedReason,recurrenceRule,createdBy,createdAt,updatedAt]);

@override
String toString() {
  return 'TaskModel(id: $id, title: $title, description: $description, status: $status, boardId: $boardId, assignees: $assignees, dueDate: $dueDate, emojiTag: $emojiTag, subtasks: $subtasks, attachments: $attachments, isWeeklyTask: $isWeeklyTask, weekStart: $weekStart, order: $order, completedAt: $completedAt, archivedAt: $archivedAt, isBlocked: $isBlocked, blockedReason: $blockedReason, recurrenceRule: $recurrenceRule, createdBy: $createdBy, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $TaskModelCopyWith<$Res>  {
  factory $TaskModelCopyWith(TaskModel value, $Res Function(TaskModel) _then) = _$TaskModelCopyWithImpl;
@useResult
$Res call({
 String id, String title, String? description, String status, String boardId, List<String> assignees, DateTime? dueDate, String? emojiTag, List<Subtask> subtasks, List<Attachment> attachments, bool isWeeklyTask, DateTime? weekStart, int order, DateTime? completedAt, DateTime? archivedAt, bool isBlocked, String? blockedReason, String recurrenceRule, String createdBy, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$TaskModelCopyWithImpl<$Res>
    implements $TaskModelCopyWith<$Res> {
  _$TaskModelCopyWithImpl(this._self, this._then);

  final TaskModel _self;
  final $Res Function(TaskModel) _then;

/// Create a copy of TaskModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? description = freezed,Object? status = null,Object? boardId = null,Object? assignees = null,Object? dueDate = freezed,Object? emojiTag = freezed,Object? subtasks = null,Object? attachments = null,Object? isWeeklyTask = null,Object? weekStart = freezed,Object? order = null,Object? completedAt = freezed,Object? archivedAt = freezed,Object? isBlocked = null,Object? blockedReason = freezed,Object? recurrenceRule = null,Object? createdBy = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,boardId: null == boardId ? _self.boardId : boardId // ignore: cast_nullable_to_non_nullable
as String,assignees: null == assignees ? _self.assignees : assignees // ignore: cast_nullable_to_non_nullable
as List<String>,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,emojiTag: freezed == emojiTag ? _self.emojiTag : emojiTag // ignore: cast_nullable_to_non_nullable
as String?,subtasks: null == subtasks ? _self.subtasks : subtasks // ignore: cast_nullable_to_non_nullable
as List<Subtask>,attachments: null == attachments ? _self.attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<Attachment>,isWeeklyTask: null == isWeeklyTask ? _self.isWeeklyTask : isWeeklyTask // ignore: cast_nullable_to_non_nullable
as bool,weekStart: freezed == weekStart ? _self.weekStart : weekStart // ignore: cast_nullable_to_non_nullable
as DateTime?,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,archivedAt: freezed == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isBlocked: null == isBlocked ? _self.isBlocked : isBlocked // ignore: cast_nullable_to_non_nullable
as bool,blockedReason: freezed == blockedReason ? _self.blockedReason : blockedReason // ignore: cast_nullable_to_non_nullable
as String?,recurrenceRule: null == recurrenceRule ? _self.recurrenceRule : recurrenceRule // ignore: cast_nullable_to_non_nullable
as String,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [TaskModel].
extension TaskModelPatterns on TaskModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TaskModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TaskModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TaskModel value)  $default,){
final _that = this;
switch (_that) {
case _TaskModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TaskModel value)?  $default,){
final _that = this;
switch (_that) {
case _TaskModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String? description,  String status,  String boardId,  List<String> assignees,  DateTime? dueDate,  String? emojiTag,  List<Subtask> subtasks,  List<Attachment> attachments,  bool isWeeklyTask,  DateTime? weekStart,  int order,  DateTime? completedAt,  DateTime? archivedAt,  bool isBlocked,  String? blockedReason,  String recurrenceRule,  String createdBy,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TaskModel() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.status,_that.boardId,_that.assignees,_that.dueDate,_that.emojiTag,_that.subtasks,_that.attachments,_that.isWeeklyTask,_that.weekStart,_that.order,_that.completedAt,_that.archivedAt,_that.isBlocked,_that.blockedReason,_that.recurrenceRule,_that.createdBy,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String? description,  String status,  String boardId,  List<String> assignees,  DateTime? dueDate,  String? emojiTag,  List<Subtask> subtasks,  List<Attachment> attachments,  bool isWeeklyTask,  DateTime? weekStart,  int order,  DateTime? completedAt,  DateTime? archivedAt,  bool isBlocked,  String? blockedReason,  String recurrenceRule,  String createdBy,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _TaskModel():
return $default(_that.id,_that.title,_that.description,_that.status,_that.boardId,_that.assignees,_that.dueDate,_that.emojiTag,_that.subtasks,_that.attachments,_that.isWeeklyTask,_that.weekStart,_that.order,_that.completedAt,_that.archivedAt,_that.isBlocked,_that.blockedReason,_that.recurrenceRule,_that.createdBy,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String? description,  String status,  String boardId,  List<String> assignees,  DateTime? dueDate,  String? emojiTag,  List<Subtask> subtasks,  List<Attachment> attachments,  bool isWeeklyTask,  DateTime? weekStart,  int order,  DateTime? completedAt,  DateTime? archivedAt,  bool isBlocked,  String? blockedReason,  String recurrenceRule,  String createdBy,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _TaskModel() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.status,_that.boardId,_that.assignees,_that.dueDate,_that.emojiTag,_that.subtasks,_that.attachments,_that.isWeeklyTask,_that.weekStart,_that.order,_that.completedAt,_that.archivedAt,_that.isBlocked,_that.blockedReason,_that.recurrenceRule,_that.createdBy,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TaskModel implements TaskModel {
  const _TaskModel({required this.id, required this.title, this.description, this.status = 'todo', required this.boardId, final  List<String> assignees = const [], this.dueDate, this.emojiTag, final  List<Subtask> subtasks = const [], final  List<Attachment> attachments = const [], this.isWeeklyTask = false, this.weekStart, this.order = 0, this.completedAt, this.archivedAt, this.isBlocked = false, this.blockedReason, this.recurrenceRule = 'never', required this.createdBy, required this.createdAt, required this.updatedAt}): _assignees = assignees,_subtasks = subtasks,_attachments = attachments;
  factory _TaskModel.fromJson(Map<String, dynamic> json) => _$TaskModelFromJson(json);

@override final  String id;
@override final  String title;
@override final  String? description;
@override@JsonKey() final  String status;
// 'todo' | 'in_progress' | 'done'
@override final  String boardId;
 final  List<String> _assignees;
@override@JsonKey() List<String> get assignees {
  if (_assignees is EqualUnmodifiableListView) return _assignees;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_assignees);
}

@override final  DateTime? dueDate;
@override final  String? emojiTag;
 final  List<Subtask> _subtasks;
@override@JsonKey() List<Subtask> get subtasks {
  if (_subtasks is EqualUnmodifiableListView) return _subtasks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_subtasks);
}

 final  List<Attachment> _attachments;
@override@JsonKey() List<Attachment> get attachments {
  if (_attachments is EqualUnmodifiableListView) return _attachments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_attachments);
}

@override@JsonKey() final  bool isWeeklyTask;
@override final  DateTime? weekStart;
@override@JsonKey() final  int order;
@override final  DateTime? completedAt;
/// When non-null, the task is archived and hidden from the board.
@override final  DateTime? archivedAt;
/// Whether this task is blocked.
@override@JsonKey() final  bool isBlocked;
/// Reason why the task is blocked.
@override final  String? blockedReason;
/// Recurrence rule: 'never' | 'daily' | 'weekly' | 'biweekly' | 'monthly'
@override@JsonKey() final  String recurrenceRule;
@override final  String createdBy;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of TaskModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskModelCopyWith<_TaskModel> get copyWith => __$TaskModelCopyWithImpl<_TaskModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TaskModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskModel&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.status, status) || other.status == status)&&(identical(other.boardId, boardId) || other.boardId == boardId)&&const DeepCollectionEquality().equals(other._assignees, _assignees)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.emojiTag, emojiTag) || other.emojiTag == emojiTag)&&const DeepCollectionEquality().equals(other._subtasks, _subtasks)&&const DeepCollectionEquality().equals(other._attachments, _attachments)&&(identical(other.isWeeklyTask, isWeeklyTask) || other.isWeeklyTask == isWeeklyTask)&&(identical(other.weekStart, weekStart) || other.weekStart == weekStart)&&(identical(other.order, order) || other.order == order)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt)&&(identical(other.isBlocked, isBlocked) || other.isBlocked == isBlocked)&&(identical(other.blockedReason, blockedReason) || other.blockedReason == blockedReason)&&(identical(other.recurrenceRule, recurrenceRule) || other.recurrenceRule == recurrenceRule)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,title,description,status,boardId,const DeepCollectionEquality().hash(_assignees),dueDate,emojiTag,const DeepCollectionEquality().hash(_subtasks),const DeepCollectionEquality().hash(_attachments),isWeeklyTask,weekStart,order,completedAt,archivedAt,isBlocked,blockedReason,recurrenceRule,createdBy,createdAt,updatedAt]);

@override
String toString() {
  return 'TaskModel(id: $id, title: $title, description: $description, status: $status, boardId: $boardId, assignees: $assignees, dueDate: $dueDate, emojiTag: $emojiTag, subtasks: $subtasks, attachments: $attachments, isWeeklyTask: $isWeeklyTask, weekStart: $weekStart, order: $order, completedAt: $completedAt, archivedAt: $archivedAt, isBlocked: $isBlocked, blockedReason: $blockedReason, recurrenceRule: $recurrenceRule, createdBy: $createdBy, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$TaskModelCopyWith<$Res> implements $TaskModelCopyWith<$Res> {
  factory _$TaskModelCopyWith(_TaskModel value, $Res Function(_TaskModel) _then) = __$TaskModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String? description, String status, String boardId, List<String> assignees, DateTime? dueDate, String? emojiTag, List<Subtask> subtasks, List<Attachment> attachments, bool isWeeklyTask, DateTime? weekStart, int order, DateTime? completedAt, DateTime? archivedAt, bool isBlocked, String? blockedReason, String recurrenceRule, String createdBy, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$TaskModelCopyWithImpl<$Res>
    implements _$TaskModelCopyWith<$Res> {
  __$TaskModelCopyWithImpl(this._self, this._then);

  final _TaskModel _self;
  final $Res Function(_TaskModel) _then;

/// Create a copy of TaskModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? description = freezed,Object? status = null,Object? boardId = null,Object? assignees = null,Object? dueDate = freezed,Object? emojiTag = freezed,Object? subtasks = null,Object? attachments = null,Object? isWeeklyTask = null,Object? weekStart = freezed,Object? order = null,Object? completedAt = freezed,Object? archivedAt = freezed,Object? isBlocked = null,Object? blockedReason = freezed,Object? recurrenceRule = null,Object? createdBy = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_TaskModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,boardId: null == boardId ? _self.boardId : boardId // ignore: cast_nullable_to_non_nullable
as String,assignees: null == assignees ? _self._assignees : assignees // ignore: cast_nullable_to_non_nullable
as List<String>,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,emojiTag: freezed == emojiTag ? _self.emojiTag : emojiTag // ignore: cast_nullable_to_non_nullable
as String?,subtasks: null == subtasks ? _self._subtasks : subtasks // ignore: cast_nullable_to_non_nullable
as List<Subtask>,attachments: null == attachments ? _self._attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<Attachment>,isWeeklyTask: null == isWeeklyTask ? _self.isWeeklyTask : isWeeklyTask // ignore: cast_nullable_to_non_nullable
as bool,weekStart: freezed == weekStart ? _self.weekStart : weekStart // ignore: cast_nullable_to_non_nullable
as DateTime?,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,archivedAt: freezed == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isBlocked: null == isBlocked ? _self.isBlocked : isBlocked // ignore: cast_nullable_to_non_nullable
as bool,blockedReason: freezed == blockedReason ? _self.blockedReason : blockedReason // ignore: cast_nullable_to_non_nullable
as String?,recurrenceRule: null == recurrenceRule ? _self.recurrenceRule : recurrenceRule // ignore: cast_nullable_to_non_nullable
as String,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
