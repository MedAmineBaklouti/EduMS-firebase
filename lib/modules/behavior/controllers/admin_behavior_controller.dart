import 'package:collection/collection.dart';
import 'package:get/get.dart';

import '../../../data/models/behavior_model.dart';
import '../../../data/models/school_class_model.dart';
import '../../../data/models/teacher_model.dart';

class AdminBehaviorController extends GetxController {
  final RxList<BehaviorModel> _allBehaviors = <BehaviorModel>[].obs;
  final RxList<BehaviorModel> behaviors = <BehaviorModel>[].obs;

  final RxList<SchoolClassModel> classes = <SchoolClassModel>[].obs;
  final RxList<TeacherModel> teachers = <TeacherModel>[].obs;

  final RxnString classFilter = RxnString();
  final RxnString teacherFilter = RxnString();
  final Rxn<BehaviorType> typeFilter = Rxn<BehaviorType>();
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

  void setBehaviors(List<BehaviorModel> items) {
    _allBehaviors.assignAll(items);
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

  void setTypeFilter(BehaviorType? type) {
    typeFilter.value = type;
    _applyFilters();
  }

  void _applyFilters() {
    final filtered = _allBehaviors.where((behavior) {
      final matchesClass =
          classFilter.value == null || classFilter.value!.isEmpty
              ? true
              : behavior.classId == classFilter.value;
      final matchesTeacher =
          teacherFilter.value == null || teacherFilter.value!.isEmpty
              ? true
              : behavior.teacherId == teacherFilter.value;
      final matchesType =
          typeFilter.value == null || behavior.type == typeFilter.value;
      return matchesClass && matchesTeacher && matchesType;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    behaviors.assignAll(filtered);
  }

  String? className(String classId) {
    return classes.firstWhereOrNull((item) => item.id == classId)?.name;
  }

  String? teacherName(String teacherId) {
    return teachers.firstWhereOrNull((item) => item.id == teacherId)?.name;
  }
}
