import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_pages.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/database_service.dart';
import '../../../data/models/course_model.dart';
import '../views/course_form_view.dart';

class TeacherCoursesController extends GetxController {
  final DatabaseService _db = Get.find();
  final AuthService _auth = Get.find();

  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;

  final RxList<CourseModel> courses = <CourseModel>[].obs;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController contentController = TextEditingController();

  String? _teacherId;
  String _teacherName = '';
  String _teacherEmail = '';

  CourseModel? editing;
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
          'Error',
          'Unable to determine the authenticated teacher.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      _teacherId = uid;
      _teacherName = _auth.currentUser?.displayName ?? '';
      _teacherEmail = _auth.currentUser?.email ?? '';

      final teacherDoc =
          await _db.firestore.collection('teachers').doc(uid).get();
      if (teacherDoc.exists) {
        final data = teacherDoc.data() as Map<String, dynamic>?;
        _teacherName = (data?['name'] as String?)?.trim() ?? _teacherName;
        _teacherEmail = (data?['email'] as String?)?.trim() ?? _teacherEmail;
      }

      _subscription = _db.streamCourses().listen((data) {
        final filtered = data
            .where((course) => course.teacherId == _teacherId)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        courses.assignAll(filtered);
      });
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load your courses. ${e.toString()}',
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
    final teacherId = _teacherId;
    if (teacherId == null) {
      Get.snackbar(
        'Error',
        'Unable to determine the authenticated teacher.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final subjectName = editing?.subjectName.trim().isNotEmpty == true
        ? editing!.subjectName
        : 'General';
    final classIds = List<String>.from(editing?.classIds ?? const <String>[]);
    final classNames = List<String>.from(editing?.classNames ?? const <String>[]);
    final teacherName = _teacherName.trim().isNotEmpty
        ? _teacherName
        : (_teacherEmail.trim().isNotEmpty ? _teacherEmail : 'Teacher');

    final course = CourseModel(
      id: editing?.id ?? '',
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      content: contentController.text.trim(),
      subjectId: editing?.subjectId ?? '',
      subjectName: subjectName,
      teacherId: teacherId,
      teacherName: teacherName,
      classIds: classIds,
      classNames: classNames,
      createdAt: editing?.createdAt ?? DateTime.now(),
    );

    try {
      isSaving.value = true;
      if (editing == null) {
        await _db.addCourse(course);
        Get.snackbar(
          'Course added',
          'Your course has been published successfully.',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        await _db.updateCourse(course);
        Get.snackbar(
          'Course updated',
          'Your changes have been saved.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      _returnToCourseList();
      clearForm();
      editing = null;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save the course. ${e.toString()}',
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
        'Course removed',
        'The course has been deleted.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete the course. ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void clearForm() {
    titleController.clear();
    descriptionController.clear();
    contentController.clear();
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
