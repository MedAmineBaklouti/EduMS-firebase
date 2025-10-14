// lib/app/routes/app_pages.dart
import 'package:get/get_navigation/src/routes/get_route.dart';

import '../../modules/admin_dashboard/views/admin_control_view.dart';
import '../../modules/admin_dashboard/views/admin_dashboard_view.dart';
import '../../modules/announcement/views/announcement_list_view.dart';
import '../../modules/attendance/views/admin_attendance_view.dart';
import '../../modules/attendance/views/admin_teacher_attendance_view.dart';
import '../../modules/attendance/views/parent_attendance_view.dart';
import '../../modules/attendance/views/teacher_attendance_view.dart';
import '../../modules/auth/views/login_view.dart';
import '../../modules/behavior/views/admin_behavior_list_view.dart';
import '../../modules/behavior/views/parent_behavior_list_view.dart';
import '../../modules/behavior/views/teacher_behavior_list_view.dart';
import '../../modules/courses/views/admin_courses_view.dart';
import '../../modules/courses/views/parent_courses_view.dart';
import '../../modules/courses/views/teacher_courses_view.dart';
import '../../modules/homework/views/admin_homework_list_view.dart';
import '../../modules/homework/views/parent_homework_list_view.dart';
import '../../modules/homework/views/teacher_homework_list_view.dart';
import '../../modules/edu_chat/routes.dart';
import '../../modules/parents_dashboard/views/parent_dashboard_view.dart';
import '../../modules/pickup/views/admin_archived_pickup_view.dart';
import '../../modules/pickup/views/admin_pickup_view.dart';
import '../../modules/messaging/views/messaging_view.dart';
import '../../modules/pickup/views/parent_pickup_view.dart';
import '../../modules/pickup/views/teacher_pickup_view.dart';
import '../../modules/profile/views/contact_us_view.dart';
import '../../modules/profile/views/edit_profile_view.dart';
import '../../modules/settings/bindings/settings_binding.dart';
import '../../modules/settings/views/settings_view.dart';
import '../../modules/splash/splash_view.dart';
import '../../modules/teachers_dashboard/views/teacher_dashboard_view.dart';

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
  static const ADMIN_HOMEWORK = '/admin/homework';
  static const TEACHER_HOMEWORK = '/teacher/homework';
  static const PARENT_HOMEWORK = '/parent/homework';
  static const ADMIN_ATTENDANCE = '/admin/attendance';
  static const ADMIN_TEACHER_ATTENDANCE = '/admin/attendance/teachers';
  static const TEACHER_ATTENDANCE = '/teacher/attendance';
  static const PARENT_ATTENDANCE = '/parent/attendance';
  static const ADMIN_BEHAVIOR = '/admin/behavior';
  static const TEACHER_BEHAVIOR = '/teacher/behavior';
  static const PARENT_BEHAVIOR = '/parent/behavior';
  static const ADMIN_PICKUP = '/admin/pickup';
  static const ADMIN_PICKUP_ARCHIVE = '/admin/pickup/archive';
  static const TEACHER_PICKUP = '/teacher/pickup';
  static const PARENT_PICKUP = '/parent/pickup';
  static const MESSAGING = '/messaging';
  static const EDU_CHAT = EduChatRoutes.chat;
  static const EDIT_PROFILE = '/profile/edit';
  static const CONTACT_US = '/support/contact';
  static const SETTINGS = '/settings';

  static final routes = [
    GetPage(name: SPLASH, page: () => SplashView()),
    GetPage(name: LOGIN, page: () => LoginView()),
    GetPage(name: ADMIN_HOME, page: () => AdminDashboard()),
    GetPage(name: ADMIN_CONTROL, page: () => AdminControlView()),
    GetPage(name: TEACHER_HOME, page: () => TeacherDashboard()),
    GetPage(name: PARENT_HOME, page: () => ParentDashboard()),
    GetPage(name: ADMIN_COURSES, page: () => AdminCoursesView()),
    GetPage(name: TEACHER_COURSES, page: () => TeacherCoursesView()),
    GetPage(name: PARENT_COURSES, page: () => ParentCoursesView()),
    GetPage(
      name: ADMIN_ANNOUNCEMENTS,
      page: () => AnnouncementListView(isAdmin: true),
    ),
    GetPage(
      name: TEACHER_ANNOUNCEMENTS,
      page: () => AnnouncementListView(audience: 'teachers'),
    ),
    GetPage(
      name: PARENT_ANNOUNCEMENTS,
      page: () => AnnouncementListView(audience: 'parents'),
    ),
    GetPage(name: ADMIN_HOMEWORK, page: () => const AdminHomeworkListView()),
    GetPage(
        name: TEACHER_HOMEWORK, page: () => const TeacherHomeworkListView()),
    GetPage(name: PARENT_HOMEWORK, page: () => const ParentHomeworkListView()),
    GetPage(name: ADMIN_ATTENDANCE, page: () => const AdminAttendanceView()),
    GetPage(
        name: ADMIN_TEACHER_ATTENDANCE,
        page: () => const AdminTeacherAttendanceView()),
    GetPage(
        name: TEACHER_ATTENDANCE, page: () => const TeacherAttendanceView()),
    GetPage(
        name: PARENT_ATTENDANCE, page: () => const ParentAttendanceView()),
    GetPage(name: ADMIN_BEHAVIOR, page: () => const AdminBehaviorListView()),
    GetPage(
        name: TEACHER_BEHAVIOR, page: () => const TeacherBehaviorListView()),
    GetPage(
        name: PARENT_BEHAVIOR, page: () => const ParentBehaviorListView()),
    GetPage(name: ADMIN_PICKUP, page: () => const AdminPickupView()),
    GetPage(
      name: ADMIN_PICKUP_ARCHIVE,
      page: () => const AdminArchivedPickupView(),
    ),
    GetPage(name: TEACHER_PICKUP, page: () => const TeacherPickupView()),
    GetPage(name: PARENT_PICKUP, page: () => const ParentPickupView()),
    GetPage(name: MESSAGING, page: () => const MessagingView()),
    GetPage(name: EDIT_PROFILE, page: () => const EditProfileView()),
    GetPage(name: CONTACT_US, page: () => const ContactUsView()),
    GetPage(
      name: SETTINGS,
      page: () => const SettingsView(),
      binding: SettingsBinding(),
    ),
    ...EduChatRoutes.routes,
  ];
}
