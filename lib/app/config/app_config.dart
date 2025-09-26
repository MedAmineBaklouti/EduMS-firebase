import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get apiBaseUrl => _readEnv('API_URL');
  static String get apiKey => _readEnv('API_KEY');

  static String _readEnv(String key) {
    if (dotenv.isInitialized) {
      return dotenv.env[key] ?? '';
    }

    // Fall back to compile-time environment variables so the app can
    // still run (for example during tests) even if dotenv hasn't been
    // loaded yet.
    return const String.fromEnvironment(key, defaultValue: '');
  }
}
