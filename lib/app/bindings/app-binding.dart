import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:edums/modules/auth/service/auth_service.dart';
import '../../common/services/database_service.dart';
import '../../common/services/network_service.dart';
import '../../common/services/settings_service.dart';
import '../../modules/admin_dashboard/bindings/admin_dashboard_binding.dart';
import '../../modules/attendance/bindings/attendance_binding.dart';
import '../../modules/auth/bindings/auth_binding.dart';
import '../../modules/behavior/bindings/behavior_binding.dart';
import '../../modules/homework/bindings/homework_binding.dart';
import '../../modules/messaging/bindings/messaging_binding.dart';
import '../../modules/messaging/services/messaging_service.dart';
import '../../modules/parents_dashboard/bindings/parents_dashboard_binding.dart';
import '../../modules/pickup/bindings/pickup_binding.dart';
import '../../modules/teachers_dashboard/bindings/teachers_dashboard_binding.dart';

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
    AuthBinding().dependencies();
    AdminDashboardBinding().dependencies();
    AttendanceBinding().dependencies();
    BehaviorBinding().dependencies();
    HomeworkBinding().dependencies();
    PickupBinding().dependencies();
    TeachersDashboardBinding().dependencies();
    ParentsDashboardBinding().dependencies();
    MessagingBinding().dependencies();
  }
}