import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lifeboard/providers/auth_provider.dart';
import 'package:lifeboard/providers/space_provider.dart';

/// Summary of task counts for a single space.
class SpaceTaskSummary {
  const SpaceTaskSummary({
    this.todoCount = 0,
    this.inProgressCount = 0,
    this.doneCount = 0,
  });

  final int todoCount;
  final int inProgressCount;
  final int doneCount;

  int get totalCount => todoCount + inProgressCount + doneCount;

  double get completionPercent =>
      totalCount == 0 ? 0 : doneCount / totalCount;
}

/// Streams a [SpaceTaskSummary] for a given space by watching all tasks.
final spaceTaskSummaryProvider =
    StreamProvider.family<SpaceTaskSummary, String>((ref, spaceId) {
  // Watch auth state so this provider resets on login/logout.
  final authState = ref.watch(authStateProvider);
  if (authState.valueOrNull == null) {
    return Stream.value(const SpaceTaskSummary());
  }

  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getAllTasksForSpace(spaceId).handleError(
    (Object _) {
      // Swallow permission errors gracefully — the card will show empty state.
    },
  ).map((tasks) {
    int todo = 0;
    int inProgress = 0;
    int done = 0;
    for (final task in tasks) {
      switch (task.status) {
        case 'todo':
          todo++;
        case 'in_progress':
          inProgress++;
        case 'done':
          done++;
      }
    }
    return SpaceTaskSummary(
      todoCount: todo,
      inProgressCount: inProgress,
      doneCount: done,
    );
  });
});
