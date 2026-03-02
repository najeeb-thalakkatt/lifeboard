import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lifeboard/app.dart';
import 'package:lifeboard/firebase_options.dart';
import 'package:lifeboard/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize push notifications once user is signed in
  final notificationService = NotificationService(
    navigatorKey: rootNavigatorKey,
  );
  FirebaseAuth.instance.authStateChanges().listen((user) {
    if (user != null) {
      notificationService.initialize();
      // Ensure Firestore user doc has displayName and photoUrl synced
      _syncUserProfile(user);
    }
  });

  runApp(const ProviderScope(child: LifeboardApp()));
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
