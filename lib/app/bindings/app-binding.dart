import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/datavase_service.dart';
import '../../modules/admin_dashboard/controllers/admin_controller.dart';
import '../../modules/auth/controllers/auth_controller.dart';
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

    // Initialize DatabaseService
    final databaseService = DatabaseService();
    await databaseService.init(); // Add init() method if needed
    Get.put(databaseService, permanent: true);

    // Initialize AuthService
    final authService = AuthService();
    await authService.init();
    Get.put(authService, permanent: true);
  }

  Future<void> _initializeControllers() async {
    Get.put(AuthController(), permanent: true);

    // Role-specific controllers can be lazy loaded
    Get.lazyPut(() => AdminController(), fenix: true);
    Get.lazyPut(() => TeacherController(), fenix: true);
    Get.lazyPut(() => ParentController(), fenix: true);
  }
}