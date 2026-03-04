import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:lifeboard/app.dart';
import 'package:lifeboard/firebase_options.dart';
import 'package:lifeboard/models/task_model.dart';
import 'package:lifeboard/services/notification_service.dart';

/// Top-level background message handler — must be a top-level function.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('[FCM-BG] Background message: ${message.messageId}');
  debugPrint('[FCM-BG] Data: ${message.data}');
  debugPrint('[FCM-BG] Notification: ${message.notification?.title} — ${message.notification?.body}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Register background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize push notifications once user is signed in
  final notificationService = NotificationService(
    navigatorKey: rootNavigatorKey,
  );
  FirebaseAuth.instance.authStateChanges().listen((user) async {
    if (user != null) {
      await notificationService.initialize();
      // Ensure Firestore user doc has displayName and photoUrl synced
      _syncUserProfile(user);
      // Reschedule local reminders for all tasks with due dates
      _rescheduleReminders(user.uid, notificationService);
    }
  });

  runApp(const ProviderScope(child: LifeboardApp()));
}

/// Fetches all tasks across user's spaces and reschedules local reminders.
Future<void> _rescheduleReminders(
  String userId,
  NotificationService notificationService,
) async {
  try {
    final db = FirebaseFirestore.instance;
    final userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) return;

    final spaceIds =
        List<String>.from(userDoc.data()?['spaceIds'] as List? ?? []);

    final allTasks = <TaskModel>[];
    for (final spaceId in spaceIds) {
      final snapshot = await db
          .collection('spaces')
          .doc(spaceId)
          .collection('tasks')
          .where('status', isNotEqualTo: 'done')
          .get();
      allTasks.addAll(snapshot.docs.map(TaskModel.fromFirestore));
    }

    await notificationService.rescheduleAllReminders(allTasks);
  } catch (e) {
    debugPrint('[main] Error rescheduling reminders: $e');
  }
}

/// Patches the Firestore user doc if displayName or photoUrl is missing.
/// Handles existing users whose docs were created before these fields were set.
Future<void> _syncUserProfile(User user) async {
  try {
    final docRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final doc = await docRef.get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final updates = <String, dynamic>{};

    final existingName = data['displayName'] as String? ?? '';
    final existingPhoto = data['photoUrl'] as String?;

    if (existingName.isEmpty && (user.displayName ?? '').isNotEmpty) {
      updates['displayName'] = user.displayName;
    }
    if (existingPhoto == null && user.photoURL != null) {
      updates['photoUrl'] = user.photoURL;
    }

    if (updates.isNotEmpty) {
      await docRef.update(updates);
      debugPrint('[main] Synced user profile: $updates');
    }
  } catch (e) {
    debugPrint('[main] Error syncing user profile: $e');
  }
}
