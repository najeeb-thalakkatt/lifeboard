import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chore_completion_model.freezed.dart';
part 'chore_completion_model.g.dart';

/// A record of a chore being completed.
///
/// Stored in `spaces/{spaceId}/chore_completions/{completionId}`.
/// The [date] field (YYYY-MM-DD) enables querying "done today".
@freezed
abstract class ChoreCompletion with _$ChoreCompletion {
  const factory ChoreCompletion({
    required String id,
    required String choreId,
    /// Denormalized for activity feed display.
    required String choreName,
    required String choreEmoji,
    required String completedBy,
    required DateTime completedAt,
    /// YYYY-MM-DD string for querying completions by date.
    required String date,
    /// UserId who acknowledged ("hat-tipped") this completion.
    String? hatTipBy,
  }) = _ChoreCompletion;

  factory ChoreCompletion.fromJson(Map<String, dynamic> json) =>
      _$ChoreCompletionFromJson(json);

  factory ChoreCompletion.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ChoreCompletion(
      id: doc.id,
      choreId: data['choreId'] as String? ?? '',
      choreName: data['choreName'] as String? ?? '',
      choreEmoji: data['choreEmoji'] as String? ?? '✅',
      completedBy: data['completedBy'] as String? ?? '',
      completedAt:
          (data['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      date: data['date'] as String? ?? '',
      hatTipBy: data['hatTipBy'] as String?,
    );
  }

  static Map<String, dynamic> toFirestore(ChoreCompletion completion) {
    return {
      'choreId': completion.choreId,
      'choreName': completion.choreName,
      'choreEmoji': completion.choreEmoji,
      'completedBy': completion.completedBy,
      'completedAt': Timestamp.fromDate(completion.completedAt),
      'date': completion.date,
      'hatTipBy': completion.hatTipBy,
    };
  }
}
