import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  /// Returns the configured base URL for the HTTP API.
  ///
  /// The value is read from the `API_URL` environment variable which can be
  /// provided either through a `.env` file (via `flutter_dotenv`) or using
  /// compile-time `--dart-define` values. Because it is easy to accidentally
  /// omit the URL scheme when configuring the value (e.g. providing
  /// `api.example.com` instead of `https://api.example.com`), the result is
  /// normalised before being returned so that the networking layer always
  /// receives a valid absolute URL with a host.
  static String get apiBaseUrl {
    final raw = _readEnv('API_URL').trim();
    if (raw.isEmpty) {
      return '';
    }

    return _normaliseBaseUrl(raw);
  }

  static String get apiKey => _readEnv('API_KEY');

  static String _readEnv(String key) {
    if (dotenv.isInitialized) {
      return dotenv.env[key] ?? '';
    }

    // Fall back to compile-time environment variables so the app can
    // still run (for example during tests) even if dotenv hasn't been
    // loaded yet.
    return String.fromEnvironment(key, defaultValue: '');
  }

  static String _normaliseBaseUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    final hasScheme = trimmed.startsWith(RegExp(r'https?://'));
    final withScheme = hasScheme ? trimmed : 'https://$trimmed';

    final uri = Uri.tryParse(withScheme);
    if (uri == null || uri.host.isEmpty) {
      throw FormatException(
        'API_URL must be a valid absolute URL that includes a host.',
        value,
      );
    }

    final trimmedPath = uri.path.replaceAll(RegExp(r'/+$'), '');
    final normalisedUri = uri.replace(path: trimmedPath);
    return normalisedUri.toString();
  }
}
