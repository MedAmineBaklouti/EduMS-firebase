import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/behavior_model.dart';
import '../../../data/models/child_model.dart';
import '../../../data/models/school_class_model.dart';
import '../../../data/models/teacher_model.dart';

class TeacherBehaviorController extends GetxController {
  final RxList<BehaviorModel> _allBehaviors = <BehaviorModel>[].obs;
  final RxList<BehaviorModel> behaviors = <BehaviorModel>[].obs;

  final RxList<SchoolClassModel> classes = <SchoolClassModel>[].obs;
  final Map<String, List<ChildModel>> _childrenByClass =
      <String, List<ChildModel>>{};
  final RxList<ChildModel> availableChildren = <ChildModel>[].obs;

  final Rxn<SchoolClassModel> selectedClass = Rxn<SchoolClassModel>();
  final Rxn<ChildModel> selectedChild = Rxn<ChildModel>();
  final Rx<BehaviorType> selectedBehaviorType = BehaviorType.positive.obs;
  final RxnString classFilter = RxnString();
  final Rxn<BehaviorType> typeFilter = Rxn<BehaviorType>();
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;

  final TextEditingController descriptionController = TextEditingController();
  final Rxn<TeacherModel> teacher = Rxn<TeacherModel>();

  BehaviorModel? editing;

  @override
  void onClose() {
    descriptionController.dispose();
    super.onClose();
  }

  void setTeacher(TeacherModel value) {
    teacher.value = value;
  }

  void setClasses(List<SchoolClassModel> items) {
    classes.assignAll(items);
    if (selectedClass.value != null) {
      final previousId = selectedClass.value!.id;
      selectedClass.value =
          classes.firstWhereOrNull((item) => item.id == previousId);
    }
  }

  void registerChildren(String classId, List<ChildModel> children) {
    _childrenByClass[classId] = children;
    if (selectedClass.value?.id == classId) {
      availableChildren.assignAll(children);
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
      final matchesType =
          typeFilter.value == null || behavior.type == typeFilter.value;
      return matchesClass && matchesType;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    behaviors.assignAll(filtered);
  }

  void startCreate() {
    editing = null;
    descriptionController.clear();
    selectedClass.value = null;
    selectedChild.value = null;
    selectedBehaviorType.value = BehaviorType.positive;
  }

  void startEdit(BehaviorModel behavior) {
    editing = behavior;
    descriptionController.text = behavior.description;
    selectedBehaviorType.value = behavior.type;
    final relatedClass =
        classes.firstWhereOrNull((item) => item.id == behavior.classId);
    selectedClass.value = relatedClass;
    availableChildren.assignAll(
        _childrenByClass[behavior.classId] ?? <ChildModel>[]);
    selectedChild.value = (_childrenByClass[behavior.classId] ?? <ChildModel>[])
        .firstWhereOrNull((child) => child.id == behavior.childId);
  }

  void selectClass(SchoolClassModel schoolClass) {
    selectedClass.value = schoolClass;
    availableChildren.assignAll(
        _childrenByClass[schoolClass.id] ?? <ChildModel>[]);
    selectedChild.value = null;
  }

  void selectChild(ChildModel child) {
    selectedChild.value = child;
  }

  Future<bool> saveBehavior() async {
    final currentClass = selectedClass.value;
    final currentChild = selectedChild.value;
    final teacherModel = teacher.value;
    if (currentClass == null || currentChild == null) {
      Get.snackbar(
        'Missing information',
        'Please select a class and a child before saving the behavior.',
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
      final model = BehaviorModel(
        id: editing?.id ?? now.millisecondsSinceEpoch.toString(),
        childId: currentChild.id,
        childName: currentChild.name,
        classId: currentClass.id,
        className: currentClass.name,
        teacherId: teacherModel.id,
        teacherName: teacherModel.name,
        type: selectedBehaviorType.value,
        description: descriptionController.text.trim(),
        createdAt: editing?.createdAt ?? now,
      );
      if (editing == null) {
        _allBehaviors.add(model);
      } else {
        final index =
            _allBehaviors.indexWhere((element) => element.id == editing!.id);
        if (index != -1) {
          _allBehaviors[index] = model;
        }
      }
      _applyFilters();
      startCreate();
      return true;
    } finally {
      isSaving.value = false;
    }
  }

  void removeBehavior(BehaviorModel behavior) {
    _allBehaviors.removeWhere((item) => item.id == behavior.id);
    _applyFilters();
  }
}
