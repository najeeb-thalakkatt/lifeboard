import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:lifeboard/models/task_model.dart';
import 'package:lifeboard/services/firestore_service.dart';

/// Handles FCM token management, permission requests,
/// foreground/background notification handling, and local notification scheduling.
class NotificationService {
  NotificationService({
    FirebaseMessaging? messaging,
    FirestoreService? firestoreService,
    this.navigatorKey,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _firestoreService = firestoreService ?? FirestoreService();

  final FirebaseMessaging _messaging;
  final FirestoreService _firestoreService;

  /// Navigator key used for deep linking on notification tap.
  final GlobalKey<NavigatorState>? navigatorKey;

  /// Persistent plugin instance for local notifications.
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _localNotificationsInitialized = false;
  bool _timezoneInitialized = false;
  bool _hasNotificationPermission = false;

  /// Maps task IDs to their notification IDs for reliable cancellation.
  final Map<String, int> _taskNotificationIds = {};

  /// Maximum number of retry attempts for failed notifications.
  static const int _maxRetries = 3;

  /// Base delay for exponential backoff in milliseconds.
  static const int _baseDelayMs = 1000;

  /// Generates a unique notification ID for a task.
  /// Uses a combination of task ID hash and timestamp to avoid collisions.
  int _generateNotificationId(String taskId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return (taskId.hashCode ^ timestamp).abs() & 0x7FFFFFFF;
  }

  /// Schedules a notification with retry logic and exponential backoff.
  Future<void> _scheduleNotificationWithRetry({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails details,
    int attempt = 0,
  }) async {
    try {
      await _localNotifications.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      if (attempt < _maxRetries) {
        final delay = _baseDelayMs * (1 << attempt);
        await Future.delayed(Duration(milliseconds: delay));
        await _scheduleNotificationWithRetry(
          id: id,
          title: title,
          body: body,
          scheduledDate: scheduledDate,
          details: details,
          attempt: attempt + 1,
        );
      } else {
        rethrow;
      }
    }
  }

  /// Initializes notification handling for the current platform.
  /// Call this after Firebase is initialized and the user is signed in.
  Future<void> initialize() async {
    if (_initialized) return;

    // Request permissions (iOS requires explicit request)
    await _requestPermission();

    // Create Android notification channel
    await _createAndroidNotificationChannel();

    // Initialize local notifications plugin
    await _initializeLocalNotifications();

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

    _initialized = true;
  }

  /// Initializes the local notifications plugin with platform-specific settings.
  Future<void> _initializeLocalNotifications() async {
    if (kIsWeb || _localNotificationsInitialized) return;

    // Initialize timezone data only once
    if (!_timezoneInitialized) {
      tz.initializeTimeZones();
      _timezoneInitialized = true;
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // Already requested via FCM
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(settings: initSettings);
    _localNotificationsInitialized = true;
  }

  /// Schedules a local notification reminder for a task's due date.
  /// The notification fires at the task's due date/time.
  Future<void> scheduleTaskReminder(TaskModel task) async {
    if (kIsWeb || task.dueDate == null) return;
    if (!_localNotificationsInitialized) return;
    if (!_hasNotificationPermission) return;

    final scheduledDate = tz.TZDateTime.from(task.dueDate!, tz.local);

    // Don't schedule if the due date is in the past
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    final notificationId = _generateNotificationId(task.id);
    _taskNotificationIds[task.id] = notificationId;

    const androidDetails = AndroidNotificationDetails(
      'lifeboard_reminders',
      'Task Reminders',
      channelDescription: 'Reminders for upcoming task due dates',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _scheduleNotificationWithRetry(
        id: notificationId,
        title: 'Task Due',
        body: '"${task.title}" is due now',
        scheduledDate: scheduledDate,
        details: details,
      );
    } catch (_) {
      // Scheduling is best-effort; silently ignore failures.
    }
  }

  /// Cancels a scheduled local notification for a task.
  Future<void> cancelTaskReminder(String taskId) async {
    if (kIsWeb) return;
    try {
      final notificationId = _taskNotificationIds.remove(taskId);
      if (notificationId != null) {
        await _localNotifications.cancel(id: notificationId);
      }
    } catch (_) {
      // Cancellation is best-effort.
    }
  }

  /// Reschedules local notifications for all active tasks with due dates.
  /// Call on app startup after auth.
  Future<void> rescheduleAllReminders(List<TaskModel> tasks) async {
    if (kIsWeb) return;
    if (!_localNotificationsInitialized) return;

    // Cancel all existing reminders first
    await _localNotifications.cancelAll();
    _taskNotificationIds.clear();

    for (final task in tasks) {
      if (task.dueDate != null && task.status != 'done') {
        await scheduleTaskReminder(task);
      }
    }
  }

  /// Creates the Android notification channel used by FCM.
  /// Required on Android 8+ (API 26) for notifications to appear.
  Future<void> _createAndroidNotificationChannel() async {
    if (kIsWeb || !Platform.isAndroid) return;

    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    // FCM channel
    const fcmChannel = AndroidNotificationChannel(
      'lifeboard_updates',
      'Lifeboard Updates',
      description: 'Notifications for task and comment updates',
      importance: Importance.high,
    );

    // Reminders channel
    const reminderChannel = AndroidNotificationChannel(
      'lifeboard_reminders',
      'Task Reminders',
      description: 'Reminders for upcoming task due dates',
      importance: Importance.high,
    );

    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(fcmChannel);
    await androidPlugin?.createNotificationChannel(reminderChannel);
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

      _hasNotificationPermission =
          settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (_) {
      _hasNotificationPermission = false;
    }
  }

  /// Gets the current FCM token and saves it to Firestore.
  Future<void> _saveToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveTokenToFirestore(token);
      }
    } catch (_) {
      // Token retrieval is best-effort.
    }
  }

  /// Persists the FCM token to the current user's Firestore doc.
  Future<void> _saveTokenToFirestore(String token) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestoreService.saveFcmToken(userId: userId, token: token);
    } catch (_) {
      // Token persistence is best-effort.
    }
  }

  /// Handles a notification received while the app is in the foreground.
  void _handleForegroundMessage(RemoteMessage message) {
    // Foreground messages are handled by the system notification display.
  }

  /// Handles taps on notifications (background + terminated state).
  /// Navigates to the relevant screen based on the FCM data payload.
  void _handleNotificationTap(RemoteMessage message) {
    final context = navigatorKey?.currentContext;
    if (context == null) return;

    final type = message.data['type'] as String?;
    final spaceId = message.data['spaceId'] as String?;
    final taskId = message.data['taskId'] as String?;

    // HomePad notifications → open HomePad tab
    if (type == 'homepad_items_added' || type == 'homepad_all_done') {
      GoRouter.of(context).go('/buylist');
      return;
    }

    if (spaceId != null && taskId != null) {
      GoRouter.of(context).push('/board/task/$taskId');
    } else {
      GoRouter.of(context).go('/board');
    }
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
    } catch (_) {
      // Token removal is best-effort.
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

  /// Cleans up resources and cancels all pending notifications.
  /// Call this when the service is no longer needed.
  Future<void> dispose() async {
    if (kIsWeb) return;

    try {
      await _localNotifications.cancelAll();
      _taskNotificationIds.clear();
    } catch (_) {
      // Disposal is best-effort.
    }
  }
}
