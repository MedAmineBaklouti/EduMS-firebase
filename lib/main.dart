import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app/bindings/app-binding.dart';
import 'my_app.dart';
import 'modules/messaging/services/messaging_push_handler.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase before registering background handlers or using any
  // Firebase services. Calling initializeApp early ensures the plugin channel
  // is ready when the background isolate starts.
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e, stackTrace) {
    // Surface the initialization failure instead of silently continuing. Most
    // services depend on Firebase being ready, so rethrowing gives clearer
    // feedback during startup failures.
    debugPrint('Firebase init failed: $e');
    debugPrintStack(stackTrace: stackTrace);
    rethrow;
  }

  // Ensure background push notifications are handled when the app is
  // terminated or running in the background. The handler must be registered
  // after Firebase is initialized so platform channels are available.
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(messagingBackgroundHandler);
  }

  // Load .env
  try {
    await dotenv.load(fileName: ".env");
    print('.env loaded');
  } catch (e) {
    print('Could not load .env: $e');
  }

  // Initialize your GetX bindings (SharedPreferences, AuthService, etc.)
  final binding = AppBindings();
  await binding.dependencies();

  // Launch the app
  runApp(const MyApp());
}
