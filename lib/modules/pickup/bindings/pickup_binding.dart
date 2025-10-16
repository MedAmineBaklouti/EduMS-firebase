import 'package:get/get.dart';

import '../controllers/admin_archived_pickup_controller.dart';
import '../controllers/admin_pickup_controller.dart';
import '../controllers/parent_pickup_controller.dart';
import '../controllers/teacher_pickup_controller.dart';
import '../services/parent_pickup_notification_service.dart';

class PickupBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminPickupController>(() => AdminPickupController(),
        fenix: true);
    Get.lazyPut<AdminArchivedPickupController>(
        () => AdminArchivedPickupController(),
        fenix: true);
    Get.lazyPut<TeacherPickupController>(() => TeacherPickupController(),
        fenix: true);
    Get.lazyPut<ParentPickupController>(() => ParentPickupController(),
        fenix: true);
    Get.put<ParentPickupNotificationService>(
      ParentPickupNotificationService(),
      permanent: true,
    );
  }
}
