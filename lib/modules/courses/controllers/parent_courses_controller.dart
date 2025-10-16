import 'dart:async';

import 'package:collection/collection.dart';
import 'package:get/get.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/database_service.dart';
import '../../common/models/child_model.dart';
import '../models/course_model.dart';
import '../../common/models/school_class_model.dart';

class ParentCoursesController extends GetxController {
  final DatabaseService _db = Get.find();
  final AuthService _auth = Get.find();

  final RxBool isLoading = true.obs;

  final RxList<CourseModel> _allCourses = <CourseModel>[].obs;
  final RxList<CourseModel> courses = <CourseModel>[].obs;
  final RxList<ChildModel> children = <ChildModel>[].obs;
  final RxMap<String, SchoolClassModel> classesById =
      <String, SchoolClassModel>{}.obs;

  final RxString selectedChildId = ''.obs;
  final RxString selectedSubjectId = ''.obs;

  final RxList<SubjectFilterOption> subjectOptions =
      <SubjectFilterOption>[].obs;

  StreamSubscription<List<CourseModel>>? _subscription;

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      isLoading.value = true;
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        Get.snackbar(
          'common_error'.tr,
          'courses_parent_auth_error'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      await _loadChildren(uid);

      _subscription = _db.streamCourses().listen((data) {
        _allCourses.assignAll(data);
        _buildSubjectOptions();
        _applyFilters();
      });
    } catch (e) {
      Get.snackbar(
        'common_error'.tr,
        'courses_load_failed_message'.trParams({'error': e.toString()}),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadChildren(String parentId) async {
    final childrenSnap = await _db.firestore
        .collection('children')
        .where('parentId', isEqualTo: parentId)
        .get();
    final loadedChildren =
        childrenSnap.docs.map((doc) => ChildModel.fromDoc(doc)).toList();
    children.assignAll(loadedChildren);

    final classesSnap = await _db.firestore.collection('classes').get();
    final classesMap = {
      for (final doc in classesSnap.docs)
        doc.id: SchoolClassModel.fromDoc(doc)
    };
    classesById.assignAll(classesMap);
  }

  void updateChildFilter(String childId) {
    selectedChildId.value = childId;
    _applyFilters();
  }

  void updateSubjectFilter(String subjectId) {
    selectedSubjectId.value = subjectId;
    _applyFilters();
  }

  void clearFilters() {
    selectedChildId.value = '';
    selectedSubjectId.value = '';
    _applyFilters();
  }

  Future<void> refreshData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return;
    }

    await _loadChildren(uid);

    final snapshot = await _db.firestore
        .collection('courses')
        .orderBy('createdAt', descending: true)
        .get();
    final latestCourses =
        snapshot.docs.map((doc) => CourseModel.fromDoc(doc)).toList();
    _allCourses.assignAll(latestCourses);
    _buildSubjectOptions();
    _applyFilters();
  }

  String childName(String id) {
    return children.firstWhereOrNull((child) => child.id == id)?.name ??
        'courses_filter_label_child'.tr;
  }

  String subjectName(String id) {
    return subjectOptions
            .firstWhereOrNull((option) => option.id == id)
            ?.name ??
        'courses_filter_label_subject'.tr;
  }

  void _applyFilters() {
    final relevantClassIds = _parentClassIds;
    Iterable<CourseModel> filtered = _allCourses.where(
        (course) => course.classIds.any(relevantClassIds.contains));

    if (selectedChildId.value.isNotEmpty) {
      final child =
          children.firstWhereOrNull((c) => c.id == selectedChildId.value);
      if (child != null && child.classId.isNotEmpty) {
        filtered = filtered
            .where((course) => course.classIds.contains(child.classId));
      }
    }

    if (selectedSubjectId.value.isNotEmpty) {
      filtered = filtered
          .where((course) => course.subjectId == selectedSubjectId.value);
    }

    final list = filtered.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    courses.assignAll(list);
  }

  void _buildSubjectOptions() {
    final relevantClassIds = _parentClassIds;
    final subjects = <String, String>{};
    for (final course in _allCourses) {
      if (!course.classIds.any(relevantClassIds.contains)) {
        continue;
      }
      if (course.subjectId.isEmpty) {
        continue;
      }
      subjects[course.subjectId] = course.subjectName;
    }
    final list = subjects.entries
        .map((entry) => SubjectFilterOption(
              id: entry.key,
              name: entry.value,
            ))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    subjectOptions.assignAll(list);
    if (list.every((element) => element.id != selectedSubjectId.value)) {
      selectedSubjectId.value = '';
    }
  }

  Set<String> get _parentClassIds => children
      .map((child) => child.classId)
      .where((id) => id.isNotEmpty)
      .toSet();

  SchoolClassModel? classForId(String id) => classesById[id];

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}

class SubjectFilterOption {
  final String id;
  final String name;

  SubjectFilterOption({required this.id, required this.name});
}
