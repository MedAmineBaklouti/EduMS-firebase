import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:edums/modules/auth/service/auth_service.dart';
import '../../../common/services/database_service.dart';
import '../models/homework_model.dart';
import '../../common/models/school_class_model.dart';
import '../../common/models/teacher_model.dart';

class TeacherHomeworkController extends GetxController {
  final DatabaseService _db = Get.find();
  final AuthService _auth = Get.find();

  StreamSubscription? _teacherSubscription;
  StreamSubscription? _classesSubscription;
  StreamSubscription? _homeworksSubscription;

  bool _teacherLoaded = false;
  bool _classesLoaded = false;
  bool _homeworksLoaded = false;

  final RxList<HomeworkModel> _allHomeworks = <HomeworkModel>[].obs;
  final RxList<HomeworkModel> homeworks = <HomeworkModel>[].obs;

  final RxList<SchoolClassModel> classes = <SchoolClassModel>[].obs;
  final Rxn<TeacherModel> teacher = Rxn<TeacherModel>();
  final Rxn<SchoolClassModel> selectedClass = Rxn<SchoolClassModel>();
  final RxnString filterClassId = RxnString();

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final Rx<DateTime?> dueDate = Rx<DateTime?>(null);

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;

  HomeworkModel? editing;

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  Future<void> refreshData() async {
    final teacherId = teacher.value?.id ?? _auth.currentUser?.uid;
    if (teacherId == null) {
      Get.snackbar(
        'Authentication required',
        'Unable to determine the authenticated teacher.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      final teacherDoc =
          await _db.firestore.collection('teachers').doc(teacherId).get();
      if (teacherDoc.exists) {
        setTeacher(TeacherModel.fromDoc(teacherDoc));
      }

      final classesSnap = await _db.firestore.collection('classes').get();
      final teacherClasses = classesSnap.docs
          .map(SchoolClassModel.fromDoc)
          .where((item) => item.teacherSubjects.values.contains(teacherId))
          .toList();
      setClasses(teacherClasses);

      final homeworkSnap = await _db.firestore
          .collection('homeworks')
          .where('teacherId', isEqualTo: teacherId)
          .get();
      setHomeworks(homeworkSnap.docs.map(HomeworkModel.fromDoc).toList());
    } catch (error) {
      Get.snackbar(
        'Refresh failed',
        'Unable to refresh homework data: $error',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    _teacherSubscription?.cancel();
    _classesSubscription?.cancel();
    _homeworksSubscription?.cancel();
    super.onClose();
  }

  void setTeacher(TeacherModel value) {
    teacher.value = value;
  }

  void setClasses(List<SchoolClassModel> items) {
    classes.assignAll(
      List<SchoolClassModel>.from(items)
        ..sort((a, b) => a.name.compareTo(b.name)),
    );
    if (selectedClass.value != null) {
      final classId = selectedClass.value!.id;
      selectedClass.value =
          classes.firstWhereOrNull((item) => item.id == classId);
    }
    if (filterClassId.value != null &&
        classes.firstWhereOrNull((item) => item.id == filterClassId.value) ==
            null) {
      filterClassId.value = null;
    }
  }

  void setHomeworks(List<HomeworkModel> items) {
    _allHomeworks.assignAll(items);
    _applyFilters();
  }

  void setFilterClass(String? classId) {
    filterClassId.value = classId == null || classId.isEmpty ? null : classId;
    _applyFilters();
  }

  void clearFilters() {
    filterClassId.value = null;
    _applyFilters();
  }

  int? childCountForClass(String classId) {
    final classModel =
        classes.firstWhereOrNull((item) => item.id == classId);
    return classModel?.childIds.length;
  }

  String className(String id) {
    return classes.firstWhereOrNull((item) => item.id == id)?.name ?? 'Class';
  }

  void _applyFilters() {
    final filtered = _allHomeworks.where((homework) {
      final matchesClass =
          filterClassId.value == null || filterClassId.value!.isEmpty
              ? true
              : homework.classId == filterClassId.value;
      return matchesClass;
    }).toList()
      ..sort((a, b) => b.dueDate.compareTo(a.dueDate));
    homeworks.assignAll(filtered);
  }

  void startCreate() {
    editing = null;
    titleController.clear();
    descriptionController.clear();
    selectedClass.value = null;
    dueDate.value = null;
  }

  void startEdit(HomeworkModel homework) {
    editing = homework;
    titleController.text = homework.title;
    descriptionController.text = homework.description;
    selectedClass.value =
        classes.firstWhereOrNull((item) => item.id == homework.classId);
    dueDate.value = homework.dueDate;
  }

  Future<bool> saveHomework() async {
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();
    final classModel = selectedClass.value;
    final teacherModel = teacher.value;
    final selectedDueDate = dueDate.value;

    if (title.isEmpty || classModel == null || selectedDueDate == null) {
      Get.snackbar(
        'Incomplete form',
        'Please provide a title, class, and due date.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
    if (teacherModel == null) {
      Get.snackbar(
        'Profile incomplete',
        'Unable to determine the authenticated teacher.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    isSaving.value = true;
    try {
      final now = DateTime.now();
      final collection = _db.firestore.collection('homeworks');
      final docRef =
          editing == null ? collection.doc() : collection.doc(editing!.id);
      final homework = HomeworkModel(
        id: docRef.id,
        title: title,
        description: description,
        classId: classModel.id,
        className: classModel.name,
        teacherId: teacherModel.id,
        teacherName: teacherModel.name,
        assignedDate: editing?.assignedDate ?? now,
        dueDate: selectedDueDate,
        completionByChildId:
            editing?.completionByChildId ?? <String, bool>{},
      );
      await docRef.set(homework.toMap());
      startCreate();
      return true;
    } finally {
      isSaving.value = false;
    }
  }

  void removeHomework(HomeworkModel homework) {
    _allHomeworks.removeWhere((item) => item.id == homework.id);
    _applyFilters();
    _db.firestore.collection('homeworks').doc(homework.id).delete();
  }

  Future<void> _initialize() async {
    try {
      final teacherId = _auth.currentUser?.uid;
      if (teacherId == null) {
        Get.snackbar(
          'Authentication required',
          'Unable to determine the authenticated teacher.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      isLoading.value = true;

      _teacherSubscription = _db.firestore
          .collection('teachers')
          .doc(teacherId)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          setTeacher(TeacherModel.fromDoc(snapshot));
        }
        _teacherLoaded = true;
        _maybeFinishLoading();
      });

      _classesSubscription = _db.firestore
          .collection('classes')
          .snapshots()
          .listen((snapshot) {
        final teacherClasses = snapshot.docs
            .map(SchoolClassModel.fromDoc)
            .where((item) => item.teacherSubjects.values.contains(teacherId))
            .toList();
        setClasses(teacherClasses);
        _classesLoaded = true;
        _maybeFinishLoading();
      });

      _homeworksSubscription = _db.firestore
          .collection('homeworks')
          .where('teacherId', isEqualTo: teacherId)
          .snapshots()
          .listen((snapshot) {
        setHomeworks(snapshot.docs.map(HomeworkModel.fromDoc).toList());
        _homeworksLoaded = true;
        _maybeFinishLoading();
      });
    } catch (error) {
      isLoading.value = false;
      Get.snackbar(
        'Load failed',
        'Unable to load homework data: $error',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _maybeFinishLoading() {
    if (_teacherLoaded && _classesLoaded && _homeworksLoaded) {
      isLoading.value = false;
    }
  }
}
