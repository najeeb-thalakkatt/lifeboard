import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lifeboard/models/space_model.dart';
import 'package:lifeboard/services/firestore_service.dart';

/// Provides the [FirestoreService] singleton.
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

/// Streams all spaces the current user belongs to.
final userSpacesProvider = StreamProvider<List<SpaceModel>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return const Stream.empty();

  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getSpacesForUser(user.uid);
});

/// Streams members of a specific space.
final spaceMembersProvider =
    StreamProvider.family<Map<String, SpaceMember>, String>((ref, spaceId) {
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
