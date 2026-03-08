import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'comment_model.freezed.dart';
part 'comment_model.g.dart';

/// Firestore comment document model.
/// Stored at `spaces/{spaceId}/tasks/{taskId}/comments/{commentId}`.
@freezed
abstract class CommentModel with _$CommentModel {
  const factory CommentModel({
    required String id,
    required String text,
    required String authorId,
    @Default({}) Map<String, List<String>> reactions, // emoji → [userIds]
    required DateTime createdAt,
  }) = _CommentModel;

  factory CommentModel.fromJson(Map<String, dynamic> json) =>
      _$CommentModelFromJson(json);

  /// Create from a Firestore document snapshot.
  factory CommentModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return CommentModel(
      id: doc.id,
      text: data['text'] as String? ?? '',
      authorId: data['authorId'] as String? ?? '',
      reactions: _parseReactions(data['reactions']),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to a Firestore-compatible map.
  static Map<String, dynamic> toFirestore(CommentModel model) {
    return {
      'text': model.text,
      'authorId': model.authorId,
      'reactions': model.reactions.map(
        MapEntry.new,
      ),
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
