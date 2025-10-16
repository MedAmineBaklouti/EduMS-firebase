import 'package:get/get.dart';

import '../controllers/admin_control_controller.dart';
import '../controllers/admin_controller.dart';

class AdminDashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminController>(() => AdminController(), fenix: true);
    Get.lazyPut<AdminControlController>(() => AdminControlController(), fenix: true);
  }
}
