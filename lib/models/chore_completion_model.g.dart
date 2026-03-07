// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chore_completion_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChoreCompletion _$ChoreCompletionFromJson(Map<String, dynamic> json) =>
    _ChoreCompletion(
      id: json['id'] as String,
      choreId: json['choreId'] as String,
      choreName: json['choreName'] as String,
      choreEmoji: json['choreEmoji'] as String,
      completedBy: json['completedBy'] as String,
      completedAt: DateTime.parse(json['completedAt'] as String),
      date: json['date'] as String,
      hatTipBy: json['hatTipBy'] as String?,
    );

Map<String, dynamic> _$ChoreCompletionToJson(_ChoreCompletion instance) =>
    <String, dynamic>{
      'id': instance.id,
      'choreId': instance.choreId,
      'choreName': instance.choreName,
      'choreEmoji': instance.choreEmoji,
      'completedBy': instance.completedBy,
      'completedAt': instance.completedAt.toIso8601String(),
      'date': instance.date,
      'hatTipBy': instance.hatTipBy,
    };
