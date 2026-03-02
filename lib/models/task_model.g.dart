// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Subtask _$SubtaskFromJson(Map<String, dynamic> json) => _Subtask(
  id: json['id'] as String,
  title: json['title'] as String,
  completed: json['completed'] as bool? ?? false,
);

Map<String, dynamic> _$SubtaskToJson(_Subtask instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'completed': instance.completed,
};

_Attachment _$AttachmentFromJson(Map<String, dynamic> json) => _Attachment(
  url: json['url'] as String,
  type: json['type'] as String,
  name: json['name'] as String,
);

Map<String, dynamic> _$AttachmentToJson(_Attachment instance) =>
    <String, dynamic>{
      'url': instance.url,
      'type': instance.type,
      'name': instance.name,
    };

_TaskModel _$TaskModelFromJson(Map<String, dynamic> json) => _TaskModel(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String?,
  status: json['status'] as String? ?? 'todo',
  boardId: json['boardId'] as String,
  assignees:
      (json['assignees'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  dueDate: json['dueDate'] == null
      ? null
      : DateTime.parse(json['dueDate'] as String),
  emojiTag: json['emojiTag'] as String?,
  subtasks:
      (json['subtasks'] as List<dynamic>?)
          ?.map((e) => Subtask.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  attachments:
      (json['attachments'] as List<dynamic>?)
          ?.map((e) => Attachment.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  isWeeklyTask: json['isWeeklyTask'] as bool? ?? false,
  weekStart: json['weekStart'] == null
      ? null
      : DateTime.parse(json['weekStart'] as String),
  order: (json['order'] as num?)?.toInt() ?? 0,
  completedAt: json['completedAt'] == null
      ? null
      : DateTime.parse(json['completedAt'] as String),
  archivedAt: json['archivedAt'] == null
      ? null
      : DateTime.parse(json['archivedAt'] as String),
  isBlocked: json['isBlocked'] as bool? ?? false,
  blockedReason: json['blockedReason'] as String?,
  recurrenceRule: json['recurrenceRule'] as String? ?? 'never',
  createdBy: json['createdBy'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$TaskModelToJson(_TaskModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'status': instance.status,
      'boardId': instance.boardId,
      'assignees': instance.assignees,
      'dueDate': instance.dueDate?.toIso8601String(),
      'emojiTag': instance.emojiTag,
      'subtasks': instance.subtasks,
      'attachments': instance.attachments,
      'isWeeklyTask': instance.isWeeklyTask,
      'weekStart': instance.weekStart?.toIso8601String(),
      'order': instance.order,
      'completedAt': instance.completedAt?.toIso8601String(),
      'archivedAt': instance.archivedAt?.toIso8601String(),
      'isBlocked': instance.isBlocked,
      'blockedReason': instance.blockedReason,
      'recurrenceRule': instance.recurrenceRule,
      'createdBy': instance.createdBy,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
