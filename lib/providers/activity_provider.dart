import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lifeboard/models/activity_model.dart';
import 'package:lifeboard/providers/space_provider.dart';
import 'package:lifeboard/services/notification_service.dart';

/// Provides the [NotificationService] singleton.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Streams aggregated activity feed across all user's spaces.
final activityFeedProvider = StreamProvider<List<ActivityModel>>((ref) {
  final spacesAsync = ref.watch(userSpacesProvider);

  return spacesAsync.when(
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
    data: (spaces) {
      if (spaces.isEmpty) return Stream.value([]);

      final spaceIds = spaces.map((s) => s.id).toList();
      final firestoreService = ref.read(firestoreServiceProvider);

      // Use Rx-style merge: listen to each space's activity stream
      // and combine into a single sorted list.
      final streams = spaceIds
          .map((id) => firestoreService.getActivity(id, limit: 30));

      // Combine all streams into one
      return _combineActivityStreams(streams.toList(), limit: 50);
    },
  );
});

/// Combines multiple activity streams into a single sorted stream.
Stream<List<ActivityModel>> _combineActivityStreams(
  List<Stream<List<ActivityModel>>> streams, {
  int limit = 50,
}) {
  if (streams.isEmpty) return Stream.value([]);
  if (streams.length == 1) return streams.first;

  // Use a StreamController to merge all streams
  final controller = StreamController<List<ActivityModel>>();
  final latestValues = List<List<ActivityModel>>.filled(streams.length, []);
  final subscriptions = <StreamSubscription<List<ActivityModel>>>[];

  for (int i = 0; i < streams.length; i++) {
    final sub = streams[i].listen(
      (items) {
        latestValues[i] = items;
        // Merge all latest values
        final merged = latestValues.expand((list) => list).toList();
        merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        controller.add(merged.take(limit).toList());
      },
      onError: (error) => controller.addError(error),
    );
    subscriptions.add(sub);
  }

  controller.onCancel = () {
    for (final sub in subscriptions) {
      sub.cancel();
    }
  };

  return controller.stream;
}

/// Streams the unread activity count for the badge.
final unreadActivityCountProvider = StreamProvider<int>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(0);

  // Listen to the user doc for lastActivityReadAt changes
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .asyncMap((userDoc) async {
    if (!userDoc.exists) return 0;
    final data = userDoc.data()!;
    final lastRead =
        (data['lastActivityReadAt'] as Timestamp?)?.toDate() ??
            DateTime(2000);
    final spaceIds = List<String>.from(data['spaceIds'] as List? ?? []);

    if (spaceIds.isEmpty) return 0;

    final firestoreService = ref.read(firestoreServiceProvider);
    return firestoreService.getUnreadActivityCount(
      spaceIds: spaceIds,
      lastReadAt: lastRead,
    );
  });
});

/// Notifier for activity feed actions (reactions, mark-read).
class ActivityNotifier extends StateNotifier<AsyncValue<void>> {
  ActivityNotifier(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  /// Toggles a reaction emoji on an activity item.
  Future<void> toggleReaction({
    required String spaceId,
    required String activityId,
    required String emoji,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final firestoreService = _ref.read(firestoreServiceProvider);
      await firestoreService.toggleActivityReaction(
        spaceId: spaceId,
        activityId: activityId,
        emoji: emoji,
        userId: userId,
      );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Marks all activity as read (updates last-read timestamp).
  Future<void> markAllRead() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final firestoreService = _ref.read(firestoreServiceProvider);
      await firestoreService.updateLastReadActivity(userId: userId);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

/// Provides the [ActivityNotifier] for activity mutations.
final activityActionProvider =
    StateNotifierProvider<ActivityNotifier, AsyncValue<void>>((ref) {
  return ActivityNotifier(ref);
});
