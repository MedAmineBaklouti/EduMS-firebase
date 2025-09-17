// lib/app/routes/app_pages.dart
import 'package:get/get_navigation/src/routes/get_route.dart';

import '../../modules/splash/splash_view.dart';
import '../../modules/announcement/views/announcement_list_view.dart';
import '../../modules/auth/views/login_view.dart';
import '../../modules/admin_dashboard/views/admin_dashboard_view.dart';
import '../../modules/teachers_dashboard/views/teacher_dashboard_view.dart';
import '../../modules/parents_dashboard/views/parent_dashboard_view.dart';
import '../../modules/admin_dashboard/views/admin_control_view.dart';
import '../../modules/courses/views/admin_courses_view.dart';
import '../../modules/courses/views/teacher_courses_view.dart';
import '../../modules/courses/views/parent_courses_view.dart';

abstract class AppPages {
  static const SPLASH     = '/splash';
  static const LOGIN      = '/login';
  static const ADMIN_HOME = '/admin';
  static const ADMIN_CONTROL = '/admin/control';
  static const TEACHER_HOME = '/teacher';
  static const PARENT_HOME  = '/parent';
  static const ADMIN_COURSES = '/admin/courses';
  static const TEACHER_COURSES = '/teacher/courses';
  static const PARENT_COURSES = '/parent/courses';
  static const ADMIN_ANNOUNCEMENTS = '/admin/announcements';
  static const TEACHER_ANNOUNCEMENTS = '/teacher/announcements';
  static const PARENT_ANNOUNCEMENTS = '/parent/announcements';

  static final routes = [
    GetPage(name: SPLASH,      page: () => SplashView()),
    GetPage(name: LOGIN,       page: () => LoginView()),
    GetPage(name: ADMIN_HOME,  page: () => AdminDashboard()),
    GetPage(name: ADMIN_CONTROL, page: () => AdminControlView()),
    GetPage(name: TEACHER_HOME,page: () => TeacherDashboard()),
    GetPage(name: PARENT_HOME, page: () => ParentDashboard()),
    GetPage(name: ADMIN_COURSES, page: () => AdminCoursesView()),
    GetPage(name: TEACHER_COURSES, page: () => TeacherCoursesView()),
    GetPage(name: PARENT_COURSES, page: () => ParentCoursesView()),
    GetPage(name: ADMIN_ANNOUNCEMENTS, page: () => AnnouncementListView(isAdmin: true)),
    GetPage(name: TEACHER_ANNOUNCEMENTS, page: () => AnnouncementListView(audience: 'teachers')),
    GetPage(name: PARENT_ANNOUNCEMENTS, page: () => AnnouncementListView(audience: 'parents')),
  ];
}
