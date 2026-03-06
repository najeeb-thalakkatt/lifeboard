import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:lifeboard/core/constants.dart';
import 'package:lifeboard/core/errors/app_exceptions.dart';
import 'package:lifeboard/models/activity_model.dart';
import 'package:lifeboard/models/board_model.dart';
import 'package:lifeboard/models/comment_model.dart';
import 'package:lifeboard/models/homepad_item_model.dart';
import 'package:lifeboard/models/space_model.dart';
import 'package:lifeboard/models/task_model.dart';

/// Wraps Firestore operations for spaces (and later boards/tasks).
class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore, FirebaseFunctions? functions})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions? _functions;

  FirebaseFunctions get _fn => _functions ?? FirebaseFunctions.instance;

  // ── Collection References ──────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _spacesRef =>
      _firestore.collection('spaces');

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> _boardsRef(String spaceId) =>
      _spacesRef.doc(spaceId).collection('boards');

  CollectionReference<Map<String, dynamic>> _tasksRef(String spaceId) =>
      _spacesRef.doc(spaceId).collection('tasks');

  CollectionReference<Map<String, dynamic>> _commentsRef(
          String spaceId, String taskId) =>
      _tasksRef(spaceId).doc(taskId).collection('comments');

  CollectionReference<Map<String, dynamic>> _activityRef(String spaceId) =>
      _spacesRef.doc(spaceId).collection('activity');

  CollectionReference<Map<String, dynamic>> _homePadRef(String spaceId) =>
      _spacesRef.doc(spaceId).collection('homepad_items');

  // ── Space CRUD ─────────────────────────────────────────────

  /// Creates a new space with the given [name], owned by [userId].
  /// Generates a unique invite code and adds the user as owner.
  Future<SpaceModel> createSpace({
    required String name,
    required String userId,
  }) async {
    final inviteCode = _generateInviteCode();

    final now = DateTime.now();

    final space = SpaceModel(
      id: '', // Will be set by Firestore
      name: name,
      members: {
        userId: SpaceMember(role: 'owner', joinedAt: now),
      },
      inviteCode: inviteCode,
      themes: ['Home', 'Kids', 'Finances'],
      createdAt: now,
    );

    final docRef = _spacesRef.doc();
    await docRef.set(SpaceModel.toFirestore(space));

    // Add space ID to the user's spaceIds array (supplementary — the space
    // query uses members.$userId.role, not spaceIds).
    await _usersRef.doc(userId).set({
      'spaceIds': FieldValue.arrayUnion([docRef.id]),
    }, SetOptions(merge: true));

    return space.copyWith(id: docRef.id);
  }

  /// Joins an existing space using an [inviteCode].
  /// Uses a Cloud Function to look up the invite code securely,
  /// then updates membership on the resolved space document.
  /// Returns the joined [SpaceModel] or throws if the code is invalid.
  Future<SpaceModel> joinSpace({
    required String inviteCode,
    required String userId,
  }) async {
    // Look up space ID via Cloud Function (avoids needing broad read access)
    final callable = _fn.httpsCallable('lookupInviteCode');
    final HttpsCallableResult result;
    try {
      result = await callable.call({'inviteCode': inviteCode.toUpperCase()});
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'not-found') {
        throw const SpaceNotFoundException();
      } else if (e.code == 'already-exists') {
        throw const AlreadyMemberException();
      }
      rethrow;
    }

    final spaceId = result.data['spaceId'] as String;

    // Add user as a member
    final now = DateTime.now();
    await _spacesRef.doc(spaceId).update({
      'members.$userId': {
        'role': 'member',
        'joinedAt': Timestamp.fromDate(now),
      },
    });

    await _usersRef.doc(userId).set({
      'spaceIds': FieldValue.arrayUnion([spaceId]),
    }, SetOptions(merge: true));

    // Fetch the updated space document
    final doc = await _spacesRef.doc(spaceId).get();
    return SpaceModel.fromFirestore(doc);
  }

  /// Streams all spaces the [userId] belongs to.
  Stream<List<SpaceModel>> getSpacesForUser(String userId) {
    return _spacesRef
        .where('members.$userId.role', whereIn: ['owner', 'member'])
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SpaceModel.fromFirestore(doc))
            .toList());
  }

  /// Streams the members of a space as a map of userId → SpaceMember.
  Stream<Map<String, SpaceMember>> getSpaceMembers(String spaceId) {
    return _spacesRef.doc(spaceId).snapshots().map((doc) {
      if (!doc.exists) return {};
      final space = SpaceModel.fromFirestore(doc);
      return space.members;
    });
  }

  /// Fetches a single space by ID.
  Future<SpaceModel?> getSpace(String spaceId) async {
    final doc = await _spacesRef.doc(spaceId).get();
    if (!doc.exists) return null;
    return SpaceModel.fromFirestore(doc);
  }

  // ── Board CRUD ─────────────────────────────────────────────

  /// Creates a new board in a space.
  Future<BoardModel> createBoard({
    required String spaceId,
    required String name,
    required String userId,
    String theme = '',
  }) async {
    final now = DateTime.now();
    final board = BoardModel(
      id: '',
      name: name,
      theme: theme,
      createdBy: userId,
      createdAt: now,
    );

    final docRef = _boardsRef(spaceId).doc();
    await docRef.set(BoardModel.toFirestore(board));
    return board.copyWith(id: docRef.id);
  }

  /// Streams all boards in a space.
  Stream<List<BoardModel>> getBoards(String spaceId) {
    return _boardsRef(spaceId).snapshots().map((snapshot) =>
        snapshot.docs.map(BoardModel.fromFirestore).toList());
  }

  /// Gets or creates the default "Home" board for a space.
  Future<BoardModel> getDefaultBoard({
    required String spaceId,
    required String userId,
  }) async {
    final snapshot = await _boardsRef(spaceId).limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      return BoardModel.fromFirestore(snapshot.docs.first);
    }
    return createBoard(
      spaceId: spaceId,
      name: 'Home',
      userId: userId,
    );
  }

  // ── Task CRUD ─────────────────────────────────────────────

  /// Creates a new task in a space.
  Future<TaskModel> createTask({
    required String spaceId,
    required TaskModel task,
  }) async {
    final docRef = _tasksRef(spaceId).doc();
    await docRef.set(TaskModel.toFirestore(task));
    return task.copyWith(id: docRef.id);
  }

  /// Partially updates a task.
  /// [updatedBy] is written so Cloud Functions can attribute the action
  /// to the correct user (not the original creator).
  Future<void> updateTask({
    required String spaceId,
    required String taskId,
    required Map<String, dynamic> fields,
    String? updatedBy,
  }) async {
    fields['updatedAt'] = Timestamp.fromDate(DateTime.now());
    if (updatedBy != null) {
      fields['updatedBy'] = updatedBy;
    }
    await _tasksRef(spaceId).doc(taskId).update(fields);
  }

  /// Deletes a task.
  Future<void> deleteTask({
    required String spaceId,
    required String taskId,
  }) async {
    await _tasksRef(spaceId).doc(taskId).delete();
  }

  /// Streams a single task by spaceId and taskId.
  Stream<TaskModel?> streamTask({
    required String spaceId,
    required String taskId,
  }) {
    return _tasksRef(spaceId)
        .doc(taskId)
        .snapshots()
        .map((doc) => doc.exists ? TaskModel.fromFirestore(doc) : null);
  }

  /// Streams tasks for a specific board, ordered by [order].
  /// Excludes archived tasks (those with archivedAt set).
  Stream<List<TaskModel>> getTasksForBoard(String spaceId, String boardId) {
    return _tasksRef(spaceId)
        .where('boardId', isEqualTo: boardId)
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map(TaskModel.fromFirestore)
            .where((task) => task.archivedAt == null)
            .toList());
  }

  /// Batch-updates task orders and statuses (used for drag-and-drop).
  Future<void> batchUpdateTaskOrders({
    required String spaceId,
    required List<({String taskId, int order, String status})> updates,
  }) async {
    final batch = _firestore.batch();
    final now = Timestamp.fromDate(DateTime.now());
    for (final update in updates) {
      batch.update(_tasksRef(spaceId).doc(update.taskId), {
        'order': update.order,
        'status': update.status,
        'updatedAt': now,
      });
    }
    await batch.commit();
  }

  /// Streams all tasks across all boards in a space.
  Stream<List<TaskModel>> getAllTasksForSpace(String spaceId) {
    return _tasksRef(spaceId)
        .orderBy('order')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(TaskModel.fromFirestore).toList());
  }

  /// Batch-updates the weekly task flags on multiple tasks.
  Future<void> batchSetWeeklyTasks({
    required String spaceId,
    required List<String> taskIds,
    required bool isWeeklyTask,
    required DateTime weekStart,
  }) async {
    final batch = _firestore.batch();
    final now = Timestamp.fromDate(DateTime.now());
    final weekTs = Timestamp.fromDate(weekStart);
    for (final taskId in taskIds) {
      batch.update(_tasksRef(spaceId).doc(taskId), {
        'isWeeklyTask': isWeeklyTask,
        'weekStart': isWeeklyTask ? weekTs : null,
        'updatedAt': now,
      });
    }
    await batch.commit();
  }

  /// Archives all completed tasks for a board.
  Future<int> archiveCompletedTasks({
    required String spaceId,
    required String boardId,
  }) async {
    final snapshot = await _tasksRef(spaceId)
        .where('boardId', isEqualTo: boardId)
        .where('status', isEqualTo: 'done')
        .get();

    final now = Timestamp.fromDate(DateTime.now());
    final batch = _firestore.batch();
    var count = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      // Skip already-archived tasks
      if (data['archivedAt'] != null) continue;
      batch.update(doc.reference, {
        'archivedAt': now,
        'updatedAt': now,
      });
      count++;
    }

    if (count > 0) await batch.commit();
    return count;
  }

  /// Updates WIP limits on a board document.
  Future<void> updateBoardWipLimits({
    required String spaceId,
    required String boardId,
    required Map<String, int> wipLimits,
  }) async {
    await _boardsRef(spaceId).doc(boardId).update({
      'wipLimits': wipLimits,
    });
  }

  // ── Comment CRUD ────────────────────────────────────────────

  /// Adds a comment to a task's comments subcollection.
  Future<CommentModel> addComment({
    required String spaceId,
    required String taskId,
    required String text,
    required String authorId,
  }) async {
    final now = DateTime.now();
    final comment = CommentModel(
      id: '',
      text: text,
      authorId: authorId,
      createdAt: now,
    );
    final docRef = _commentsRef(spaceId, taskId).doc();
    await docRef.set(CommentModel.toFirestore(comment));
    return comment.copyWith(id: docRef.id);
  }

  /// Streams all comments for a task, ordered by creation time.
  Stream<List<CommentModel>> getComments({
    required String spaceId,
    required String taskId,
  }) {
    return _commentsRef(spaceId, taskId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(CommentModel.fromFirestore).toList());
  }

  /// Toggles a reaction emoji for a user on a comment.
  /// If the user already reacted with that emoji, removes it; otherwise adds it.
  Future<void> toggleReaction({
    required String spaceId,
    required String taskId,
    required String commentId,
    required String emoji,
    required String userId,
  }) async {
    final docRef = _commentsRef(spaceId, taskId).doc(commentId);
    final doc = await docRef.get();
    if (!doc.exists) return;

    final comment = CommentModel.fromFirestore(doc);
    final currentUsers = List<String>.from(comment.reactions[emoji] ?? []);

    if (currentUsers.contains(userId)) {
      currentUsers.remove(userId);
    } else {
      currentUsers.add(userId);
    }

    if (currentUsers.isEmpty) {
      await docRef.update({'reactions.$emoji': FieldValue.delete()});
    } else {
      await docRef.update({'reactions.$emoji': currentUsers});
    }
  }

  // ── User Profile ──────────────────────────────────────────

  /// Updates profile fields on the user document.
  Future<void> updateUserProfile({
    required String userId,
    required Map<String, dynamic> fields,
  }) async {
    await _usersRef.doc(userId).update(fields);
  }

  /// Updates notification preferences on the user document.
  Future<void> updateNotificationPrefs({
    required String userId,
    required bool pushEnabled,
    required bool emailEnabled,
    bool homePadUpdates = true,
    bool homePadComplete = true,
  }) async {
    await _usersRef.doc(userId).update({
      'notificationPrefs': {
        'pushEnabled': pushEnabled,
        'emailEnabled': emailEnabled,
        'homePadUpdates': homePadUpdates,
        'homePadComplete': homePadComplete,
      },
    });
  }

  // ── Space Management (Profile) ──────────────────────────────

  /// Leaves a space. Removes the user from the members map and their spaceIds.
  /// If the user is the sole owner and other members exist, transfers ownership.
  Future<void> leaveSpace({
    required String spaceId,
    required String userId,
  }) async {
    final doc = await _spacesRef.doc(spaceId).get();
    if (!doc.exists) return;

    final space = SpaceModel.fromFirestore(doc);
    final member = space.members[userId];
    if (member == null) return;

    final otherMembers = space.members.entries
        .where((e) => e.key != userId)
        .toList();

    // If this is the last member, delete the space entirely
    if (otherMembers.isEmpty) {
      await _spacesRef.doc(spaceId).delete();
      await _usersRef.doc(userId).update({
        'spaceIds': FieldValue.arrayRemove([spaceId]),
      });
      return;
    }

    // If owner and others exist, transfer ownership to the first member
    if (member.role == 'owner') {
      await _spacesRef.doc(spaceId).update({
        'members.${otherMembers.first.key}.role': 'owner',
      });
    }

    // Remove user from space members
    await _spacesRef.doc(spaceId).update({
      'members.$userId': FieldValue.delete(),
    });

    // Remove space from user's spaceIds
    await _usersRef.doc(userId).update({
      'spaceIds': FieldValue.arrayRemove([spaceId]),
    });
  }

  /// Deletes a space entirely. Only callable by owners.
  Future<void> deleteSpace({
    required String spaceId,
    required String userId,
  }) async {
    final doc = await _spacesRef.doc(spaceId).get();
    if (!doc.exists) return;

    final space = SpaceModel.fromFirestore(doc);
    final member = space.members[userId];
    if (member == null || member.role != 'owner') {
      throw Exception('Only the space owner can delete a space');
    }

    // Remove spaceId from all members' spaceIds arrays
    for (final memberId in space.members.keys) {
      await _usersRef.doc(memberId).update({
        'spaceIds': FieldValue.arrayRemove([spaceId]),
      });
    }

    // Delete the space document (subcollections remain but become orphaned)
    await _spacesRef.doc(spaceId).delete();
  }

  /// Returns the total count of completed tasks across all the user's spaces.
  Future<int> getCompletedTaskCount(List<String> spaceIds) async {
    final futures = spaceIds.map((spaceId) =>
      _tasksRef(spaceId)
          .where('status', isEqualTo: 'done')
          .count()
          .get(),
    );
    final results = await Future.wait(futures);
    return results.fold<int>(0, (sum, snap) => sum + (snap.count ?? 0));
  }

  /// Returns completed tasks grouped by week (weekStart = Monday 00:00 UTC)
  /// for streak calculation. Returns dates of weeks with at least 1 completion.
  Future<List<DateTime>> getCompletionWeeks(List<String> spaceIds) async {
    final futures = spaceIds.map((spaceId) =>
      _tasksRef(spaceId)
          .where('status', isEqualTo: 'done')
          .get(),
    );
    final results = await Future.wait(futures);

    final Set<String> weekKeys = {};
    for (final snapshot in results) {
      for (final doc in snapshot.docs) {
        final completedAt = (doc.data()['completedAt'] as Timestamp?)?.toDate();
        if (completedAt != null) {
          // Normalize to Monday of that week
          final monday = completedAt.subtract(
            Duration(days: completedAt.weekday - 1),
          );
          weekKeys.add('${monday.year}-${monday.month}-${monday.day}');
        }
      }
    }
    // Parse back to DateTimes and sort descending
    final weeks = weekKeys.map((k) {
      final parts = k.split('-');
      return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    }).toList()
      ..sort((a, b) => b.compareTo(a));
    return weeks;
  }

  /// Deletes the user's Firestore document and removes them from all spaces.
  Future<void> deleteUserAccount({required String userId}) async {
    // Get all spaces the user belongs to
    final spacesSnapshot = await _spacesRef
        .where('members.$userId.role', whereIn: ['owner', 'member'])
        .get();

    for (final doc in spacesSnapshot.docs) {
      final space = SpaceModel.fromFirestore(doc);
      final member = space.members[userId];

      if (member?.role == 'owner') {
        final others = space.members.keys.where((k) => k != userId).toList();
        if (others.isNotEmpty) {
          // Transfer ownership
          await doc.reference.update({
            'members.${others.first}.role': 'owner',
            'members.$userId': FieldValue.delete(),
          });
        } else {
          // Sole member — delete the space
          await doc.reference.delete();
        }
      } else {
        await doc.reference.update({
          'members.$userId': FieldValue.delete(),
        });
      }
    }

    // Delete user document
    await _usersRef.doc(userId).delete();
  }

  // ── Activity Feed ──────────────────────────────────────────

  /// Streams activity for a space, ordered by most recent first.
  Stream<List<ActivityModel>> getActivity(String spaceId, {int limit = 50}) {
    return _activityRef(spaceId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ActivityModel.fromFirestore(doc, spaceId: spaceId))
            .toList());
  }

  /// Streams activity across multiple spaces, merged and sorted.
  Stream<List<ActivityModel>> getActivityForSpaces(List<String> spaceIds,
      {int limit = 50}) {
    if (spaceIds.isEmpty) return Stream.value([]);

    // Stream each space's activity and merge
    final streams = spaceIds.map((id) => getActivity(id, limit: limit));
    return streams.fold<Stream<List<ActivityModel>>>(
      Stream.value([]),
      (combined, stream) {
        return combined.asyncExpand((existing) {
          return stream.map((newItems) {
            final merged = [...existing, ...newItems];
            merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return merged.take(limit).toList();
          });
        });
      },
    );
  }

  /// Toggles a reaction on an activity item.
  Future<void> toggleActivityReaction({
    required String spaceId,
    required String activityId,
    required String emoji,
    required String userId,
  }) async {
    final docRef = _activityRef(spaceId).doc(activityId);
    final doc = await docRef.get();
    if (!doc.exists) return;

    final activity = ActivityModel.fromFirestore(doc, spaceId: spaceId);
    final currentUsers = List<String>.from(activity.reactions[emoji] ?? []);

    if (currentUsers.contains(userId)) {
      currentUsers.remove(userId);
    } else {
      currentUsers.add(userId);
    }

    if (currentUsers.isEmpty) {
      await docRef.update({'reactions.$emoji': FieldValue.delete()});
    } else {
      await docRef.update({'reactions.$emoji': currentUsers});
    }
  }

  /// Gets unread activity count for a user across spaces.
  /// Compares activity timestamps against user's last-read timestamp.
  Future<int> getUnreadActivityCount({
    required List<String> spaceIds,
    required DateTime lastReadAt,
  }) async {
    int count = 0;
    for (final spaceId in spaceIds) {
      final snapshot = await _activityRef(spaceId)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(lastReadAt))
          .count()
          .get();
      count += snapshot.count ?? 0;
    }
    return count;
  }

  /// Updates the user's last-read activity timestamp.
  Future<void> updateLastReadActivity({required String userId}) async {
    await _usersRef.doc(userId).set({
      'lastActivityReadAt': Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));
  }

  /// Saves FCM token to user document for push notifications.
  Future<void> saveFcmToken({
    required String userId,
    required String token,
  }) async {
    await _usersRef.doc(userId).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
    }, SetOptions(merge: true));
  }

  /// Removes an FCM token from user document.
  Future<void> removeFcmToken({
    required String userId,
    required String token,
  }) async {
    await _usersRef.doc(userId).update({
      'fcmTokens': FieldValue.arrayRemove([token]),
    });
  }

  // ── HomePad CRUD ──────────────────────────────────────────────

  /// Streams all HomePad items for a space (only items stored in Firestore,
  /// i.e. items that have transitioned away from 'available').
  Stream<List<HomePadItem>> getHomePadItems(String spaceId) {
    return _homePadRef(spaceId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(HomePadItem.fromFirestore).toList());
  }

  /// Adds or updates a HomePad item in Firestore.
  Future<void> addHomePadItem({
    required String spaceId,
    required HomePadItem item,
  }) async {
    final docRef = item.id.startsWith('catalog_')
        ? _homePadRef(spaceId).doc(item.id)
        : _homePadRef(spaceId).doc(item.id.isEmpty ? null : item.id);
    await docRef.set(HomePadItem.toFirestore(item), SetOptions(merge: true));
  }

  /// Updates the status of a HomePad item.
  Future<void> updateHomePadItemStatus({
    required String spaceId,
    required String itemId,
    required String status,
    required String userId,
  }) async {
    final now = Timestamp.fromDate(DateTime.now());
    final Map<String, dynamic> fields = {'status': status};

    if (status == 'to_buy') {
      fields['addedBy'] = userId;
      fields['addedAt'] = now;
      fields['purchasedBy'] = null;
      fields['purchasedAt'] = null;
    } else if (status == 'purchased') {
      fields['purchasedBy'] = userId;
      fields['purchasedAt'] = now;
    } else if (status == 'available') {
      fields['addedBy'] = null;
      fields['addedAt'] = null;
      fields['purchasedBy'] = null;
      fields['purchasedAt'] = null;
    }

    await _homePadRef(spaceId).doc(itemId).update(fields);
  }

  /// Batch-marks all "to_buy" items as purchased.
  Future<int> batchMarkAllDone({
    required String spaceId,
    required String userId,
  }) async {
    final snapshot = await _homePadRef(spaceId)
        .where('status', isEqualTo: 'to_buy')
        .get();

    if (snapshot.docs.isEmpty) return 0;

    final now = Timestamp.fromDate(DateTime.now());
    final docs = snapshot.docs;

    // Chunk into batches of 500 (Firestore limit)
    for (var i = 0; i < docs.length; i += 500) {
      final batch = _firestore.batch();
      final chunk = docs.skip(i).take(500);
      for (final doc in chunk) {
        batch.update(doc.reference, {
          'status': 'purchased',
          'purchasedBy': userId,
          'purchasedAt': now,
        });
      }
      await batch.commit();
    }

    return docs.length;
  }

  /// Deletes a HomePad item (custom items only).
  Future<void> deleteHomePadItem({
    required String spaceId,
    required String itemId,
  }) async {
    await _homePadRef(spaceId).doc(itemId).delete();
  }

  /// Clears all purchased HomePad items (moves them back to not stored in Firestore).
  Future<int> clearPurchasedHomePadItems({
    required String spaceId,
  }) async {
    final snapshot = await _homePadRef(spaceId)
        .where('status', isEqualTo: 'purchased')
        .get();

    if (snapshot.docs.isEmpty) return 0;

    final docs = snapshot.docs;

    // Chunk into batches of 500 (Firestore limit)
    for (var i = 0; i < docs.length; i += 500) {
      final batch = _firestore.batch();
      final chunk = docs.skip(i).take(500);
      for (final doc in chunk) {
        final data = doc.data();
        final isCustom = data['isCustom'] as bool? ?? false;
        if (isCustom) {
          // Custom items: reset to available
          batch.update(doc.reference, {
            'status': 'available',
            'purchasedBy': null,
            'purchasedAt': null,
          });
        } else {
          // Prebuilt items: delete the Firestore doc (returns to catalog-only state)
          batch.delete(doc.reference);
        }
      }
      await batch.commit();
    }

    return docs.length;
  }

  // ── Invite Code Generation ─────────────────────────────────

  /// Generates a 6-character alphanumeric invite code.
  /// With 32^6 ≈ 1 billion possibilities, collisions are near-zero.
  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // No I/O/0/1 confusion
    final random = Random.secure();
    final code = List.generate(
      AppConstants.inviteCodeLength,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
    return code;
  }
}