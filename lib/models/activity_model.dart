import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'activity_model.freezed.dart';
part 'activity_model.g.dart';

/// Firestore activity document model.
/// Stored at `spaces/{spaceId}/activity/{activityId}`.
@freezed
abstract class ActivityModel with _$ActivityModel {
  const factory ActivityModel({
    required String id,
    required String type, // 'task_moved' | 'task_created' | 'task_completed' | 'comment_added' | 'member_joined'
    required String actorId,
    String? taskId,
    required String spaceId,
    required String message,
    @Default({}) Map<String, List<String>> reactions, // emoji → [userIds]
    required DateTime createdAt,
  }) = _ActivityModel;

  factory ActivityModel.fromJson(Map<String, dynamic> json) =>
      _$ActivityModelFromJson(json);

  /// Create from a Firestore document snapshot.
  factory ActivityModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc,
      {required String spaceId}) {
    final data = doc.data()!;
    return ActivityModel(
      id: doc.id,
      type: data['type'] as String? ?? '',
      actorId: data['actorId'] as String? ?? '',
      taskId: data['taskId'] as String?,
      spaceId: spaceId,
      message: data['message'] as String? ?? '',
      reactions: _parseReactions(data['reactions']),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to a Firestore-compatible map.
  static Map<String, dynamic> toFirestore(ActivityModel model) {
    return {
      'type': model.type,
      'actorId': model.actorId,
      'taskId': model.taskId,
      'spaceId': model.spaceId,
      'message': model.message,
      'reactions': model.reactions,
      'createdAt': Timestamp.fromDate(model.createdAt),
    };
  }
}

/// Parses the reactions map from Firestore (emoji to List of userId).
Map<String, List<String>> _parseReactions(dynamic raw) {
  if (raw == null || raw is! Map) return {};
  return raw.map<String, List<String>>(
    (key, value) => MapEntry(
      key.toString(),
      List<String>.from(value as List? ?? []),
    ),
  );
}
