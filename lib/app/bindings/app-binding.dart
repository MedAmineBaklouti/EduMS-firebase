import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/database_service.dart';
import '../../core/services/network_service.dart';
import '../../core/services/settings_service.dart';
import '../../modules/admin_dashboard/controllers/admin_controller.dart';
import '../../modules/admin_dashboard/controllers/admin_control_controller.dart';
import '../../modules/attendance/controllers/admin_attendance_controller.dart';
import '../../modules/attendance/controllers/admin_teacher_attendance_controller.dart';
import '../../modules/attendance/controllers/parent_attendance_controller.dart';
import '../../modules/attendance/controllers/teacher_attendance_controller.dart';
import '../../modules/auth/controllers/auth_controller.dart';
import '../../modules/behavior/controllers/admin_behavior_controller.dart';
import '../../modules/behavior/controllers/parent_behavior_controller.dart';
import '../../modules/behavior/controllers/teacher_behavior_controller.dart';
import '../../modules/homework/controllers/admin_homework_controller.dart';
import '../../modules/homework/controllers/parent_homework_controller.dart';
import '../../modules/homework/controllers/teacher_homework_controller.dart';
import '../../modules/pickup/controllers/admin_archived_pickup_controller.dart';
import '../../modules/pickup/controllers/admin_pickup_controller.dart';
import '../../modules/messaging/controllers/messaging_controller.dart';
import '../../modules/messaging/services/messaging_service.dart';
import '../../modules/pickup/controllers/parent_pickup_controller.dart';
import '../../modules/pickup/controllers/teacher_pickup_controller.dart';
import '../../modules/pickup/services/parent_pickup_notification_service.dart';
import '../../modules/parents_dashboard/controllers/parent_controller.dart';
import '../../modules/teachers_dashboard/controllers/teacher_controller.dart';

class AppBindings extends Bindings {
  @override
  Future<void> dependencies() async {
    await _initializeCoreServices();
    await _initializeControllers();
  }

  Future<void> _initializeCoreServices() async {
    // Initialize SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    Get.put(prefs, permanent: true);

    // Initialize user preferences and settings
    final settingsService =
        await SettingsService(preferences: prefs).init();
    Get.put(settingsService, permanent: true);

    // Monitor connectivity for Firestore before other services use it
    final networkService = NetworkService();
    await networkService.init();
    Get.put(networkService, permanent: true);

    // Ensure Firebase is initialized before any services depend on it.
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }

    // Initialize DatabaseService
    final databaseService = DatabaseService();
    await databaseService.init(); // Add init() method if needed
    Get.put(databaseService, permanent: true);

    // Initialize AuthService
    final authService = AuthService();
    await authService.init();
    Get.put(authService, permanent: true);

    // Initialize MessagingService
    final messagingService = MessagingService();
    await messagingService.init();
    Get.put(messagingService, permanent: true);
  }

  Future<void> _initializeControllers() async {
    Get.put(AuthController(), permanent: true);

    // Role-specific controllers can be lazy loaded
    Get.lazyPut(() => AdminController(), fenix: true);
    Get.lazyPut(() => AdminControlController(), fenix: true);
    Get.lazyPut(() => AdminAttendanceController(), fenix: true);
    Get.lazyPut(() => AdminTeacherAttendanceController(), fenix: true);
    Get.lazyPut(() => AdminBehaviorController(), fenix: true);
    Get.lazyPut(() => AdminHomeworkController(), fenix: true);
    Get.lazyPut(() => AdminPickupController(), fenix: true);
    Get.lazyPut(() => AdminArchivedPickupController(), fenix: true);
    Get.lazyPut(() => TeacherController(), fenix: true);
    Get.lazyPut(() => TeacherAttendanceController(), fenix: true);
    Get.lazyPut(() => TeacherBehaviorController(), fenix: true);
    Get.lazyPut(() => TeacherHomeworkController(), fenix: true);
    Get.lazyPut(() => TeacherPickupController(), fenix: true);
    Get.lazyPut(() => ParentController(), fenix: true);
    Get.lazyPut(() => ParentAttendanceController(), fenix: true);
    Get.lazyPut(() => ParentBehaviorController(), fenix: true);
    Get.lazyPut(() => ParentHomeworkController(), fenix: true);
    Get.lazyPut(() => ParentPickupController(), fenix: true);
    Get.lazyPut(() => MessagingController(), fenix: true);
    Get.put(ParentPickupNotificationService(), permanent: true);
  }
}