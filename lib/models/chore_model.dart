import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chore_model.freezed.dart';
part 'chore_model.g.dart';

/// A recurring household chore within a space.
///
/// Chores are cyclical (done → resets → done again), atomic (no subtasks),
/// and binary (needs doing / done today).
@freezed
abstract class Chore with _$Chore {
  const factory Chore({
    required String id,
    required String name,
    @Default('✅') String emoji,

    // ── Recurrence ────────────────────────────────────────────
    /// "one_off" | "daily" | "every_n_days" | "weekly" | "biweekly" | "monthly"
    @Default('weekly') String recurrenceType,

    /// Interval for "every_n_days" (e.g. 3 = every 3 days).
    @Default(1) int recurrenceInterval,

    /// Days of week for "weekly" recurrence (1=Mon..7=Sun).
    @Default([]) List<int> recurrenceDaysOfWeek,

    /// Day of month for "monthly" recurrence.
    @Default(1) int recurrenceDayOfMonth,

    /// "fixed" = next due from schedule, "floating" = next due from completion.
    @Default('floating') String recurrenceMode,

    // ── Assignment & Status ───────────────────────────────────
    /// Null means "anyone can claim it".
    String? assigneeId,

    /// When the chore is next due.
    required DateTime nextDueDate,

    /// When the chore was last completed.
    DateTime? lastCompletedAt,

    /// Who last completed this chore.
    String? lastCompletedBy,

    /// "now" | "regular" | "whenever"
    @Default('regular') String priority,

    // ── Metadata ──────────────────────────────────────────────
    required String createdBy,
    required DateTime createdAt,
    @Default(0) int order,

    /// Whether the chore is archived (e.g. completed one-off chores).
    @Default(false) bool isArchived,
  }) = _Chore;

  factory Chore.fromJson(Map<String, dynamic> json) => _$ChoreFromJson(json);

  /// Creates a [Chore] from a Firestore document snapshot.
  factory Chore.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Chore(
      id: doc.id,
      name: data['name'] as String? ?? '',
      emoji: data['emoji'] as String? ?? '✅',
      recurrenceType: data['recurrenceType'] as String? ?? 'weekly',
      recurrenceInterval: data['recurrenceInterval'] as int? ?? 1,
      recurrenceDaysOfWeek:
          (data['recurrenceDaysOfWeek'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      recurrenceDayOfMonth: data['recurrenceDayOfMonth'] as int? ?? 1,
      recurrenceMode: data['recurrenceMode'] as String? ?? 'floating',
      assigneeId: data['assigneeId'] as String?,
      nextDueDate:
          (data['nextDueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastCompletedAt: (data['lastCompletedAt'] as Timestamp?)?.toDate(),
      lastCompletedBy: data['lastCompletedBy'] as String?,
      priority: data['priority'] as String? ?? 'regular',
      createdBy: data['createdBy'] as String? ?? '',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      order: data['order'] as int? ?? 0,
      isArchived: data['isArchived'] as bool? ?? false,
    );
  }

  /// Converts a [Chore] to a Firestore-compatible map.
  static Map<String, dynamic> toFirestore(Chore chore) {
    return {
      'name': chore.name,
      'emoji': chore.emoji,
      'recurrenceType': chore.recurrenceType,
      'recurrenceInterval': chore.recurrenceInterval,
      'recurrenceDaysOfWeek': chore.recurrenceDaysOfWeek,
      'recurrenceDayOfMonth': chore.recurrenceDayOfMonth,
      'recurrenceMode': chore.recurrenceMode,
      'assigneeId': chore.assigneeId,
      'nextDueDate': Timestamp.fromDate(chore.nextDueDate),
      'lastCompletedAt': chore.lastCompletedAt != null
          ? Timestamp.fromDate(chore.lastCompletedAt!)
          : null,
      'lastCompletedBy': chore.lastCompletedBy,
      'priority': chore.priority,
      'createdBy': chore.createdBy,
      'createdAt': Timestamp.fromDate(chore.createdAt),
      'order': chore.order,
      'isArchived': chore.isArchived,
    };
  }
}
