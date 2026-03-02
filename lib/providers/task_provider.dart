import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lifeboard/models/task_model.dart';
import 'package:lifeboard/providers/auth_provider.dart';
import 'package:lifeboard/providers/space_provider.dart';

/// Streams tasks for a specific (spaceId, boardId) pair.
final boardTasksProvider = StreamProvider.family<List<TaskModel>,
    ({String spaceId, String boardId})>((ref, params) {
  // Watch auth state so this provider resets on login/logout.
  final authState = ref.watch(authStateProvider);
  if (authState.valueOrNull == null) return const Stream.empty();

  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getTasksForBoard(params.spaceId, params.boardId);
});

/// Notifier for task mutations (create, update, delete, reorder).
class TaskNotifier extends StateNotifier<AsyncValue<void>> {
  TaskNotifier(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  /// Creates a new task with the given title in the specified status column.
  Future<TaskModel?> createTask({
    required String spaceId,
    required String boardId,
    required String title,
    required String status,
    required String userId,
    int order = 0,
  }) async {
    state = const AsyncLoading();
    try {
      final now = DateTime.now();
      final task = TaskModel(
        id: '',
        title: title,
        status: status,
        boardId: boardId,
        assignees: [userId],
        order: order,
        createdBy: userId,
        createdAt: now,
        updatedAt: now,
      );

      final firestoreService = _ref.read(firestoreServiceProvider);
      final created = await firestoreService.createTask(
        spaceId: spaceId,
        task: task,
      );
      state = const AsyncData(null);
      return created;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  /// Updates a task's status and order (for drag-and-drop).
  Future<void> moveTask({
    required String spaceId,
    required String taskId,
    required String newStatus,
    required int newOrder,
  }) async {
    try {
      final fields = <String, dynamic>{
        'status': newStatus,
        'order': newOrder,
      };
      // Mark completedAt when moving to done
      if (newStatus == 'done') {
        fields['completedAt'] = Timestamp.fromDate(DateTime.now());
      } else {
        fields['completedAt'] = null;
      }
      final firestoreService = _ref.read(firestoreServiceProvider);
      await firestoreService.updateTask(
        spaceId: spaceId,
        taskId: taskId,
        fields: fields,
      );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Partially updates a task with the given fields map.
  Future<void> updateTask({
    required String spaceId,
    required String taskId,
    required Map<String, dynamic> fields,
  }) async {
    try {
      final firestoreService = _ref.read(firestoreServiceProvider);
      await firestoreService.updateTask(
        spaceId: spaceId,
        taskId: taskId,
        fields: fields,
      );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Batch reorder tasks within/across columns.
  Future<void> reorderTasks({
    required String spaceId,
    required List<({String taskId, int order, String status})> updates,
  }) async {
    try {
      final firestoreService = _ref.read(firestoreServiceProvider);
      await firestoreService.batchUpdateTaskOrders(
        spaceId: spaceId,
        updates: updates,
      );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Deletes a task.
  Future<void> deleteTask({
    required String spaceId,
    required String taskId,
  }) async {
    state = const AsyncLoading();
    try {
      final firestoreService = _ref.read(firestoreServiceProvider);
      await firestoreService.deleteTask(
        spaceId: spaceId,
        taskId: taskId,
      );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

/// Provides the [TaskNotifier] for task mutations.
final taskActionProvider =
    StateNotifierProvider<TaskNotifier, AsyncValue<void>>((ref) {
  return TaskNotifier(ref);
});
