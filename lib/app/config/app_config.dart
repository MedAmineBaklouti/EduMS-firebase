import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get apiBaseUrl => _readEnv('API_URL');
  static String get apiKey => _readEnv('API_KEY');
  static String get fcmServerKey => _readEnv('FCM_SERVER_KEY');
  static String get projectId => _readEnv('PROJECT_ID');
  static String get clientEmail => _readEnv('CLIENT_EMAIL');
  static String get privateKeyId => _readEnv('PRIVATE_KEY_ID');
  static String get privateKey => _readEnv('PRIVATE_KEY');

  static String _readEnv(String key) {
    if (dotenv.isInitialized) {
      return dotenv.env[key] ?? '';
    }

    // Fall back to compile-time environment variables so the app can
    // still run (for example during tests) even if dotenv hasn't been
    // loaded yet.
    return String.fromEnvironment(key, defaultValue: '');
  }
}
