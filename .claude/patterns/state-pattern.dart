// Pattern: Riverpod state management (StreamProvider + StateNotifier)
// Source: lib/providers/task_provider.dart
// Usage: All entity providers follow this dual pattern

import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── 1. StreamProvider for real-time reads ──────────────────
// Use StreamProvider.family when data depends on parameters.
// Always watch authStateProvider to reset on login/logout.

final itemsProvider = StreamProvider.family<List<ItemModel>,
    ({String spaceId, String collectionId})>((ref, params) {
  final authState = ref.watch(authStateProvider);
  if (authState.valueOrNull == null) return const Stream.empty();

  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getItems(params.spaceId, params.collectionId);
});

// ── 2. StateNotifier for mutations ─────────────────────────
// Wraps async operations with AsyncValue for loading/error states.

class ItemNotifier extends StateNotifier<AsyncValue<void>> {
  ItemNotifier(this._ref) : super(const AsyncData(null));
  final Ref _ref;

  Future<void> createItem({
    required String spaceId,
    required String title,
  }) async {
    state = const AsyncLoading();
    try {
      final service = _ref.read(firestoreServiceProvider);
      await service.createItem(spaceId: spaceId, title: title);

      // Log activity after successful mutation
      _ref.read(activityLoggerProvider).log(
            type: 'item_created',
            message: 'Created "$title"',
          );

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

// Provider for the notifier
final itemNotifierProvider =
    StateNotifierProvider<ItemNotifier, AsyncValue<void>>(
  (ref) => ItemNotifier(ref),
);

// Key points:
// 1. StreamProvider for reads (real-time), StateNotifier for writes
// 2. Always guard with auth check: if (auth == null) return Stream.empty()
// 3. Use .family when provider needs parameters
// 4. Set state = AsyncLoading() before async ops, AsyncData/AsyncError after
// 5. Log activity after successful mutations
