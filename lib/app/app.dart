import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'bindings/app-binding.dart';
import 'routes/app_pages.dart';
import 'themes/theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'School Management',
      debugShowCheckedModeBanner: false,

      // Routing
      initialRoute: AppPages.SPLASH,
      initialBinding: AppBindings(),
      getPages: AppPages.routes,

      // Theming
      //themeMode: ThemeMode.system,
      theme: AppTheme.lightTheme,
      //darkTheme: AppTheme.darkTheme,

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
      localizationsDelegates: const [
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
    );
  }
}