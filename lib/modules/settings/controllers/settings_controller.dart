import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_pages.dart';
import '../../../common/services/settings_service.dart';

class SettingsController extends GetxController {
  SettingsController(this._settingsService);

  final SettingsService _settingsService;

  ThemeMode get themeMode => _settingsService.themeMode.value;
  Locale get language => _settingsService.locale.value;

  List<ThemeMode> get themeOptions => SettingsService.supportedThemeModes;
  List<Locale> get languageOptions => SettingsService.supportedLocales;

  void updateThemeMode(ThemeMode? mode) {
    if (mode == null) return;
    _settingsService.setThemeMode(mode);
  }

  void updateLanguage(Locale? locale) {
    if (locale == null) return;
    _settingsService.setLocale(locale);
    Get.updateLocale(locale);
  }

  void openAccount() {
    Get.toNamed(AppPages.EDIT_PROFILE);
  }

  void openSupport() {
    Get.toNamed(AppPages.CONTACT_US);
  }

  String describeThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'settings_theme_light'.tr;
      case ThemeMode.dark:
        return 'settings_theme_dark'.tr;
      case ThemeMode.system:
      default:
        return 'settings_theme_system'.tr;
    }
  }

  String describeLanguage(Locale locale) {
    switch (locale.languageCode) {
      case 'fr':
        return 'settings_language_fr'.tr;
      case 'ar':
        return 'settings_language_ar'.tr;
      case 'en':
      default:
        return 'settings_language_en'.tr;
    }
  }
}
