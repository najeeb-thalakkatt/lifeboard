// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ActivityModel _$ActivityModelFromJson(Map<String, dynamic> json) =>
    _ActivityModel(
      id: json['id'] as String,
      type: json['type'] as String,
      actorId: json['actorId'] as String,
      taskId: json['taskId'] as String?,
      spaceId: json['spaceId'] as String,
      message: json['message'] as String,
      reactions:
          (json['reactions'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(
              k,
              (e as List<dynamic>).map((e) => e as String).toList(),
            ),
          ) ??
          const {},
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$ActivityModelToJson(_ActivityModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'actorId': instance.actorId,
      'taskId': instance.taskId,
      'spaceId': instance.spaceId,
      'message': instance.message,
      'reactions': instance.reactions,
      'createdAt': instance.createdAt.toIso8601String(),
    };
