// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'homepad_item_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HomePadItem {

 String get id; String get name; String get emoji; String get category; String get subcategory; String get status;// 'available' | 'to_buy' | 'purchased'
 String get frequency;// 'weekly' | 'biweekly' | 'monthly' | 'as_needed'
 bool get isCustom; bool get isHidden; String? get addedBy; DateTime? get addedAt; String? get purchasedBy; DateTime? get purchasedAt; int get quantity; String? get note; int get purchaseCount; int get order; DateTime get createdAt;
/// Create a copy of HomePadItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HomePadItemCopyWith<HomePadItem> get copyWith => _$HomePadItemCopyWithImpl<HomePadItem>(this as HomePadItem, _$identity);

  /// Serializes this HomePadItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomePadItem&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.emoji, emoji) || other.emoji == emoji)&&(identical(other.category, category) || other.category == category)&&(identical(other.subcategory, subcategory) || other.subcategory == subcategory)&&(identical(other.status, status) || other.status == status)&&(identical(other.frequency, frequency) || other.frequency == frequency)&&(identical(other.isCustom, isCustom) || other.isCustom == isCustom)&&(identical(other.isHidden, isHidden) || other.isHidden == isHidden)&&(identical(other.addedBy, addedBy) || other.addedBy == addedBy)&&(identical(other.addedAt, addedAt) || other.addedAt == addedAt)&&(identical(other.purchasedBy, purchasedBy) || other.purchasedBy == purchasedBy)&&(identical(other.purchasedAt, purchasedAt) || other.purchasedAt == purchasedAt)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.note, note) || other.note == note)&&(identical(other.purchaseCount, purchaseCount) || other.purchaseCount == purchaseCount)&&(identical(other.order, order) || other.order == order)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,emoji,category,subcategory,status,frequency,isCustom,isHidden,addedBy,addedAt,purchasedBy,purchasedAt,quantity,note,purchaseCount,order,createdAt);

@override
String toString() {
  return 'HomePadItem(id: $id, name: $name, emoji: $emoji, category: $category, subcategory: $subcategory, status: $status, frequency: $frequency, isCustom: $isCustom, isHidden: $isHidden, addedBy: $addedBy, addedAt: $addedAt, purchasedBy: $purchasedBy, purchasedAt: $purchasedAt, quantity: $quantity, note: $note, purchaseCount: $purchaseCount, order: $order, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $HomePadItemCopyWith<$Res>  {
  factory $HomePadItemCopyWith(HomePadItem value, $Res Function(HomePadItem) _then) = _$HomePadItemCopyWithImpl;
@useResult
$Res call({
 String id, String name, String emoji, String category, String subcategory, String status, String frequency, bool isCustom, bool isHidden, String? addedBy, DateTime? addedAt, String? purchasedBy, DateTime? purchasedAt, int quantity, String? note, int purchaseCount, int order, DateTime createdAt
});




}
/// @nodoc
class _$HomePadItemCopyWithImpl<$Res>
    implements $HomePadItemCopyWith<$Res> {
  _$HomePadItemCopyWithImpl(this._self, this._then);

  final HomePadItem _self;
  final $Res Function(HomePadItem) _then;

/// Create a copy of HomePadItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? emoji = null,Object? category = null,Object? subcategory = null,Object? status = null,Object? frequency = null,Object? isCustom = null,Object? isHidden = null,Object? addedBy = freezed,Object? addedAt = freezed,Object? purchasedBy = freezed,Object? purchasedAt = freezed,Object? quantity = null,Object? note = freezed,Object? purchaseCount = null,Object? order = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,emoji: null == emoji ? _self.emoji : emoji // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,subcategory: null == subcategory ? _self.subcategory : subcategory // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as String,isCustom: null == isCustom ? _self.isCustom : isCustom // ignore: cast_nullable_to_non_nullable
as bool,isHidden: null == isHidden ? _self.isHidden : isHidden // ignore: cast_nullable_to_non_nullable
as bool,addedBy: freezed == addedBy ? _self.addedBy : addedBy // ignore: cast_nullable_to_non_nullable
as String?,addedAt: freezed == addedAt ? _self.addedAt : addedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,purchasedBy: freezed == purchasedBy ? _self.purchasedBy : purchasedBy // ignore: cast_nullable_to_non_nullable
as String?,purchasedAt: freezed == purchasedAt ? _self.purchasedAt : purchasedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,purchaseCount: null == purchaseCount ? _self.purchaseCount : purchaseCount // ignore: cast_nullable_to_non_nullable
as int,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [HomePadItem].
extension HomePadItemPatterns on HomePadItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HomePadItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HomePadItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HomePadItem value)  $default,){
final _that = this;
switch (_that) {
case _HomePadItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HomePadItem value)?  $default,){
final _that = this;
switch (_that) {
case _HomePadItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String emoji,  String category,  String subcategory,  String status,  String frequency,  bool isCustom,  bool isHidden,  String? addedBy,  DateTime? addedAt,  String? purchasedBy,  DateTime? purchasedAt,  int quantity,  String? note,  int purchaseCount,  int order,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HomePadItem() when $default != null:
return $default(_that.id,_that.name,_that.emoji,_that.category,_that.subcategory,_that.status,_that.frequency,_that.isCustom,_that.isHidden,_that.addedBy,_that.addedAt,_that.purchasedBy,_that.purchasedAt,_that.quantity,_that.note,_that.purchaseCount,_that.order,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String emoji,  String category,  String subcategory,  String status,  String frequency,  bool isCustom,  bool isHidden,  String? addedBy,  DateTime? addedAt,  String? purchasedBy,  DateTime? purchasedAt,  int quantity,  String? note,  int purchaseCount,  int order,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _HomePadItem():
return $default(_that.id,_that.name,_that.emoji,_that.category,_that.subcategory,_that.status,_that.frequency,_that.isCustom,_that.isHidden,_that.addedBy,_that.addedAt,_that.purchasedBy,_that.purchasedAt,_that.quantity,_that.note,_that.purchaseCount,_that.order,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String emoji,  String category,  String subcategory,  String status,  String frequency,  bool isCustom,  bool isHidden,  String? addedBy,  DateTime? addedAt,  String? purchasedBy,  DateTime? purchasedAt,  int quantity,  String? note,  int purchaseCount,  int order,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _HomePadItem() when $default != null:
return $default(_that.id,_that.name,_that.emoji,_that.category,_that.subcategory,_that.status,_that.frequency,_that.isCustom,_that.isHidden,_that.addedBy,_that.addedAt,_that.purchasedBy,_that.purchasedAt,_that.quantity,_that.note,_that.purchaseCount,_that.order,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HomePadItem implements HomePadItem {
  const _HomePadItem({required this.id, required this.name, this.emoji = '🛒', required this.category, this.subcategory = '', this.status = 'available', this.frequency = 'as_needed', this.isCustom = false, this.isHidden = false, this.addedBy, this.addedAt, this.purchasedBy, this.purchasedAt, this.quantity = 1, this.note, this.purchaseCount = 0, this.order = 0, required this.createdAt});
  factory _HomePadItem.fromJson(Map<String, dynamic> json) => _$HomePadItemFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey() final  String emoji;
@override final  String category;
@override@JsonKey() final  String subcategory;
@override@JsonKey() final  String status;
// 'available' | 'to_buy' | 'purchased'
@override@JsonKey() final  String frequency;
// 'weekly' | 'biweekly' | 'monthly' | 'as_needed'
@override@JsonKey() final  bool isCustom;
@override@JsonKey() final  bool isHidden;
@override final  String? addedBy;
@override final  DateTime? addedAt;
@override final  String? purchasedBy;
@override final  DateTime? purchasedAt;
@override@JsonKey() final  int quantity;
@override final  String? note;
@override@JsonKey() final  int purchaseCount;
@override@JsonKey() final  int order;
@override final  DateTime createdAt;

/// Create a copy of HomePadItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HomePadItemCopyWith<_HomePadItem> get copyWith => __$HomePadItemCopyWithImpl<_HomePadItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HomePadItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HomePadItem&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.emoji, emoji) || other.emoji == emoji)&&(identical(other.category, category) || other.category == category)&&(identical(other.subcategory, subcategory) || other.subcategory == subcategory)&&(identical(other.status, status) || other.status == status)&&(identical(other.frequency, frequency) || other.frequency == frequency)&&(identical(other.isCustom, isCustom) || other.isCustom == isCustom)&&(identical(other.isHidden, isHidden) || other.isHidden == isHidden)&&(identical(other.addedBy, addedBy) || other.addedBy == addedBy)&&(identical(other.addedAt, addedAt) || other.addedAt == addedAt)&&(identical(other.purchasedBy, purchasedBy) || other.purchasedBy == purchasedBy)&&(identical(other.purchasedAt, purchasedAt) || other.purchasedAt == purchasedAt)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.note, note) || other.note == note)&&(identical(other.purchaseCount, purchaseCount) || other.purchaseCount == purchaseCount)&&(identical(other.order, order) || other.order == order)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,emoji,category,subcategory,status,frequency,isCustom,isHidden,addedBy,addedAt,purchasedBy,purchasedAt,quantity,note,purchaseCount,order,createdAt);

@override
String toString() {
  return 'HomePadItem(id: $id, name: $name, emoji: $emoji, category: $category, subcategory: $subcategory, status: $status, frequency: $frequency, isCustom: $isCustom, isHidden: $isHidden, addedBy: $addedBy, addedAt: $addedAt, purchasedBy: $purchasedBy, purchasedAt: $purchasedAt, quantity: $quantity, note: $note, purchaseCount: $purchaseCount, order: $order, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$HomePadItemCopyWith<$Res> implements $HomePadItemCopyWith<$Res> {
  factory _$HomePadItemCopyWith(_HomePadItem value, $Res Function(_HomePadItem) _then) = __$HomePadItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String emoji, String category, String subcategory, String status, String frequency, bool isCustom, bool isHidden, String? addedBy, DateTime? addedAt, String? purchasedBy, DateTime? purchasedAt, int quantity, String? note, int purchaseCount, int order, DateTime createdAt
});




}
/// @nodoc
class __$HomePadItemCopyWithImpl<$Res>
    implements _$HomePadItemCopyWith<$Res> {
  __$HomePadItemCopyWithImpl(this._self, this._then);

  final _HomePadItem _self;
  final $Res Function(_HomePadItem) _then;

/// Create a copy of HomePadItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? emoji = null,Object? category = null,Object? subcategory = null,Object? status = null,Object? frequency = null,Object? isCustom = null,Object? isHidden = null,Object? addedBy = freezed,Object? addedAt = freezed,Object? purchasedBy = freezed,Object? purchasedAt = freezed,Object? quantity = null,Object? note = freezed,Object? purchaseCount = null,Object? order = null,Object? createdAt = null,}) {
  return _then(_HomePadItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,emoji: null == emoji ? _self.emoji : emoji // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,subcategory: null == subcategory ? _self.subcategory : subcategory // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as String,isCustom: null == isCustom ? _self.isCustom : isCustom // ignore: cast_nullable_to_non_nullable
as bool,isHidden: null == isHidden ? _self.isHidden : isHidden // ignore: cast_nullable_to_non_nullable
as bool,addedBy: freezed == addedBy ? _self.addedBy : addedBy // ignore: cast_nullable_to_non_nullable
as String?,addedAt: freezed == addedAt ? _self.addedAt : addedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,purchasedBy: freezed == purchasedBy ? _self.purchasedBy : purchasedBy // ignore: cast_nullable_to_non_nullable
as String?,purchasedAt: freezed == purchasedAt ? _self.purchasedAt : purchasedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,purchaseCount: null == purchaseCount ? _self.purchaseCount : purchaseCount // ignore: cast_nullable_to_non_nullable
as int,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
