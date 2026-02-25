import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lifeboard/models/comment_model.dart';
import 'package:lifeboard/providers/space_provider.dart';

/// Streams comments for a specific (spaceId, taskId) pair in real-time.
final taskCommentsProvider = StreamProvider.family<List<CommentModel>,
    ({String spaceId, String taskId})>((ref, params) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getComments(
    spaceId: params.spaceId,
    taskId: params.taskId,
  );
});

/// Notifier for comment mutations (add comment, toggle reaction).
class CommentNotifier extends StateNotifier<AsyncValue<void>> {
  CommentNotifier(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  /// Adds a new comment to a task.
  Future<CommentModel?> addComment({
    required String spaceId,
    required String taskId,
    required String text,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || text.trim().isEmpty) return null;

    state = const AsyncLoading();
    try {
      final firestoreService = _ref.read(firestoreServiceProvider);
      final comment = await firestoreService.addComment(
        spaceId: spaceId,
        taskId: taskId,
        text: text.trim(),
        authorId: userId,
      );
      state = const AsyncData(null);
      return comment;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  /// Toggles a reaction emoji on a comment.
  Future<void> toggleReaction({
    required String spaceId,
    required String taskId,
    required String commentId,
    required String emoji,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final firestoreService = _ref.read(firestoreServiceProvider);
      await firestoreService.toggleReaction(
        spaceId: spaceId,
        taskId: taskId,
        commentId: commentId,
        emoji: emoji,
        userId: userId,
      );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

/// Provides the [CommentNotifier] for comment mutations.
final commentActionProvider =
    StateNotifierProvider<CommentNotifier, AsyncValue<void>>((ref) {
  return CommentNotifier(ref);
});
