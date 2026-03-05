// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserModel _$UserModelFromJson(Map<String, dynamic> json) => _UserModel(
  id: json['id'] as String,
  displayName: json['displayName'] as String,
  email: json['email'] as String,
  photoUrl: json['photoUrl'] as String?,
  moodEmoji: json['moodEmoji'] as String?,
  spaceIds:
      (json['spaceIds'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  notificationPrefs: json['notificationPrefs'] == null
      ? const NotificationPrefs()
      : NotificationPrefs.fromJson(
          json['notificationPrefs'] as Map<String, dynamic>,
        ),
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$UserModelToJson(_UserModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'displayName': instance.displayName,
      'email': instance.email,
      'photoUrl': instance.photoUrl,
      'moodEmoji': instance.moodEmoji,
      'spaceIds': instance.spaceIds,
      'notificationPrefs': instance.notificationPrefs,
      'createdAt': instance.createdAt.toIso8601String(),
    };

_NotificationPrefs _$NotificationPrefsFromJson(Map<String, dynamic> json) =>
    _NotificationPrefs(
      pushEnabled: json['pushEnabled'] as bool? ?? true,
      emailEnabled: json['emailEnabled'] as bool? ?? true,
      homePadUpdates: json['homePadUpdates'] as bool? ?? true,
      homePadComplete: json['homePadComplete'] as bool? ?? true,
    );

Map<String, dynamic> _$NotificationPrefsToJson(_NotificationPrefs instance) =>
    <String, dynamic>{
      'pushEnabled': instance.pushEnabled,
      'emailEnabled': instance.emailEnabled,
      'homePadUpdates': instance.homePadUpdates,
      'homePadComplete': instance.homePadComplete,
    };
