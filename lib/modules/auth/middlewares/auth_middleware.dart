import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:edums/app/routes/app_pages.dart';

class RoleMiddleware extends GetMiddleware {
  final String allowedRole;

  RoleMiddleware(this.allowedRole);

  @override
  RouteSettings? redirect(String? route) {
    final prefs = Get.find<SharedPreferences>();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final savedRole = prefs.getString('userRole');

    if (!isLoggedIn) {
      return const RouteSettings(name: AppPages.LOGIN);
    }

    if (savedRole != allowedRole) {
      return const RouteSettings(name: AppPages.LOGIN); // Or UNAUTHORIZED route
    }

    return null; // allow access
  }
}