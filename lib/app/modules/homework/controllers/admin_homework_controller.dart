import 'dart:async';

import 'package:collection/collection.dart';
import 'package:get/get.dart';

import '../../../core/services/database_service.dart';
import '../../../data/models/homework_model.dart';
import '../../../data/models/school_class_model.dart';
import '../../../data/models/teacher_model.dart';

class AdminHomeworkController extends GetxController {
  final DatabaseService _db = Get.find();

  StreamSubscription? _classesSubscription;
  StreamSubscription? _teachersSubscription;
  StreamSubscription? _homeworksSubscription;

  bool _classesLoaded = false;
  bool _teachersLoaded = false;
  bool _homeworksLoaded = false;

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  @override
  void onClose() {
    _classesSubscription?.cancel();
    _teachersSubscription?.cancel();
    _homeworksSubscription?.cancel();
    super.onClose();
  }

  final RxList<HomeworkModel> _allHomeworks = <HomeworkModel>[].obs;
  final RxList<HomeworkModel> homeworks = <HomeworkModel>[].obs;

  final RxList<SchoolClassModel> classes = <SchoolClassModel>[].obs;
  final RxList<TeacherModel> teachers = <TeacherModel>[].obs;

  final RxnString classFilter = RxnString();
  final RxnString teacherFilter = RxnString();
  final RxBool isLoading = false.obs;

  void clearFilters() {
    classFilter.value = null;
    teacherFilter.value = null;
    _applyFilters();
  }

  int? childCountForClass(String classId) {
    final classModel =
        classes.firstWhereOrNull((item) => item.id == classId);
    return classModel?.childIds.length;
  }

  String className(String classId) {
    return classes
            .firstWhereOrNull((item) => item.id == classId)
            ?.name ??
        'Class';
  }

  String teacherName(String teacherId) {
    return teachers
            .firstWhereOrNull((item) => item.id == teacherId)
            ?.name ??
        'Teacher';
  }

  void setClasses(List<SchoolClassModel> items) {
    classes.assignAll(items);
    if (classFilter.value != null &&
        classes.firstWhereOrNull((item) => item.id == classFilter.value) ==
            null) {
      classFilter.value = null;
    }
    _classesLoaded = true;
    _maybeFinishLoading();
  }

  void setTeachers(List<TeacherModel> items) {
    teachers.assignAll(items);
    if (teacherFilter.value != null &&
        teachers.firstWhereOrNull((item) => item.id == teacherFilter.value) ==
            null) {
      teacherFilter.value = null;
    }
    _teachersLoaded = true;
    _maybeFinishLoading();
  }

  void setHomeworks(List<HomeworkModel> items) {
    _allHomeworks.assignAll(items);
    _applyFilters();
    _homeworksLoaded = true;
    _maybeFinishLoading();
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

  Future<void> refreshData() async {
    final classSnapshot = await _db.firestore.collection('classes').get();
    setClasses(classSnapshot.docs.map(SchoolClassModel.fromDoc).toList());

    final teacherSnapshot = await _db.firestore.collection('teachers').get();
    setTeachers(teacherSnapshot.docs.map(TeacherModel.fromDoc).toList());

    final homeworkSnapshot = await _db.firestore.collection('homeworks').get();
    setHomeworks(homeworkSnapshot.docs.map(HomeworkModel.fromDoc).toList());
  }

  void _initialize() {
    isLoading.value = true;

    _classesSubscription = _db.firestore
        .collection('classes')
        .snapshots()
        .listen((snapshot) {
      setClasses(snapshot.docs.map(SchoolClassModel.fromDoc).toList());
    });

    _teachersSubscription = _db.firestore
        .collection('teachers')
        .snapshots()
        .listen((snapshot) {
      setTeachers(snapshot.docs.map(TeacherModel.fromDoc).toList());
    });

    _homeworksSubscription = _db.firestore
        .collection('homeworks')
        .snapshots()
        .listen((snapshot) {
      setHomeworks(snapshot.docs.map(HomeworkModel.fromDoc).toList());
    });
  }

  void _maybeFinishLoading() {
    if (_classesLoaded && _teachersLoaded && _homeworksLoaded) {
      isLoading.value = false;
    }
  }
}
