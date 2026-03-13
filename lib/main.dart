import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:quick_actions_ios/quick_actions_ios.dart';

import 'package:lifeboard/app.dart';
import 'package:lifeboard/firebase_options.dart';
import 'package:lifeboard/models/task_model.dart';
import 'package:lifeboard/services/biometric_service.dart';
import 'package:lifeboard/services/notification_service.dart';
import 'package:lifeboard/screens/lock/app_lock_screen.dart';
import 'package:go_router/go_router.dart';

/// Top-level background message handler — must be a top-level function.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Background message received — no action needed beyond Firebase init.
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Enable Firestore offline persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
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
      unawaited(_syncUserProfile(user));
      // Reschedule local reminders for all tasks with due dates
      unawaited(_rescheduleReminders(user.uid, notificationService));
    }
  });

  // Clear app badge on launch
  if (!kIsWeb) {
    try {
      await FlutterAppBadger.removeBadge();
    } catch (_) {}
  }

  runApp(const ProviderScope(child: LifeboardAppWrapper()));
}

/// Wraps the app with biometric lock and quick action handling.
class LifeboardAppWrapper extends StatefulWidget {
  const LifeboardAppWrapper({super.key});

  @override
  State<LifeboardAppWrapper> createState() => _LifeboardAppWrapperState();
}

class _LifeboardAppWrapperState extends State<LifeboardAppWrapper>
    with WidgetsBindingObserver {
  bool _isLocked = false;
  final _biometricService = BiometricService();
  String? _pendingShortcut;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initQuickActions();
    _initSpotlightHandler();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _initSpotlightHandler() {
    if (kIsWeb || !Platform.isIOS) return;
    const channel = MethodChannel('com.codehive.lifeboard/spotlight');
    channel.setMethodCallHandler((call) async {
      if (call.method == 'onSpotlightTap') {
        final args = call.arguments as Map?;
        final taskId = args?['taskId'] as String?;
        if (taskId != null) {
          final context = rootNavigatorKey.currentContext;
          if (context != null) {
            unawaited(GoRouter.of(context).push('/board/task/$taskId'));
          }
        }
      }
    });
  }

  void _initQuickActions() {
    if (kIsWeb || !Platform.isIOS) return;
    final quickActions = QuickActionsIos();
    quickActions.initialize(_handleShortcut);
    quickActions.setShortcutItems([
      const ShortcutItem(
        type: 'com.codehive.lifeboard.addTask',
        localizedTitle: 'Add Task',
        icon: 'plus',
      ),
      const ShortcutItem(
        type: 'com.codehive.lifeboard.myBoard',
        localizedTitle: 'My Board',
        icon: 'list.bullet.rectangle',
      ),
      const ShortcutItem(
        type: 'com.codehive.lifeboard.buyList',
        localizedTitle: 'Buy List',
        icon: 'cart',
      ),
    ]);
  }

  void _handleShortcut(String type) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) {
      // Store for later if app is still initializing
      _pendingShortcut = type;
      return;
    }

    final router = GoRouter.of(context);
    switch (type) {
      case 'com.codehive.lifeboard.addTask':
        router.go('/board');
        // The board will handle opening create sheet
        break;
      case 'com.codehive.lifeboard.myBoard':
        router.go('/board');
        break;
      case 'com.codehive.lifeboard.buyList':
        router.go('/buylist');
        break;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Clear badge when app comes to foreground
      if (!kIsWeb) {
        try {
          FlutterAppBadger.removeBadge();
        } catch (_) {}
      }
      // Check biometric lock
      _checkBiometricLock();
      // Handle pending shortcut
      if (_pendingShortcut != null) {
        final shortcut = _pendingShortcut!;
        _pendingShortcut = null;
        _handleShortcut(shortcut);
      }
    }
    if (state == AppLifecycleState.paused) {
      _onAppPaused();
    }
  }

  Future<void> _onAppPaused() async {
    final isEnabled = await _biometricService.isEnabled;
    final isAvailable = await _biometricService.isAvailable;
    if (isEnabled && isAvailable && FirebaseAuth.instance.currentUser != null) {
      if (mounted) setState(() => _isLocked = true);
    }
  }

  Future<void> _checkBiometricLock() async {
    if (!_isLocked) return;
    // Lock screen will handle authentication
  }

  @override
  Widget build(BuildContext context) {
    if (_isLocked) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: AppLockScreen(
          onUnlocked: () => setState(() => _isLocked = false),
        ),
      );
    }
    return const LifeboardApp();
  }
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
    // Rescheduling is best-effort; ignore errors.
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
    }
  } catch (_) {
    // Profile sync is best-effort; ignore errors.
  }
}
