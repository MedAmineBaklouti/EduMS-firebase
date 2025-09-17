import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

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

  final RxList<CourseModel> courses = <CourseModel>[].obs;
  final RxList<SchoolClassModel> availableClasses = <SchoolClassModel>[].obs;
  final RxSet<String> selectedClassIds = <String>{}.obs;

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

      final teacherDoc =
          await _db.firestore.collection('teachers').doc(uid).get();
      if (!teacherDoc.exists) {
        Get.snackbar(
          'Profile missing',
          'Please contact the administrator to complete your profile.',
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
        'Missing information',
        'Please select at least one class.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    final teacherModel = teacher.value;
    if (teacherModel == null) {
      Get.snackbar(
        'Error',
        'Teacher profile missing. Please contact the administrator.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final selectedClasses = availableClasses
        .where((element) => selectedClassIds.contains(element.id))
        .toList();
    final subjectName = subject.value?.name.trim().isNotEmpty == true
        ? subject.value!.name
        : 'Unknown Subject';

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
      Get.back();
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

  void toggleClassSelection(String classId) {
    if (selectedClassIds.contains(classId)) {
      selectedClassIds.remove(classId);
    } else {
      selectedClassIds.add(classId);
    }
    selectedClassIds.refresh();
  }

  void clearForm() {
    titleController.clear();
    descriptionController.clear();
    contentController.clear();
    selectedClassIds.clear();
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
