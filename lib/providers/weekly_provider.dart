import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lifeboard/models/space_model.dart';
import 'package:lifeboard/models/task_model.dart';
import 'package:lifeboard/providers/space_provider.dart';

// ── Week Helpers ──────────────────────────────────────────────────

/// Returns Monday 00:00 of the week containing [date].
DateTime mondayOf(DateTime date) {
  final d = DateTime(date.year, date.month, date.day);
  return d.subtract(Duration(days: d.weekday - 1));
}

/// Returns Sunday 23:59:59 of the week containing [date].
DateTime sundayOf(DateTime date) {
  final monday = mondayOf(date);
  return monday.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
}

// ── Selected Week State ──────────────────────────────────────────

/// Holds the Monday of the currently viewed week.
class SelectedWeekNotifier extends StateNotifier<DateTime> {
  SelectedWeekNotifier() : super(mondayOf(DateTime.now()));

  void goToPreviousWeek() {
    state = state.subtract(const Duration(days: 7));
  }

  void goToNextWeek() {
    state = state.add(const Duration(days: 7));
  }

  void goToCurrentWeek() {
    state = mondayOf(DateTime.now());
  }
}

final selectedWeekProvider =
    StateNotifierProvider<SelectedWeekNotifier, DateTime>((ref) {
  return SelectedWeekNotifier();
});

// ── All Tasks for All User Spaces ────────────────────────────────

/// Streams all tasks across every space the user belongs to.
/// Returns a flat list of (spaceId, task) pairs for downstream filtering.
final allUserTasksProvider =
    StreamProvider<List<({String spaceId, TaskModel task})>>((ref) {
  final spacesAsync = ref.watch(userSpacesProvider);
  final spaces = spacesAsync.valueOrNull ?? <SpaceModel>[];

  if (spaces.isEmpty) return const Stream.empty();

  final firestoreService = ref.watch(firestoreServiceProvider);

  // Combine streams from all spaces
  final streams = spaces.map((space) {
    return firestoreService.getAllTasksForSpace(space.id).map(
          (tasks) => tasks
              .map((t) => (spaceId: space.id, task: t))
              .toList(),
        );
  }).toList();

  // Merge all space task streams into one
  if (streams.length == 1) return streams.first;

  return _combineStreams(streams);
});

/// Combines multiple streams of task lists into a single stream.
Stream<List<({String spaceId, TaskModel task})>> _combineStreams(
    List<Stream<List<({String spaceId, TaskModel task})>>> streams) async* {
  final latestValues =
      List<List<({String spaceId, TaskModel task})>?>.filled(streams.length, null);
  var initialCount = 0;

  await for (final _ in _mergeIndexed(streams, latestValues, () {
    initialCount++;
  })) {
    // Emit merged list once we have at least one value
    if (initialCount > 0) {
      final merged = <({String spaceId, TaskModel task})>[];
      for (final list in latestValues) {
        if (list != null) merged.addAll(list);
      }
      yield merged;
    }
  }
}

/// Helper that listens to all streams and triggers callback on each event.
Stream<void> _mergeIndexed(
  List<Stream<List<({String spaceId, TaskModel task})>>> streams,
  List<List<({String spaceId, TaskModel task})>?> latestValues,
  void Function() onData,
) {
  return Stream.multi((controller) {
    for (var i = 0; i < streams.length; i++) {
      final index = i;
      streams[index].listen(
        (data) {
          latestValues[index] = data;
          onData();
          controller.add(null);
        },
        onError: controller.addError,
      );
    }
  });
}

// ── Weekly Filtered Tasks ────────────────────────────────────────

/// Tasks marked for the selected week (isWeeklyTask == true, weekStart matches).
final weeklyTasksProvider =
    Provider<List<({String spaceId, TaskModel task})>>((ref) {
  final weekStart = ref.watch(selectedWeekProvider);
  final allAsync = ref.watch(allUserTasksProvider);
  final all = allAsync.valueOrNull ?? [];

  return all.where((entry) {
    final t = entry.task;
    if (!t.isWeeklyTask || t.weekStart == null) return false;
    final taskMonday = mondayOf(t.weekStart!);
    return taskMonday.year == weekStart.year &&
        taskMonday.month == weekStart.month &&
        taskMonday.day == weekStart.day;
  }).toList();
});

/// "My Tasks" — weekly tasks assigned to the current user.
final myWeeklyTasksProvider =
    Provider<List<({String spaceId, TaskModel task})>>((ref) {
  final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final weeklyTasks = ref.watch(weeklyTasksProvider);

  return weeklyTasks
      .where((entry) => entry.task.assignees.contains(userId))
      .toList();
});

/// "Next Up" — tasks with dueDate in the next 7 days that are NOT yet in
/// the weekly plan and are not done.
final nextUpTasksProvider =
    Provider<List<({String spaceId, TaskModel task})>>((ref) {
  final allAsync = ref.watch(allUserTasksProvider);
  final all = allAsync.valueOrNull ?? [];
  final now = DateTime.now();
  final sevenDaysOut = now.add(const Duration(days: 7));

  return all.where((entry) {
    final t = entry.task;
    if (t.status == 'done') return false;
    if (t.isWeeklyTask) return false;
    if (t.dueDate == null) return false;
    return t.dueDate!.isAfter(now.subtract(const Duration(days: 1))) &&
        t.dueDate!.isBefore(sevenDaysOut);
  }).toList();
});

/// Backlog tasks — all non-done tasks that are NOT in the current week's plan.
final backlogTasksProvider =
    Provider<List<({String spaceId, TaskModel task})>>((ref) {
  final weekStart = ref.watch(selectedWeekProvider);
  final allAsync = ref.watch(allUserTasksProvider);
  final all = allAsync.valueOrNull ?? [];

  return all.where((entry) {
    final t = entry.task;
    if (t.status == 'done') return false;
    // Exclude tasks already in THIS week's plan
    if (t.isWeeklyTask && t.weekStart != null) {
      final taskMonday = mondayOf(t.weekStart!);
      if (taskMonday.year == weekStart.year &&
          taskMonday.month == weekStart.month &&
          taskMonday.day == weekStart.day) {
        return false;
      }
    }
    return true;
  }).toList();
});

// ── Weekly Summary Stats ─────────────────────────────────────────

/// Summary of the selected week: total tasks and completed count.
final weeklySummaryProvider = Provider<({int total, int completed})>((ref) {
  final weeklyTasks = ref.watch(weeklyTasksProvider);
  final total = weeklyTasks.length;
  final completed =
      weeklyTasks.where((e) => e.task.status == 'done').length;
  return (total: total, completed: completed);
});
