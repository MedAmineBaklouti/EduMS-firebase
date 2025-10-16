import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PdfSaveTiming { immediately, prompt }

class SettingsService extends GetxService {
  SettingsService({SharedPreferences? preferences})
      : _preferences = preferences ?? Get.find<SharedPreferences>();

  static const _themeModeKey = 'settings.themeMode';
  static const _languageKey = 'settings.language';
  static const _pdfSaveTimingKey = 'settings.pdfSaveTiming';

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
  static List<PdfSaveTiming> get supportedPdfSaveTimings => PdfSaveTiming.values;

  final SharedPreferences _preferences;

  final Rx<ThemeMode> themeMode = ThemeMode.system.obs;
  final Rx<Locale> locale = fallbackLocale.obs;
  final Rx<PdfSaveTiming> pdfSaveTiming = PdfSaveTiming.immediately.obs;

  Future<SettingsService> init() async {
    _loadThemeMode();
    _loadLanguage();
    _loadPdfSaveTiming();
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

  void setPdfSaveTiming(PdfSaveTiming timing) {
    if (pdfSaveTiming.value == timing) {
      return;
    }
    pdfSaveTiming.value = timing;
    _preferences.setString(_pdfSaveTimingKey, timing.name);
  }

  Future<bool> confirmPdfSave() async {
    if (pdfSaveTiming.value != PdfSaveTiming.prompt) {
      return true;
    }

    final shouldSave = await Get.dialog<bool>(
      AlertDialog(
        title: Text('settings_pdf_save_confirm_title'.tr),
        content: Text('settings_pdf_save_confirm_message'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('settings_pdf_save_confirm_negative'.tr),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: Text('settings_pdf_save_confirm_positive'.tr),
          ),
        ],
      ),
      barrierDismissible: true,
    );

    return shouldSave ?? false;
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

  void _loadPdfSaveTiming() {
    final stored = _preferences.getString(_pdfSaveTimingKey);
    if (stored == null) {
      pdfSaveTiming.value = PdfSaveTiming.immediately;
      return;
    }

    pdfSaveTiming.value = PdfSaveTiming.values.firstWhere(
      (timing) => timing.name == stored,
      orElse: () => PdfSaveTiming.immediately,
    );
  }
}
