import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lifeboard/models/board_model.dart';
import 'package:lifeboard/models/task_model.dart';
import 'package:lifeboard/providers/auth_provider.dart';
import 'package:lifeboard/providers/space_provider.dart';

// ── Board Filters ────────────────────────────────────────────────

/// Active filters for the board view.
class BoardFilter {
  const BoardFilter({
    this.assigneeId,
    this.emojiTag,
    this.hasDueDate,
    this.isBlocked,
  });

  final String? assigneeId;
  final String? emojiTag;
  final bool? hasDueDate;
  final bool? isBlocked;

  bool get isActive =>
      assigneeId != null ||
      emojiTag != null ||
      hasDueDate == true ||
      isBlocked == true;

  BoardFilter copyWith({
    String? Function()? assigneeId,
    String? Function()? emojiTag,
    bool? Function()? hasDueDate,
    bool? Function()? isBlocked,
  }) {
    return BoardFilter(
      assigneeId: assigneeId != null ? assigneeId() : this.assigneeId,
      emojiTag: emojiTag != null ? emojiTag() : this.emojiTag,
      hasDueDate: hasDueDate != null ? hasDueDate() : this.hasDueDate,
      isBlocked: isBlocked != null ? isBlocked() : this.isBlocked,
    );
  }

  /// Returns true if [task] passes all active filters.
  bool matches(TaskModel task) {
    if (assigneeId != null && !task.assignees.contains(assigneeId)) {
      return false;
    }
    if (emojiTag != null && task.emojiTag != emojiTag) return false;
    if (hasDueDate == true && task.dueDate == null) return false;
    if (isBlocked == true && !task.isBlocked) return false;
    return true;
  }
}

/// Global board filter state — reset when switching boards.
final boardFilterProvider = StateProvider<BoardFilter>((ref) {
  return const BoardFilter();
});

/// Streams all boards for a space.
final boardsProvider =
    StreamProvider.family<List<BoardModel>, String>((ref, spaceId) {
  // Watch auth state so this provider resets on login/logout.
  final authState = ref.watch(authStateProvider);
  if (authState.valueOrNull == null) return const Stream.empty();

  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getBoards(spaceId);
});

/// Currently selected board ID within the board view.
final selectedBoardIdProvider = StateProvider<String?>((ref) => null);

/// Streams a single board document for real-time updates (e.g., WIP limit changes).
final boardStreamProvider = StreamProvider.family<BoardModel?,
    ({String spaceId, String boardId})>((ref, params) {
  final authState = ref.watch(authStateProvider);
  if (authState.valueOrNull == null) return const Stream.empty();

  final firestore = ref.watch(firestoreServiceProvider);
  return firestore.getBoards(params.spaceId).map((boards) {
    try {
      return boards.firstWhere((b) => b.id == params.boardId);
    } catch (_) {
      return null;
    }
  });
});

/// Gets or creates the default board for a space.
final defaultBoardProvider =
    FutureProvider.family<BoardModel, String>((ref, spaceId) async {
  // Watch auth state so this provider resets on login/logout.
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) throw StateError('Not authenticated');

  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getDefaultBoard(
    spaceId: spaceId,
    userId: user.uid,
  );
});
