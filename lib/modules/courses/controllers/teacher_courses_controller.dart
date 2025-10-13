import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_pages.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/database_service.dart';
import '../../../data/models/course_model.dart';
import '../../../data/models/school_class_model.dart';
import '../../../data/models/subject_model.dart';
import '../../../data/models/teacher_model.dart';
import '../views/course_form_view.dart';

class TeacherCoursesController extends GetxController {
  final DatabaseService _db = Get.find();
  final AuthService _auth = Get.find();

  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;

  final RxList<CourseModel> _allCourses = <CourseModel>[].obs;
  final RxList<CourseModel> courses = <CourseModel>[].obs;
  final RxList<SchoolClassModel> availableClasses = <SchoolClassModel>[].obs;
  final RxSet<String> selectedClassIds = <String>{}.obs;
  final RxString selectedFilterClassId = ''.obs;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController contentController = TextEditingController();

  final Rxn<TeacherModel> teacher = Rxn<TeacherModel>();
  final Rxn<SubjectModel> subject = Rxn<SubjectModel>();

  CourseModel? editing;
  StreamSubscription<List<CourseModel>>? _subscription;

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  Future<void> refreshData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      Get.snackbar(
        'courses_auth_required_title'.tr,
        'courses_teacher_auth_error'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      final teacherDoc =
          await _db.firestore.collection('teachers').doc(uid).get();
      if (!teacherDoc.exists) {
        Get.snackbar(
          'courses_profile_missing_title'.tr,
          'courses_profile_missing_message'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final teacherModel = TeacherModel.fromDoc(teacherDoc);
      teacher.value = teacherModel;

      if (teacherModel.subjectId.isNotEmpty) {
        final subjectDoc = await _db.firestore
            .collection('subjects')
            .doc(teacherModel.subjectId)
            .get();
        subject.value =
            subjectDoc.exists ? SubjectModel.fromDoc(subjectDoc) : null;
      } else {
        subject.value = null;
      }

      final classesSnap = await _db.firestore.collection('classes').get();
      final classes = classesSnap.docs
          .map((doc) => SchoolClassModel.fromDoc(doc))
          .where((schoolClass) =>
              schoolClass.teacherSubjects[teacherModel.subjectId] ==
              teacherModel.id)
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      availableClasses.assignAll(classes);

      final coursesSnap = await _db.firestore
          .collection('courses')
          .where('teacherId', isEqualTo: teacherModel.id)
          .get();
      _allCourses.assignAll(
        coursesSnap.docs.map((doc) => CourseModel.fromDoc(doc)).toList(),
      );
      _applyFilters();
    } catch (error) {
      Get.snackbar(
        'courses_refresh_failed'.tr,
        'courses_refresh_failed_message'
            .trParams({'error': error.toString()}),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _initialize() async {
    try {
      isLoading.value = true;
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        Get.snackbar(
          'common_error'.tr,
          'courses_teacher_auth_error'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final teacherDoc =
          await _db.firestore.collection('teachers').doc(uid).get();
      if (!teacherDoc.exists) {
        Get.snackbar(
          'courses_profile_missing_title'.tr,
          'courses_profile_missing_message'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final teacherModel = TeacherModel.fromDoc(teacherDoc);
      teacher.value = teacherModel;

      if (teacherModel.subjectId.isNotEmpty) {
        final subjectDoc = await _db.firestore
            .collection('subjects')
            .doc(teacherModel.subjectId)
            .get();
        if (subjectDoc.exists) {
          subject.value = SubjectModel.fromDoc(subjectDoc);
        }
      }

      final classesSnap = await _db.firestore.collection('classes').get();
      final classes = classesSnap.docs
          .map((doc) => SchoolClassModel.fromDoc(doc))
          .where((schoolClass) =>
              schoolClass.teacherSubjects[teacherModel.subjectId] ==
              teacherModel.id)
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      availableClasses.assignAll(classes);

      _subscription = _db.streamCourses().listen((data) {
        final filtered = data
            .where((course) => course.teacherId == teacherModel.id)
            .toList();
        _allCourses.assignAll(filtered);
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

  void openForm({CourseModel? course}) {
    if (course != null) {
      editing = course;
      titleController.text = course.title;
      descriptionController.text = course.description;
      contentController.text = course.content;
      selectedClassIds
        ..clear()
        ..addAll(course.classIds);
    } else {
      editing = null;
      clearForm();
    }
    Get.to(() => CourseFormView(controller: this));
  }

  Future<void> saveCourse() async {
    if (formKey.currentState?.validate() != true) {
      return;
    }
    if (selectedClassIds.isEmpty) {
      Get.snackbar(
        'courses_missing_information_title'.tr,
        'courses_select_class_message'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    final teacherModel = teacher.value;
    if (teacherModel == null) {
      Get.snackbar(
        'common_error'.tr,
        'courses_teacher_profile_missing_message'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final selectedClasses = availableClasses
        .where((element) => selectedClassIds.contains(element.id))
        .toList();
    final subjectName = subject.value?.name.trim().isNotEmpty == true
        ? subject.value!.name
        : 'courses_subject_not_specified'.tr;

    final course = CourseModel(
      id: editing?.id ?? '',
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      content: contentController.text.trim(),
      subjectId: subject.value?.id ?? teacherModel.subjectId,
      subjectName: subjectName,
      teacherId: teacherModel.id,
      teacherName: teacherModel.name,
      classIds: selectedClasses.map((e) => e.id).toList(),
      classNames: selectedClasses.map((e) => e.name).toList(),
      createdAt: editing?.createdAt ?? DateTime.now(),
    );

    try {
      isSaving.value = true;
      if (editing == null) {
        await _db.addCourse(course);
        Get.snackbar(
          'courses_course_added_title'.tr,
          'courses_course_added_message'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        await _db.updateCourse(course);
        Get.snackbar(
          'courses_course_updated_title'.tr,
          'courses_course_updated_message'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      _returnToCourseList();
      clearForm();
      editing = null;
    } catch (e) {
      Get.snackbar(
        'common_error'.tr,
        'courses_save_failed_message'.trParams({'error': e.toString()}),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> deleteCourse(String id) async {
    try {
      await _db.deleteCourse(id);
      Get.snackbar(
        'courses_course_removed_title'.tr,
        'courses_course_removed_message'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'common_error'.tr,
        'courses_delete_failed_message'.trParams({'error': e.toString()}),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void toggleClassSelection(String classId) {
    if (selectedClassIds.contains(classId)) {
      selectedClassIds.remove(classId);
    } else {
      selectedClassIds.add(classId);
    }
    selectedClassIds.refresh();
  }

  void updateClassFilter(String value) {
    selectedFilterClassId.value = value;
    _applyFilters();
  }

  void clearFilters() {
    selectedFilterClassId.value = '';
    _applyFilters();
  }

  String className(String id) {
    return availableClasses.firstWhereOrNull((element) => element.id == id)?.name ??
        'courses_filter_label_class'.tr;
  }

  void _applyFilters() {
    Iterable<CourseModel> filtered = _allCourses;
    if (selectedFilterClassId.value.isNotEmpty) {
      filtered = filtered
          .where((course) => course.classIds.contains(selectedFilterClassId.value));
    }

    final list = filtered.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    courses.assignAll(list);
  }

  void clearForm() {
    titleController.clear();
    descriptionController.clear();
    contentController.clear();
    selectedClassIds.clear();
  }

  void _returnToCourseList() {
    Get.until((route) {
      if (route.settings.name == AppPages.TEACHER_COURSES) {
        return true;
      }
      if (route.isFirst) {
        return true;
      }
      return false;
    });
    if (Get.currentRoute != AppPages.TEACHER_COURSES) {
      Get.toNamed(AppPages.TEACHER_COURSES);
    }
  }

  @override
  void onClose() {
    _subscription?.cancel();
    titleController.dispose();
    descriptionController.dispose();
    contentController.dispose();
    super.onClose();
  }
}
