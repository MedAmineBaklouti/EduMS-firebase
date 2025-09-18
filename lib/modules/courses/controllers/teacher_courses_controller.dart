import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf_text/pdf_text.dart';
import 'package:path_provider/path_provider.dart';

import '../../../app/routes/app_pages.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/database_service.dart';
import '../../../data/models/course_model.dart';
import '../../../data/models/school_class_model.dart';
import '../../../data/models/subject_model.dart';
import '../../../data/models/teacher_model.dart';
import '../views/course_form_view.dart';

enum CourseContentInputMode { manual, pdf, image }

class TeacherCoursesController extends GetxController {
  final DatabaseService _db = Get.find();
  final AuthService _auth = Get.find();
  final ImagePicker _imagePicker = ImagePicker();

  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;

  final RxList<CourseModel> _allCourses = <CourseModel>[].obs;
  final RxList<CourseModel> courses = <CourseModel>[].obs;
  final RxList<SchoolClassModel> availableClasses = <SchoolClassModel>[].obs;
  final RxSet<String> selectedClassIds = <String>{}.obs;
  final RxString selectedFilterClassId = ''.obs;
  final Rx<CourseContentInputMode> contentInputMode =
      CourseContentInputMode.manual.obs;
  final RxBool isExtractingContent = false.obs;
  final Rxn<String> lastContentSource = Rxn<String>();
  final Rxn<String> extractionError = Rxn<String>();

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
            .toList();
        _allCourses.assignAll(filtered);
        _applyFilters();
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
    _resetContentExtractionState();
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

  void setContentInputMode(CourseContentInputMode mode) {
    contentInputMode.value = mode;
    extractionError.value = null;
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

  Future<void> pickPdfAndExtractText() async {
    try {
      extractionError.value = null;
      lastContentSource.value = null;
      final typeGroup = XTypeGroup(
        label: 'PDF',
        extensions: ['pdf'],
        mimeTypes: const ['application/pdf'],
      );
      final pickedFile = await openFile(acceptedTypeGroups: [typeGroup]);
      if (pickedFile == null) {
        return;
      }
      final fileName =
          pickedFile.name.isNotEmpty ? pickedFile.name : 'selected file';
      final path = await _resolveLocalFilePath(pickedFile);
      if (path == null) {
        final message = 'Could not read the selected PDF file $fileName.';
        extractionError.value = message;
        Get.snackbar(
          'Extraction failed',
          message,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      isExtractingContent.value = true;
      final pdfDoc = await PDFDoc.fromPath(path);
      final text = (await pdfDoc.text).trim();
      if (text.isEmpty) {
        final message = 'No readable text was found in $fileName.';
        extractionError.value = message;
        Get.snackbar(
          'No text found',
          message,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      contentController.text = text;
      lastContentSource.value = 'Extracted from $fileName';
      Get.snackbar(
        'Content updated',
        'Text extracted from the selected PDF.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      final message = 'Failed to extract text from the PDF. ${e.toString()}';
      extractionError.value = message;
      Get.snackbar(
        'Extraction failed',
        message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isExtractingContent.value = false;
    }
  }

  Future<String?> _resolveLocalFilePath(XFile pickedFile) async {
    final existingPath = pickedFile.path;
    if (existingPath != null && existingPath.isNotEmpty) {
      return existingPath;
    }
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = pickedFile.name.isNotEmpty
          ? pickedFile.name
          : 'selected_pdf_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final tempFile = File(
        '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_$fileName',
      );
      await tempFile.writeAsBytes(await pickedFile.readAsBytes(), flush: true);
      return tempFile.path;
    } catch (_) {
      return null;
    }
  }

  Future<void> pickImageAndExtractText({required bool fromCamera}) async {
    try {
      extractionError.value = null;
      lastContentSource.value = null;
      final pickedFile = await _imagePicker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      );
      if (pickedFile == null) {
        return;
      }
      isExtractingContent.value = true;
      final inputImage = InputImage.fromFilePath(pickedFile.path);
      final textRecognizer = TextRecognizer(
        script: TextRecognitionScript.latin,
      );
      try {
        final recognisedText = await textRecognizer.processImage(inputImage);
        final text = recognisedText.text.trim();
        if (text.isEmpty) {
          const message = 'No text was detected in the selected image.';
          extractionError.value = message;
          Get.snackbar(
            'No text found',
            message,
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }
        contentController.text = text;
        lastContentSource.value = fromCamera
            ? 'Extracted from captured photo'
            : 'Extracted from selected image';
        Get.snackbar(
          'Content updated',
          'Text extracted from the image.',
          snackPosition: SnackPosition.BOTTOM,
        );
      } finally {
        await textRecognizer.close();
      }
    } catch (e) {
      final message = 'Failed to read text from the image. ${e.toString()}';
      extractionError.value = message;
      Get.snackbar(
        'Extraction failed',
        message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isExtractingContent.value = false;
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
        'Class';
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
    _resetContentExtractionState();
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

  void _resetContentExtractionState() {
    contentInputMode.value = CourseContentInputMode.manual;
    isExtractingContent.value = false;
    lastContentSource.value = null;
    extractionError.value = null;
  }
}
