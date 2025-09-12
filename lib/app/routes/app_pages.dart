// lib/app/routes/app_pages.dart
import 'package:get/get_navigation/src/routes/get_route.dart';

import '../../modules/splash/splash_view.dart';
import '../../modules/auth/views/login_view.dart';
import '../../modules/admin_dashboard/views/admin_dashboard_view.dart';
import '../../modules/teachers_dashboard/views/teacher_dashboard_view.dart';
import '../../modules/parents_dashboard/views/parent_dashboard_view.dart';
import '../../modules/admin_dashboard/views/admin_control_view.dart';
import '../../modules/admin_dashboard/views/announcement_view.dart';

abstract class AppPages {
  static const SPLASH     = '/splash';
  static const LOGIN      = '/login';
  static const ADMIN_HOME = '/admin';
  static const ADMIN_CONTROL = '/admin/control';
  static const ADMIN_ANNOUNCEMENTS = '/admin/announcements';
  static const TEACHER_HOME = '/teacher';
  static const PARENT_HOME  = '/parent';

  static final routes = [
    GetPage(name: SPLASH,      page: () => SplashView()),
    GetPage(name: LOGIN,       page: () => LoginView()),
    GetPage(name: ADMIN_HOME,  page: () => AdminDashboard()),
    GetPage(name: ADMIN_CONTROL, page: () => AdminControlView()),
    GetPage(name: ADMIN_ANNOUNCEMENTS, page: () => AnnouncementView()),
    GetPage(name: TEACHER_HOME,page: () => TeacherDashboard()),
    GetPage(name: PARENT_HOME, page: () => ParentDashboard()),
  ];
}
