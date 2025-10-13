import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app/routes/app_pages.dart';
import 'app/themes/theme.dart';
import 'app/translations/app_translations.dart';
import 'core/services/settings_service.dart';

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settingsService = Get.find<SettingsService>();

    return Obx(
      () => GetMaterialApp(
        title: 'School Management',
        debugShowCheckedModeBanner: false,

        // Routing
        initialRoute: AppPages.SPLASH,
        getPages: AppPages.routes,

        // Internationalization
        translations: AppTranslations(),
        locale: settingsService.effectiveLocale,
        supportedLocales: SettingsService.supportedLocales,
        fallbackLocale: SettingsService.fallbackLocale,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],

        // Theming
        themeMode: settingsService.themeMode.value,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,

        // Layout
        builder: (context, child) {
          return Scaffold(
            body: SafeArea(
              top: false,
              bottom: true,
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },

        // Additional recommended settings
        scrollBehavior: const MaterialScrollBehavior().copyWith(
          physics: const BouncingScrollPhysics(),
        ),
      ),
    );
  }
}