import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends GetxService {
  SettingsService({SharedPreferences? preferences})
      : _preferences = preferences ?? Get.find<SharedPreferences>();

  static const _themeModeKey = 'settings.themeMode';
  static const _languageKey = 'settings.language';

  static const fallbackLocale = Locale('en');
  static const supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
    Locale('ar'),
  ];
  static const supportedThemeModes = <ThemeMode>[
    ThemeMode.system,
    ThemeMode.light,
    ThemeMode.dark,
  ];

  final SharedPreferences _preferences;

  final Rx<ThemeMode> themeMode = ThemeMode.system.obs;
  final Rx<Locale> locale = fallbackLocale.obs;

  Future<SettingsService> init() async {
    _loadThemeMode();
    _loadLanguage();
    return this;
  }

  Locale get effectiveLocale => locale.value;

  void setThemeMode(ThemeMode mode) {
    if (themeMode.value == mode) {
      return;
    }
    themeMode.value = mode;
    _preferences.setString(_themeModeKey, mode.name);
  }

  void setLocale(Locale locale) {
    if (this.locale.value == locale) {
      return;
    }
    this.locale.value = locale;
    _preferences.setString(_languageKey, locale.languageCode);
  }

  void _loadThemeMode() {
    final stored = _preferences.getString(_themeModeKey);
    if (stored == null) {
      themeMode.value = ThemeMode.system;
      return;
    }

    themeMode.value = ThemeMode.values.firstWhere(
      (mode) => mode.name == stored,
      orElse: () => ThemeMode.system,
    );
  }

  void _loadLanguage() {
    final stored = _preferences.getString(_languageKey);
    if (stored == null) {
      locale.value = fallbackLocale;
      return;
    }

    final matched = supportedLocales.firstWhere(
      (locale) => locale.languageCode == stored,
      orElse: () => fallbackLocale,
    );
    locale.value = matched;
  }
}
