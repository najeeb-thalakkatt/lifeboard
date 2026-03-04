// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'homepad_item_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HomePadItem _$HomePadItemFromJson(Map<String, dynamic> json) => _HomePadItem(
  id: json['id'] as String,
  name: json['name'] as String,
  emoji: json['emoji'] as String? ?? '🛒',
  category: json['category'] as String,
  subcategory: json['subcategory'] as String? ?? '',
  status: json['status'] as String? ?? 'available',
  frequency: json['frequency'] as String? ?? 'as_needed',
  isCustom: json['isCustom'] as bool? ?? false,
  isHidden: json['isHidden'] as bool? ?? false,
  addedBy: json['addedBy'] as String?,
  addedAt: json['addedAt'] == null
      ? null
      : DateTime.parse(json['addedAt'] as String),
  purchasedBy: json['purchasedBy'] as String?,
  purchasedAt: json['purchasedAt'] == null
      ? null
      : DateTime.parse(json['purchasedAt'] as String),
  quantity: (json['quantity'] as num?)?.toInt() ?? 1,
  note: json['note'] as String?,
  purchaseCount: (json['purchaseCount'] as num?)?.toInt() ?? 0,
  order: (json['order'] as num?)?.toInt() ?? 0,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$HomePadItemToJson(_HomePadItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'emoji': instance.emoji,
      'category': instance.category,
      'subcategory': instance.subcategory,
      'status': instance.status,
      'frequency': instance.frequency,
      'isCustom': instance.isCustom,
      'isHidden': instance.isHidden,
      'addedBy': instance.addedBy,
      'addedAt': instance.addedAt?.toIso8601String(),
      'purchasedBy': instance.purchasedBy,
      'purchasedAt': instance.purchasedAt?.toIso8601String(),
      'quantity': instance.quantity,
      'note': instance.note,
      'purchaseCount': instance.purchaseCount,
      'order': instance.order,
      'createdAt': instance.createdAt.toIso8601String(),
    };
