import 'package:get/get.dart';

import '../controllers/admin_homework_controller.dart';
import '../controllers/parent_homework_controller.dart';
import '../controllers/teacher_homework_controller.dart';

class HomeworkBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminHomeworkController>(() => AdminHomeworkController(),
        fenix: true);
    Get.lazyPut<TeacherHomeworkController>(
        () => TeacherHomeworkController(),
        fenix: true);
    Get.lazyPut<ParentHomeworkController>(() => ParentHomeworkController(),
        fenix: true);
  }
}
