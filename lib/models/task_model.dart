import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_model.freezed.dart';
part 'task_model.g.dart';

/// A subtask within a task.
@freezed
abstract class Subtask with _$Subtask {
  const factory Subtask({
    required String id,
    required String title,
    @Default(false) bool completed,
  }) = _Subtask;

  factory Subtask.fromJson(Map<String, dynamic> json) =>
      _$SubtaskFromJson(json);
}

/// A file attachment on a task.
@freezed
abstract class Attachment with _$Attachment {
  const factory Attachment({
    required String url,
    required String type,
    required String name,
  }) = _Attachment;

  factory Attachment.fromJson(Map<String, dynamic> json) =>
      _$AttachmentFromJson(json);
}

/// Firestore task document model.
@freezed
abstract class TaskModel with _$TaskModel {
  const factory TaskModel({
    required String id,
    required String title,
    String? description,
    @Default('todo') String status, // 'todo' | 'in_progress' | 'done'
    required String boardId,
    @Default([]) List<String> assignees,
    DateTime? dueDate,
    String? emojiTag,
    @Default([]) List<Subtask> subtasks,
    @Default([]) List<Attachment> attachments,
    @Default(false) bool isWeeklyTask,
    DateTime? weekStart,
    @Default(0) int order,
    DateTime? completedAt,
    /// When non-null, the task is archived and hidden from the board.
    DateTime? archivedAt,
    /// Whether this task is blocked.
    @Default(false) bool isBlocked,
    /// Reason why the task is blocked.
    String? blockedReason,
    /// Recurrence rule: 'never' | 'daily' | 'weekly' | 'biweekly' | 'monthly'
    @Default('never') String recurrenceRule,
    required String createdBy,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _TaskModel;

  factory TaskModel.fromJson(Map<String, dynamic> json) =>
      _$TaskModelFromJson(json);

  /// Create from a Firestore document snapshot.
  factory TaskModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return TaskModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String?,
      status: data['status'] as String? ?? 'todo',
      boardId: data['boardId'] as String? ?? '',
      assignees: List<String>.from(data['assignees'] as List? ?? []),
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      emojiTag: data['emojiTag'] as String?,
      subtasks: (data['subtasks'] as List? ?? [])
          .map((s) => Subtask.fromJson(Map<String, dynamic>.from(s as Map)))
          .toList(),
      attachments: (data['attachments'] as List? ?? [])
          .map((a) =>
              Attachment.fromJson(Map<String, dynamic>.from(a as Map)))
          .toList(),
      isWeeklyTask: data['isWeeklyTask'] as bool? ?? false,
      weekStart: (data['weekStart'] as Timestamp?)?.toDate(),
      order: data['order'] as int? ?? 0,
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      archivedAt: (data['archivedAt'] as Timestamp?)?.toDate(),
      isBlocked: data['isBlocked'] as bool? ?? false,
      blockedReason: data['blockedReason'] as String?,
      recurrenceRule: data['recurrenceRule'] as String? ?? 'never',
      createdBy: data['createdBy'] as String? ?? '',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:
          (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to a Firestore-compatible map.
  static Map<String, dynamic> toFirestore(TaskModel model) {
    return {
      'title': model.title,
      'description': model.description,
      'status': model.status,
      'boardId': model.boardId,
      'assignees': model.assignees,
      'dueDate':
          model.dueDate != null ? Timestamp.fromDate(model.dueDate!) : null,
      'emojiTag': model.emojiTag,
      'subtasks': model.subtasks
          .map((s) => {'id': s.id, 'title': s.title, 'completed': s.completed})
          .toList(),
      'attachments': model.attachments
          .map((a) => {'url': a.url, 'type': a.type, 'name': a.name})
          .toList(),
      'isWeeklyTask': model.isWeeklyTask,
      'weekStart': model.weekStart != null
          ? Timestamp.fromDate(model.weekStart!)
          : null,
      'order': model.order,
      'completedAt': model.completedAt != null
          ? Timestamp.fromDate(model.completedAt!)
          : null,
      'archivedAt': model.archivedAt != null
          ? Timestamp.fromDate(model.archivedAt!)
          : null,
      'isBlocked': model.isBlocked,
      'blockedReason': model.blockedReason,
      'recurrenceRule': model.recurrenceRule,
      'createdBy': model.createdBy,
      'createdAt': Timestamp.fromDate(model.createdAt),
      'updatedAt': Timestamp.fromDate(model.updatedAt),
    };
  }
}
