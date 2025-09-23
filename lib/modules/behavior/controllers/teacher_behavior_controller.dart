import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/database_service.dart';
import '../../../data/models/behavior_model.dart';
import '../../../data/models/child_model.dart';
import '../../../data/models/school_class_model.dart';
import '../../../data/models/teacher_model.dart';

class TeacherBehaviorController extends GetxController {
  final DatabaseService _db = Get.find();
  final AuthService _auth = Get.find();

  final RxList<BehaviorModel> _allBehaviors = <BehaviorModel>[].obs;
  final RxList<BehaviorModel> behaviors = <BehaviorModel>[].obs;

  final RxList<SchoolClassModel> classes = <SchoolClassModel>[].obs;
  final Map<String, List<ChildModel>> _childrenByClass =
      <String, List<ChildModel>>{};
  final RxList<ChildModel> availableChildren = <ChildModel>[].obs;

  final Map<String, StreamSubscription> _childrenSubscriptions =
      <String, StreamSubscription>{};
  StreamSubscription? _teacherSubscription;
  StreamSubscription? _classesSubscription;
  StreamSubscription? _behaviorsSubscription;

  final Rxn<SchoolClassModel> selectedClass = Rxn<SchoolClassModel>();
  final Rxn<ChildModel> selectedChild = Rxn<ChildModel>();
  final Rx<BehaviorType> selectedBehaviorType = BehaviorType.positive.obs;
  final RxnString classFilter = RxnString();
  final Rxn<BehaviorType> typeFilter = Rxn<BehaviorType>();
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;

  bool _teacherLoaded = false;
  bool _classesLoaded = false;
  bool _behaviorsLoaded = false;

  final TextEditingController descriptionController = TextEditingController();
  final Rxn<TeacherModel> teacher = Rxn<TeacherModel>();

  BehaviorModel? editing;

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  @override
  void onClose() {
    descriptionController.dispose();
    _teacherSubscription?.cancel();
    _classesSubscription?.cancel();
    _behaviorsSubscription?.cancel();
    for (final sub in _childrenSubscriptions.values) {
      sub.cancel();
    }
    _childrenSubscriptions.clear();
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
    if (selectedClass.value == null && classes.isNotEmpty && editing == null) {
      selectedClass.value = classes.first;
      availableChildren.assignAll(
          _childrenByClass[selectedClass.value!.id] ?? <ChildModel>[]);
      if (availableChildren.length == 1) {
        selectedChild.value = availableChildren.first;
      }
    }
  }

  void registerChildren(String classId, List<ChildModel> children) {
    _childrenByClass[classId] = children;
    if (selectedClass.value?.id == classId) {
      availableChildren.assignAll(children);
      if (editing != null && editing!.classId == classId) {
        selectedChild.value =
            children.firstWhereOrNull((child) => child.id == editing!.childId);
      } else if (selectedChild.value != null) {
        selectedChild.value = children
            .firstWhereOrNull((child) => child.id == selectedChild.value!.id);
      } else if (children.length == 1 && editing == null) {
        selectedChild.value = children.first;
      }
    }
    if (selectedClass.value == null &&
        classes.length == 1 &&
        classes.first.id == classId &&
        editing == null) {
      selectedClass.value = classes.first;
      availableChildren.assignAll(children);
      if (children.length == 1) {
        selectedChild.value = children.first;
      }
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

  void clearFilters() {
    classFilter.value = null;
    typeFilter.value = null;
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

  String classNameFor(String id) {
    for (final schoolClass in classes) {
      if (schoolClass.id == id) {
        return schoolClass.name;
      }
    }
    return 'Class';
  }

  void startCreate() {
    editing = null;
    descriptionController.clear();
    selectedClass.value = null;
    selectedChild.value = null;
    availableChildren.clear();
    selectedBehaviorType.value = BehaviorType.positive;
    if (classes.length == 1) {
      final firstClass = classes.first;
      selectedClass.value = firstClass;
      availableChildren.assignAll(
          _childrenByClass[firstClass.id] ?? <ChildModel>[]);
      if (availableChildren.length == 1) {
        selectedChild.value = availableChildren.first;
      }
    }
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
      final collection = _db.firestore.collection('behaviors');
      final docRef = editing == null
          ? collection.doc()
          : collection.doc(editing!.id);
      final model = BehaviorModel(
        id: docRef.id,
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
      await docRef.set(model.toMap());
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
    } catch (e) {
      Get.snackbar(
        'Save failed',
        'Unable to save the behavior record: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> removeBehavior(BehaviorModel behavior) async {
    _allBehaviors.removeWhere((item) => item.id == behavior.id);
    _applyFilters();
    await _db.firestore.collection('behaviors').doc(behavior.id).delete();
  }

  Future<void> refreshData() async {
    final teacherId = _auth.currentUser?.uid;
    if (teacherId == null) {
      return;
    }
    final classSnapshot = await _db.firestore.collection('classes').get();
    final teacherClasses = classSnapshot.docs
        .map((doc) => SchoolClassModel.fromDoc(doc))
        .where((item) => item.teacherSubjects.values.contains(teacherId))
        .toList();
    setClasses(teacherClasses);
    for (final schoolClass in teacherClasses) {
      final childrenSnapshot = await _db.firestore
          .collection('children')
          .where('classId', isEqualTo: schoolClass.id)
          .get();
      registerChildren(
        schoolClass.id,
        childrenSnapshot.docs.map(ChildModel.fromDoc).toList(),
      );
    }
    final behaviorSnapshot = await _db.firestore
        .collection('behaviors')
        .where('teacherId', isEqualTo: teacherId)
        .get();
    setBehaviors(
      behaviorSnapshot.docs.map(BehaviorModel.fromDoc).toList(),
    );
  }

  void _initialize() {
    final teacherId = _auth.currentUser?.uid;
    if (teacherId == null) {
      isLoading.value = false;
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

    _classesSubscription =
        _db.firestore.collection('classes').snapshots().listen((snapshot) {
      final allClasses =
          snapshot.docs.map((doc) => SchoolClassModel.fromDoc(doc)).toList();
      final teacherClasses = allClasses
          .where((item) => item.teacherSubjects.values.contains(teacherId))
          .toList();
      setClasses(teacherClasses);
      _syncChildrenListeners(teacherClasses);
      _classesLoaded = true;
      _maybeFinishLoading();
    });

    _behaviorsSubscription = _db.firestore
        .collection('behaviors')
        .where('teacherId', isEqualTo: teacherId)
        .snapshots()
        .listen((snapshot) {
      setBehaviors(
        snapshot.docs.map(BehaviorModel.fromDoc).toList(),
      );
      _behaviorsLoaded = true;
      _maybeFinishLoading();
    });
  }

  void _syncChildrenListeners(List<SchoolClassModel> teacherClasses) {
    final currentClassIds = teacherClasses.map((item) => item.id).toSet();
    final existingIds = _childrenSubscriptions.keys.toSet();

    for (final removedId in existingIds.difference(currentClassIds)) {
      _childrenSubscriptions.remove(removedId)?.cancel();
      _childrenByClass.remove(removedId);
    }

    for (final schoolClass in teacherClasses) {
      if (_childrenSubscriptions.containsKey(schoolClass.id)) {
        continue;
      }
      final subscription = _db.firestore
          .collection('children')
          .where('classId', isEqualTo: schoolClass.id)
          .snapshots()
          .listen((snapshot) {
        registerChildren(
          schoolClass.id,
          snapshot.docs.map(ChildModel.fromDoc).toList(),
        );
      });
      _childrenSubscriptions[schoolClass.id] = subscription;
    }
  }

  void _maybeFinishLoading() {
    if (_teacherLoaded && _classesLoaded && _behaviorsLoaded) {
      isLoading.value = false;
    }
  }
}
