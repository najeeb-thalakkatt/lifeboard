import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'space_model.freezed.dart';
part 'space_model.g.dart';

/// Represents a member within a space.
@freezed
abstract class SpaceMember with _$SpaceMember {
  const factory SpaceMember({
    required String role, // 'owner' | 'member'
    required DateTime joinedAt,
  }) = _SpaceMember;

  factory SpaceMember.fromJson(Map<String, dynamic> json) =>
      _$SpaceMemberFromJson(json);
}

/// Firestore space document model.
@freezed
abstract class SpaceModel with _$SpaceModel {
  const factory SpaceModel({
    required String id,
    required String name,
    required Map<String, SpaceMember> members,
    required String inviteCode,
    @Default([]) List<String> themes,
    required DateTime createdAt,
  }) = _SpaceModel;

  factory SpaceModel.fromJson(Map<String, dynamic> json) =>
      _$SpaceModelFromJson(json);

  /// Create from a Firestore document snapshot.
  factory SpaceModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;

    // Parse members map
    final membersRaw = data['members'] as Map<String, dynamic>? ?? {};
    final members = membersRaw.map((userId, value) {
      final memberData = value as Map<String, dynamic>;
      return MapEntry(
        userId,
        SpaceMember(
          role: memberData['role'] as String? ?? 'member',
          joinedAt:
              (memberData['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        ),
      );
    });

    return SpaceModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      members: members,
      inviteCode: data['inviteCode'] as String? ?? '',
      themes: List<String>.from(data['themes'] as List? ?? []),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to a Firestore-compatible map.
  static Map<String, dynamic> toFirestore(SpaceModel model) {
    return {
      'name': model.name,
      'members': model.members.map((userId, member) => MapEntry(
            userId,
            {
              'role': member.role,
              'joinedAt': Timestamp.fromDate(member.joinedAt),
            },
          )),
      'inviteCode': model.inviteCode,
      'themes': model.themes,
      'createdAt': Timestamp.fromDate(model.createdAt),
    };
  }
}
