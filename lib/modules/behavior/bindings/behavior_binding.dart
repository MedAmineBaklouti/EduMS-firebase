import 'package:get/get.dart';

import '../controllers/admin_behavior_controller.dart';
import '../controllers/parent_behavior_controller.dart';
import '../controllers/teacher_behavior_controller.dart';

class BehaviorBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminBehaviorController>(
        () => AdminBehaviorController(),
        fenix: true);
    Get.lazyPut<TeacherBehaviorController>(
        () => TeacherBehaviorController(),
        fenix: true);
    Get.lazyPut<ParentBehaviorController>(
        () => ParentBehaviorController(),
        fenix: true);
  }
}
