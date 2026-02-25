import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

/// Firestore user document model.
@freezed
abstract class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String displayName,
    required String email,
    String? photoUrl,
    String? moodEmoji,
    @Default([]) List<String> spaceIds,
    @Default(NotificationPrefs()) NotificationPrefs notificationPrefs,
    required DateTime createdAt,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  /// Create from a Firestore document snapshot.
  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserModel(
      id: doc.id,
      displayName: data['displayName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      moodEmoji: data['moodEmoji'] as String?,
      spaceIds: List<String>.from(data['spaceIds'] as List? ?? []),
      notificationPrefs: data['notificationPrefs'] != null
          ? NotificationPrefs(
              pushEnabled:
                  (data['notificationPrefs'] as Map)['pushEnabled'] as bool? ??
                      true,
              emailEnabled:
                  (data['notificationPrefs'] as Map)['emailEnabled'] as bool? ??
                      true,
            )
          : const NotificationPrefs(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to a Firestore-compatible map.
  static Map<String, dynamic> toFirestore(UserModel model) {
    return {
      'displayName': model.displayName,
      'email': model.email,
      'photoUrl': model.photoUrl,
      'moodEmoji': model.moodEmoji,
      'spaceIds': model.spaceIds,
      'notificationPrefs': {
        'pushEnabled': model.notificationPrefs.pushEnabled,
        'emailEnabled': model.notificationPrefs.emailEnabled,
      },
      'createdAt': Timestamp.fromDate(model.createdAt),
    };
  }
}

@freezed
abstract class NotificationPrefs with _$NotificationPrefs {
  const factory NotificationPrefs({
    @Default(true) bool pushEnabled,
    @Default(true) bool emailEnabled,
  }) = _NotificationPrefs;

  factory NotificationPrefs.fromJson(Map<String, dynamic> json) =>
      _$NotificationPrefsFromJson(json);
}
