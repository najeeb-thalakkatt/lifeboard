// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'board_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BoardModel _$BoardModelFromJson(Map<String, dynamic> json) => _BoardModel(
  id: json['id'] as String,
  name: json['name'] as String,
  theme: json['theme'] as String? ?? '',
  columns:
      (json['columns'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const ['todo', 'in_progress', 'done'],
  wipLimits:
      (json['wipLimits'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toInt()),
      ) ??
      const {},
  createdBy: json['createdBy'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$BoardModelToJson(_BoardModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'theme': instance.theme,
      'columns': instance.columns,
      'wipLimits': instance.wipLimits,
      'createdBy': instance.createdBy,
      'createdAt': instance.createdAt.toIso8601String(),
    };
