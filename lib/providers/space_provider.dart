import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lifeboard/models/space_model.dart';
import 'package:lifeboard/providers/auth_provider.dart';
import 'package:lifeboard/services/firestore_service.dart';

/// Provides the [FirestoreService] singleton.
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

/// Streams all spaces the current user belongs to.
final userSpacesProvider = StreamProvider<List<SpaceModel>>((ref) {
  // Watch auth state so this provider re-evaluates on login/logout.
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return const Stream.empty();

  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getSpacesForUser(user.uid);
});

/// Streams members of a specific space.
final spaceMembersProvider =
    StreamProvider.family<Map<String, SpaceMember>, String>((ref, spaceId) {
  // Watch auth state so this provider resets on login/logout.
  final authState = ref.watch(authStateProvider);
  if (authState.valueOrNull == null) return const Stream.empty();

  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getSpaceMembers(spaceId);
});

/// Notifier for creating and joining spaces.
class SpaceActionNotifier extends StateNotifier<AsyncValue<void>> {
  SpaceActionNotifier(this._firestoreService) : super(const AsyncData(null));

  final FirestoreService _firestoreService;

  /// Creates a new space and returns it.
  Future<SpaceModel> createSpace({
    required String name,
    required String userId,
  }) async {
    state = const AsyncLoading();
    try {
      final space = await _firestoreService.createSpace(
        name: name,
        userId: userId,
      );
      state = const AsyncData(null);
      return space;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Joins an existing space via invite code.
  Future<SpaceModel> joinSpace({
    required String inviteCode,
    required String userId,
  }) async {
    state = const AsyncLoading();
    try {
      final space = await _firestoreService.joinSpace(
        inviteCode: inviteCode,
        userId: userId,
      );
      state = const AsyncData(null);
      return space;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

/// Provides the [SpaceActionNotifier] for create/join mutations.
final spaceActionProvider =
    StateNotifierProvider<SpaceActionNotifier, AsyncValue<void>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return SpaceActionNotifier(firestoreService);
});

/// Provides resolved member profiles (userId → displayName) for a space.
///
/// Watches the space members list, then resolves each user's Firestore doc
/// to get their real displayName instead of raw UIDs.
// ── Global Selected Space ──────────────────────────────────────────

const _selectedSpaceKey = 'selected_space_id';

/// Manages the globally selected space across all tabs.
/// Persists the selection to SharedPreferences.
class SelectedSpaceNotifier extends StateNotifier<String?> {
  SelectedSpaceNotifier(this._ref) : super(null) {
    _init();
  }

  final Ref _ref;

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString(_selectedSpaceKey);
    final spaces = _ref.read(userSpacesProvider).valueOrNull ?? [];

    if (savedId != null && spaces.any((s) => s.id == savedId)) {
      state = savedId;
    } else if (spaces.isNotEmpty) {
      state = spaces.first.id;
    }

    // React to space list changes (e.g. user leaves a space)
    _ref.listen(userSpacesProvider, (_, next) {
      final currentSpaces = next.valueOrNull ?? [];
      if (currentSpaces.isEmpty) {
        state = null;
        return;
      }
      // If current selection is still valid, keep it
      if (state != null && currentSpaces.any((s) => s.id == state)) return;
      // Otherwise fall back to first space
      state = currentSpaces.first.id;
    });
  }

  Future<void> select(String spaceId) async {
    state = spaceId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedSpaceKey, spaceId);
  }
}

final selectedSpaceProvider =
    StateNotifierProvider<SelectedSpaceNotifier, String?>((ref) {
  return SelectedSpaceNotifier(ref);
});

// ── Member Profiles ───────────────────────────────────────────────

final spaceMemberProfilesProvider =
    Provider.family<Map<String, String>, String>((ref, spaceId) {
  final membersAsync = ref.watch(spaceMembersProvider(spaceId));

  return membersAsync.when(
    loading: () => {},
    error: (_, __) => {},
    data: (members) {
      final profiles = <String, String>{};
      for (final uid in members.keys) {
        final userAsync = ref.watch(userByIdProvider(uid));
        userAsync.when(
          loading: () => profiles[uid] = 'Loading...',
          error: (_, __) => profiles[uid] = 'Member',
          data: (user) {
            if (user != null && user.displayName.isNotEmpty) {
              profiles[uid] = user.displayName;
            } else if (user != null && user.email.isNotEmpty) {
              profiles[uid] = user.email.split('@').first;
            } else {
              profiles[uid] = 'Member';
            }
          },
        );
      }
      return profiles;
    },
  );
});
