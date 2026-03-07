// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chore_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Chore _$ChoreFromJson(Map<String, dynamic> json) => _Chore(
  id: json['id'] as String,
  name: json['name'] as String,
  emoji: json['emoji'] as String? ?? '✅',
  recurrenceType: json['recurrenceType'] as String? ?? 'weekly',
  recurrenceInterval: (json['recurrenceInterval'] as num?)?.toInt() ?? 1,
  recurrenceDaysOfWeek:
      (json['recurrenceDaysOfWeek'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const [],
  recurrenceDayOfMonth: (json['recurrenceDayOfMonth'] as num?)?.toInt() ?? 1,
  recurrenceMode: json['recurrenceMode'] as String? ?? 'floating',
  assigneeId: json['assigneeId'] as String?,
  nextDueDate: DateTime.parse(json['nextDueDate'] as String),
  lastCompletedAt: json['lastCompletedAt'] == null
      ? null
      : DateTime.parse(json['lastCompletedAt'] as String),
  lastCompletedBy: json['lastCompletedBy'] as String?,
  priority: json['priority'] as String? ?? 'regular',
  createdBy: json['createdBy'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  order: (json['order'] as num?)?.toInt() ?? 0,
  isArchived: json['isArchived'] as bool? ?? false,
);

Map<String, dynamic> _$ChoreToJson(_Chore instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'emoji': instance.emoji,
  'recurrenceType': instance.recurrenceType,
  'recurrenceInterval': instance.recurrenceInterval,
  'recurrenceDaysOfWeek': instance.recurrenceDaysOfWeek,
  'recurrenceDayOfMonth': instance.recurrenceDayOfMonth,
  'recurrenceMode': instance.recurrenceMode,
  'assigneeId': instance.assigneeId,
  'nextDueDate': instance.nextDueDate.toIso8601String(),
  'lastCompletedAt': instance.lastCompletedAt?.toIso8601String(),
  'lastCompletedBy': instance.lastCompletedBy,
  'priority': instance.priority,
  'createdBy': instance.createdBy,
  'createdAt': instance.createdAt.toIso8601String(),
  'order': instance.order,
  'isArchived': instance.isArchived,
};
