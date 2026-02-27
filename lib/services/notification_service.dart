import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'package:lifeboard/services/firestore_service.dart';

/// Handles FCM token management, permission requests, and
/// foreground/background notification handling.
class NotificationService {
  NotificationService({
    FirebaseMessaging? messaging,
    FirestoreService? firestoreService,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _firestoreService = firestoreService ?? FirestoreService();

  final FirebaseMessaging _messaging;
  final FirestoreService _firestoreService;

  /// Initializes notification handling for the current platform.
  /// Call this after Firebase is initialized and the user is signed in.
  Future<void> initialize() async {
    // Request permissions (iOS requires explicit request)
    await _requestPermission();

    // Get and save FCM token
    await _saveToken();

    // Listen for token refresh
    _messaging.onTokenRefresh.listen(_saveTokenToFirestore);

    // Configure foreground notification presentation (iOS)
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check if app was opened from a notification (terminated state)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  /// Requests notification permissions.
  /// On iOS, shows the system permission dialog.
  /// On Android 13+, requests POST_NOTIFICATIONS permission.
  Future<void> _requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint(
        '[NotificationService] Permission status: ${settings.authorizationStatus}',
      );
    } catch (e) {
      debugPrint('[NotificationService] Error requesting permission: $e');
    }
  }

  /// Gets the current FCM token and saves it to Firestore.
  Future<void> _saveToken() async {
    try {
      String? token;

      if (kIsWeb) {
        // Web requires a VAPID key — skip if not configured
        token = await _messaging.getToken();
      } else {
        token = await _messaging.getToken();
      }

      if (token != null) {
        await _saveTokenToFirestore(token);
      }
    } catch (e) {
      debugPrint('[NotificationService] Error getting FCM token: $e');
    }
  }

  /// Persists the FCM token to the current user's Firestore doc.
  Future<void> _saveTokenToFirestore(String token) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestoreService.saveFcmToken(userId: userId, token: token);
      debugPrint('[NotificationService] Token saved for user $userId');
    } catch (e) {
      debugPrint('[NotificationService] Error saving token: $e');
    }
  }

  /// Handles a notification received while the app is in the foreground.
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint(
      '[NotificationService] Foreground message: ${message.notification?.title}',
    );
    // The notification is automatically displayed on iOS/Android
    // via setForegroundNotificationPresentationOptions.
    // For custom in-app banners, you could show a snackbar or overlay here.
  }

  /// Handles taps on notifications (background + terminated state).
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint(
      '[NotificationService] Notification tapped: ${message.data}',
    );
    // Navigation based on notification data can be wired here.
    // The data payload includes 'type' and 'spaceId' from Cloud Functions.
  }

  /// Removes the current FCM token (call on sign out).
  Future<void> removeToken() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _firestoreService.removeFcmToken(userId: userId, token: token);
      }
      await _messaging.deleteToken();
      debugPrint('[NotificationService] Token removed');
    } catch (e) {
      debugPrint('[NotificationService] Error removing token: $e');
    }
  }

  /// Subscribes to a topic (e.g. space-level notifications).
  Future<void> subscribeToTopic(String topic) async {
    if (kIsWeb) return; // Topic messaging not supported on web
    await _messaging.subscribeToTopic(topic);
  }

  /// Unsubscribes from a topic.
  Future<void> unsubscribeFromTopic(String topic) async {
    if (kIsWeb) return;
    await _messaging.unsubscribeFromTopic(topic);
  }
}
