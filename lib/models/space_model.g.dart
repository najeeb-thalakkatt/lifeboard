// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'space_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SpaceMember _$SpaceMemberFromJson(Map<String, dynamic> json) => _SpaceMember(
  role: json['role'] as String,
  joinedAt: DateTime.parse(json['joinedAt'] as String),
);

Map<String, dynamic> _$SpaceMemberToJson(_SpaceMember instance) =>
    <String, dynamic>{
      'role': instance.role,
      'joinedAt': instance.joinedAt.toIso8601String(),
    };

_SpaceModel _$SpaceModelFromJson(Map<String, dynamic> json) => _SpaceModel(
  id: json['id'] as String,
  name: json['name'] as String,
  members: (json['members'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(k, SpaceMember.fromJson(e as Map<String, dynamic>)),
  ),
  inviteCode: json['inviteCode'] as String,
  themes:
      (json['themes'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$SpaceModelToJson(_SpaceModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'members': instance.members,
      'inviteCode': instance.inviteCode,
      'themes': instance.themes,
      'createdAt': instance.createdAt.toIso8601String(),
    };
