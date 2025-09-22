import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/homework_model.dart';
import '../../../data/models/school_class_model.dart';
import '../../../data/models/teacher_model.dart';

class TeacherHomeworkController extends GetxController {
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
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  void setTeacher(TeacherModel value) {
    teacher.value = value;
  }

  void setClasses(List<SchoolClassModel> items) {
    classes.assignAll(items);
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
    filterClassId.value = classId;
    _applyFilters();
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
      final homework = HomeworkModel(
        id: editing?.id ?? now.millisecondsSinceEpoch.toString(),
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
      if (editing == null) {
        _allHomeworks.add(homework);
      } else {
        final index =
            _allHomeworks.indexWhere((item) => item.id == editing!.id);
        if (index != -1) {
          _allHomeworks[index] = homework;
        }
      }
      _applyFilters();
      startCreate();
      return true;
    } finally {
      isSaving.value = false;
    }
  }

  void removeHomework(HomeworkModel homework) {
    _allHomeworks.removeWhere((item) => item.id == homework.id);
    _applyFilters();
  }
}
