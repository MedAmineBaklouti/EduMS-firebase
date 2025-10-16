import 'package:get/get.dart';

import '../controllers/teacher_controller.dart';

class TeachersDashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TeacherController>(() => TeacherController(), fenix: true);
  }
}
