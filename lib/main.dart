import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app/bindings/app-binding.dart';
import 'my_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env
  try {
    await dotenv.load(fileName: ".env");
    print('.env loaded');
  } catch (e) {
    print('Could not load .env: $e');
  }

  // Initialize Firebase
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print('Firebase init failed: $e');
  }

  // Initialize your GetX bindings (SharedPreferences, AuthService, etc.)
  final binding = AppBindings();
  await binding.dependencies();

  // Launch the app
  runApp(const MyApp());
}
