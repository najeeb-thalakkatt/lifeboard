import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lifeboard/models/chore_completion_model.dart';
import 'package:lifeboard/models/chore_model.dart';
import 'package:lifeboard/providers/homepad_provider.dart';
import 'package:lifeboard/providers/space_provider.dart';

// ── Common Chores Catalog (cached) ────────────────────────────────

/// Loads and caches the common chores catalog from assets.
/// Returns a flat list of all chore definitions across categories.
final commonChoresCatalogProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final jsonStr =
      await rootBundle.loadString('assets/data/common_chores.json');
  final List<dynamic> data = json.decode(jsonStr) as List<dynamic>;
  final chores = <Map<String, dynamic>>[];
  for (final cat in data) {
    for (final chore in (cat['chores'] as List<dynamic>)) {
      chores.add(chore as Map<String, dynamic>);
    }
  }
  return chores;
});

/// Loads the common chores catalog with category grouping preserved.
final commonChoresCategoriesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final jsonStr =
      await rootBundle.loadString('assets/data/common_chores.json');
  final List<dynamic> data = json.decode(jsonStr) as List<dynamic>;
  return data.cast<Map<String, dynamic>>();
});

// ── Firestore Streams ──────────────────────────────────────────

/// Streams all active (non-archived) chores for a space, ordered by nextDueDate.
final choresStreamProvider =
    StreamProvider.family<List<Chore>, String>((ref, spaceId) {
  final service = ref.watch(firestoreServiceProvider);
  return service.getChores(spaceId).map(
      (chores) => chores.where((c) => !c.isArchived).toList());
});

/// Today's date string (YYYY-MM-DD). Keyed so the provider refreshes at midnight.
final _todayDateStringProvider = Provider<String>((ref) {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
});

/// Streams today's chore completions for a space.
/// Keyed on date string so it refreshes when the date changes.
final todayCompletionsProvider =
    StreamProvider.family<List<ChoreCompletion>, String>((ref, spaceId) {
  final service = ref.watch(firestoreServiceProvider);
  final dateStr = ref.watch(_todayDateStringProvider);
  return service.getCompletionsForDate(spaceId, dateStr);
});

// ── Derived Providers ──────────────────────────────────────────

/// Chores due today or overdue (not yet completed today).
final todayChoresProvider =
    Provider.family<List<Chore>, String>((ref, spaceId) {
  final choresAsync = ref.watch(choresStreamProvider(spaceId));
  final completionsAsync = ref.watch(todayCompletionsProvider(spaceId));
  final chores = choresAsync.valueOrNull ?? [];
  final completions = completionsAsync.valueOrNull ?? [];

  final completedChoreIds = completions.map((c) => c.choreId).toSet();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final endOfToday = today.add(const Duration(days: 1));

  return chores
      .where((c) =>
          c.nextDueDate.isBefore(endOfToday) &&
          !completedChoreIds.contains(c.id))
      .toList()
    ..sort((a, b) {
      // Overdue first, then by priority
      final aOverdue = a.nextDueDate.isBefore(today);
      final bOverdue = b.nextDueDate.isBefore(today);
      if (aOverdue != bOverdue) return aOverdue ? -1 : 1;
      return a.nextDueDate.compareTo(b.nextDueDate);
    });
});

/// Chores coming up in the next 7 days (not due today).
final upcomingChoresProvider =
    Provider.family<List<Chore>, String>((ref, spaceId) {
  final choresAsync = ref.watch(choresStreamProvider(spaceId));
  final chores = choresAsync.valueOrNull ?? [];

  final now = DateTime.now();
  final endOfToday = DateTime(now.year, now.month, now.day + 1);
  final weekAhead = endOfToday.add(const Duration(days: 7));

  return chores
      .where((c) =>
          !c.nextDueDate.isBefore(endOfToday) &&
          c.nextDueDate.isBefore(weekAhead))
      .toList()
    ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
});

/// Badge count: overdue chores for the selected space.
final choreBadgeCountProvider = Provider<int>((ref) {
  final spaceId = ref.watch(selectedHomePadSpaceProvider);
  if (spaceId == null) return 0;

  final todayChores = ref.watch(todayChoresProvider(spaceId));
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  return todayChores.where((c) => c.nextDueDate.isBefore(today)).length;
});

// ── Action Notifier ────────────────────────────────────────────

class ChoreActionNotifier extends StateNotifier<AsyncValue<void>> {
  ChoreActionNotifier(this._ref) : super(const AsyncData(null));

  final Ref _ref;
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  /// Creates a new chore.
  Future<void> addChore({
    required String spaceId,
    required String name,
    required String emoji,
    required String recurrenceType,
    int recurrenceInterval = 1,
    List<int> recurrenceDaysOfWeek = const [],
    int recurrenceDayOfMonth = 1,
    String recurrenceMode = 'floating',
    String? assigneeId,
    String priority = 'regular',
    DateTime? firstDueDate,
  }) async {
    final userId = _userId;
    if (userId == null) return;

    state = const AsyncLoading();
    try {
      final service = _ref.read(firestoreServiceProvider);
      final now = DateTime.now();
      final chore = Chore(
        id: '',
        name: name,
        emoji: emoji,
        recurrenceType: recurrenceType,
        recurrenceInterval: recurrenceInterval,
        recurrenceDaysOfWeek: recurrenceDaysOfWeek,
        recurrenceDayOfMonth: recurrenceDayOfMonth,
        recurrenceMode: recurrenceMode,
        assigneeId: assigneeId,
        nextDueDate: firstDueDate ?? now,
        priority: priority,
        createdBy: userId,
        createdAt: now,
      );
      await service.createChore(spaceId: spaceId, chore: chore);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Bulk-adds multiple chores (from common library) using a WriteBatch.
  Future<void> bulkAddChores({
    required String spaceId,
    required List<Map<String, dynamic>> choreDefs,
  }) async {
    final userId = _userId;
    if (userId == null) return;

    state = const AsyncLoading();
    try {
      final service = _ref.read(firestoreServiceProvider);
      final now = DateTime.now();
      final chores = choreDefs.map((def) => Chore(
            id: '',
            name: def['name'] as String,
            emoji: def['emoji'] as String? ?? '✅',
            recurrenceType: def['recurrenceType'] as String? ?? 'weekly',
            recurrenceInterval: def['recurrenceInterval'] as int? ?? 1,
            nextDueDate: now,
            createdBy: userId,
            createdAt: now,
          )).toList();
      await service.bulkCreateChores(spaceId: spaceId, chores: chores);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Marks a chore as completed.
  /// Returns the completion doc ID for undo support.
  Future<ChoreCompletion?> completeChore({
    required String spaceId,
    required Chore chore,
  }) async {
    final userId = _userId;
    if (userId == null) return null;

    state = const AsyncLoading();
    try {
      final service = _ref.read(firestoreServiceProvider);
      final completion = await service.completeChore(
        spaceId: spaceId,
        chore: chore,
        userId: userId,
      );
      state = const AsyncData(null);
      return completion;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  /// Undoes a chore completion.
  Future<void> undoCompletion({
    required String spaceId,
    required String completionId,
    required String choreId,
    required DateTime previousNextDueDate,
  }) async {
    state = const AsyncLoading();
    try {
      final service = _ref.read(firestoreServiceProvider);
      await service.undoChoreCompletion(
        spaceId: spaceId,
        completionId: completionId,
        choreId: choreId,
        previousNextDueDate: previousNextDueDate,
      );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Skips a chore cycle.
  Future<void> skipChore({
    required String spaceId,
    required Chore chore,
  }) async {
    state = const AsyncLoading();
    try {
      final service = _ref.read(firestoreServiceProvider);
      await service.skipChore(spaceId: spaceId, chore: chore);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Deletes a chore.
  Future<void> deleteChore({
    required String spaceId,
    required String choreId,
  }) async {
    state = const AsyncLoading();
    try {
      final service = _ref.read(firestoreServiceProvider);
      await service.deleteChore(spaceId: spaceId, choreId: choreId);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Updates an existing chore.
  Future<void> updateChore({
    required String spaceId,
    required String choreId,
    required Map<String, dynamic> fields,
  }) async {
    state = const AsyncLoading();
    try {
      final service = _ref.read(firestoreServiceProvider);
      await service.updateChore(
        spaceId: spaceId,
        choreId: choreId,
        fields: fields,
      );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Sends a hat-tip on a partner's completion.
  Future<void> hatTip({
    required String spaceId,
    required String completionId,
  }) async {
    final userId = _userId;
    if (userId == null) return;

    try {
      final service = _ref.read(firestoreServiceProvider);
      await service.hatTipCompletion(
        spaceId: spaceId,
        completionId: completionId,
        userId: userId,
      );
    } catch (_) {
      // Silent fail for hat-tip — non-critical
    }
  }
}

final choreActionProvider =
    StateNotifierProvider<ChoreActionNotifier, AsyncValue<void>>((ref) {
  return ChoreActionNotifier(ref);
});
