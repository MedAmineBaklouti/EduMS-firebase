import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app/bindings/app-binding.dart';
import 'my_app.dart';
import 'modules/messaging/services/messaging_push_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ensure background push notifications are handled when the app is
  // terminated or running in the background. This must be set up before
  // Firebase is initialized and before runApp is called so the handler is
  // available as soon as the Flutter engine starts in the background.
  FirebaseMessaging.onBackgroundMessage(messagingBackgroundHandler);

  // Load .env file
  await dotenv.load(fileName: ".env");

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize your GetX bindings (SharedPreferences, AuthService, etc.)
  final binding = AppBindings();
  await binding.dependencies();

  // Launch the app
  runApp(const MyApp());
}