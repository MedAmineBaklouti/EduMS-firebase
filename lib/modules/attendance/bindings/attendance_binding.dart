import 'package:get/get.dart';

import '../controllers/admin_attendance_controller.dart';
import '../controllers/admin_teacher_attendance_controller.dart';
import '../controllers/parent_attendance_controller.dart';
import '../controllers/teacher_attendance_controller.dart';

class AttendanceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminAttendanceController>(
        () => AdminAttendanceController(),
        fenix: true);
    Get.lazyPut<AdminTeacherAttendanceController>(
        () => AdminTeacherAttendanceController(),
        fenix: true);
    Get.lazyPut<TeacherAttendanceController>(
        () => TeacherAttendanceController(),
        fenix: true);
    Get.lazyPut<ParentAttendanceController>(
        () => ParentAttendanceController(),
        fenix: true);
  }
}
