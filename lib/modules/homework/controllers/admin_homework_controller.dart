import 'package:collection/collection.dart';
import 'package:get/get.dart';

import '../../../data/models/homework_model.dart';
import '../../../data/models/school_class_model.dart';
import '../../../data/models/teacher_model.dart';

class AdminHomeworkController extends GetxController {
  final RxList<HomeworkModel> _allHomeworks = <HomeworkModel>[].obs;
  final RxList<HomeworkModel> homeworks = <HomeworkModel>[].obs;

  final RxList<SchoolClassModel> classes = <SchoolClassModel>[].obs;
  final RxList<TeacherModel> teachers = <TeacherModel>[].obs;

  final RxnString classFilter = RxnString();
  final RxnString teacherFilter = RxnString();
  final RxBool isLoading = false.obs;

  void setClasses(List<SchoolClassModel> items) {
    classes.assignAll(items);
    if (classFilter.value != null &&
        classes.firstWhereOrNull((item) => item.id == classFilter.value) ==
            null) {
      classFilter.value = null;
    }
  }

  void setTeachers(List<TeacherModel> items) {
    teachers.assignAll(items);
    if (teacherFilter.value != null &&
        teachers.firstWhereOrNull((item) => item.id == teacherFilter.value) ==
            null) {
      teacherFilter.value = null;
    }
  }

  void setHomeworks(List<HomeworkModel> items) {
    _allHomeworks.assignAll(items);
    _applyFilters();
  }

  void setClassFilter(String? classId) {
    classFilter.value = classId;
    _applyFilters();
  }

  void setTeacherFilter(String? teacherId) {
    teacherFilter.value = teacherId;
    _applyFilters();
  }

  void _applyFilters() {
    final filtered = _allHomeworks.where((homework) {
      final matchesClass =
          classFilter.value == null || classFilter.value!.isEmpty
              ? true
              : homework.classId == classFilter.value;
      final matchesTeacher =
          teacherFilter.value == null || teacherFilter.value!.isEmpty
              ? true
              : homework.teacherId == teacherFilter.value;
      return matchesClass && matchesTeacher;
    }).toList()
      ..sort((a, b) => b.dueDate.compareTo(a.dueDate));
    homeworks.assignAll(filtered);
  }
}
