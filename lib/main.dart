import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
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
  final notificationService = NotificationService();
  FirebaseAuth.instance.authStateChanges().listen((user) {
    if (user != null) {
      notificationService.initialize();
    }
  });

  runApp(const ProviderScope(child: LifeboardApp()));
}
