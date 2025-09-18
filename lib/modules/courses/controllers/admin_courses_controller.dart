import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/database_service.dart';
import '../../../data/models/course_model.dart';
import '../../../data/models/school_class_model.dart';
import '../../../data/models/subject_model.dart';
import '../../../data/models/teacher_model.dart';

class AdminCoursesController extends GetxController {
  final DatabaseService _db = Get.find();

  final RxBool isLoading = true.obs;

  final RxList<CourseModel> _allCourses = <CourseModel>[].obs;
  final RxList<CourseModel> courses = <CourseModel>[].obs;

  final RxList<SubjectModel> subjects = <SubjectModel>[].obs;
  final RxList<TeacherModel> teachers = <TeacherModel>[].obs;
  final RxList<SchoolClassModel> classes = <SchoolClassModel>[].obs;

  final RxString selectedSubjectId = ''.obs;
  final RxString selectedTeacherId = ''.obs;
  final RxString selectedClassId = ''.obs;
  final RxString searchQuery = ''.obs;
  final TextEditingController searchController = TextEditingController();

  StreamSubscription<List<CourseModel>>? _subscription;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(() {
      updateSearchQuery(searchController.text);
    });
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      isLoading.value = true;
      await Future.wait([
        _loadSubjects(),
        _loadTeachers(),
        _loadClasses(),
      ]);

      _subscription = _db.streamCourses().listen((data) {
        _allCourses.assignAll(data);
        _applyFilters();
      });
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load courses. ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadSubjects() async {
    final snap = await _db.firestore.collection('subjects').get();
    final data = snap.docs.map((doc) => SubjectModel.fromDoc(doc)).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    subjects.assignAll(data);
  }

  Future<void> _loadTeachers() async {
    final snap = await _db.firestore.collection('teachers').get();
    final data = snap.docs.map((doc) => TeacherModel.fromDoc(doc)).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    teachers.assignAll(data);
  }

  Future<void> _loadClasses() async {
    final snap = await _db.firestore.collection('classes').get();
    final data = snap.docs.map((doc) => SchoolClassModel.fromDoc(doc)).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    classes.assignAll(data);
  }

  void updateSubjectFilter(String value) {
    selectedSubjectId.value = value;
    _applyFilters();
  }

  void updateTeacherFilter(String value) {
    selectedTeacherId.value = value;
    _applyFilters();
  }

  void updateClassFilter(String value) {
    selectedClassId.value = value;
    _applyFilters();
  }

  void updateSearchQuery(String value) {
    final normalized = value.trim();
    if (searchQuery.value == normalized) {
      return;
    }
    searchQuery.value = normalized;
    _applyFilters();
  }

  void clearFilters() {
    selectedSubjectId.value = '';
    selectedTeacherId.value = '';
    selectedClassId.value = '';
    if (searchController.text.isNotEmpty) {
      searchController.clear();
    }
    _applyFilters();
  }

  void _applyFilters() {
    Iterable<CourseModel> filtered = _allCourses;
    if (selectedSubjectId.value.isNotEmpty) {
      filtered =
          filtered.where((course) => course.subjectId == selectedSubjectId.value);
    }
    if (selectedTeacherId.value.isNotEmpty) {
      filtered = filtered
          .where((course) => course.teacherId == selectedTeacherId.value);
    }
    if (selectedClassId.value.isNotEmpty) {
      filtered = filtered
          .where((course) => course.classIds.contains(selectedClassId.value));
    }
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      filtered = filtered.where((course) {
        final titleMatch = course.title.toLowerCase().contains(query);
        final subjectMatch = course.subjectName.toLowerCase().contains(query);
        final teacherMatch = course.teacherName.toLowerCase().contains(query);
        final classMatch = course.classNames
            .any((name) => name.toLowerCase().contains(query));
        return titleMatch || subjectMatch || teacherMatch || classMatch;
      });
    }

    final list = filtered.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    courses.assignAll(list);
  }

  String subjectName(String id) {
    return subjects.firstWhereOrNull((subject) => subject.id == id)?.name ??
        'Unknown Subject';
  }

  String teacherName(String id) {
    return teachers.firstWhereOrNull((teacher) => teacher.id == id)?.name ??
        'Unknown Teacher';
  }

  String className(String id) {
    return classes.firstWhereOrNull((schoolClass) => schoolClass.id == id)
            ?.name ??
        'Class';
  }

  int get totalCourseCount => _allCourses.length;

  int get totalTeacherCount =>
      _allCourses.map((course) => course.teacherId).where((id) => id.isNotEmpty).toSet().length;

  int get totalSubjectCount =>
      _allCourses.map((course) => course.subjectId).where((id) => id.isNotEmpty).toSet().length;

  int get totalClassCount =>
      _allCourses.expand((course) => course.classIds).where((id) => id.isNotEmpty).toSet().length;

  int get filteredTeacherCount =>
      courses.map((course) => course.teacherId).where((id) => id.isNotEmpty).toSet().length;

  int get filteredSubjectCount =>
      courses.map((course) => course.subjectId).where((id) => id.isNotEmpty).toSet().length;

  int get filteredClassCount =>
      courses.expand((course) => course.classIds).where((id) => id.isNotEmpty).toSet().length;

  @override
  void onClose() {
    _subscription?.cancel();
    searchController.dispose();
    super.onClose();
  }
}
