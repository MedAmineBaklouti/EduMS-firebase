import 'dart:async';

import 'package:collection/collection.dart';
import 'package:get/get.dart';

import '../../../common/services/database_service.dart';
import '../models/behavior_model.dart';
import '../../../common/models/school_class_model.dart';
import '../../../common/models/teacher_model.dart';

class AdminBehaviorController extends GetxController {
  final DatabaseService _db = Get.find();

  final RxList<BehaviorModel> _allBehaviors = <BehaviorModel>[].obs;
  final RxList<BehaviorModel> behaviors = <BehaviorModel>[].obs;

  final RxList<SchoolClassModel> classes = <SchoolClassModel>[].obs;
  final RxList<TeacherModel> teachers = <TeacherModel>[].obs;

  final RxnString classFilter = RxnString();
  final RxnString teacherFilter = RxnString();
  final Rxn<BehaviorType> typeFilter = Rxn<BehaviorType>();
  final RxBool isLoading = false.obs;

  StreamSubscription? _classesSubscription;
  StreamSubscription? _teachersSubscription;
  StreamSubscription? _behaviorsSubscription;

  bool _classesLoaded = false;
  bool _teachersLoaded = false;
  bool _behaviorsLoaded = false;

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  @override
  void onClose() {
    _classesSubscription?.cancel();
    _teachersSubscription?.cancel();
    _behaviorsSubscription?.cancel();
    super.onClose();
  }

  void setClasses(List<SchoolClassModel> items) {
    classes.assignAll(items);
    if (classFilter.value != null &&
        classes.firstWhereOrNull((item) => item.id == classFilter.value) ==
            null) {
      classFilter.value = null;
    }
  }

  void setTeachers(List<TeacherModel> items) {
    teachers.assignAll(items);
    if (teacherFilter.value != null &&
        teachers.firstWhereOrNull((item) => item.id == teacherFilter.value) ==
            null) {
      teacherFilter.value = null;
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

  void setTeacherFilter(String? teacherId) {
    teacherFilter.value = teacherId;
    _applyFilters();
  }

  void setTypeFilter(BehaviorType? type) {
    typeFilter.value = type;
    _applyFilters();
  }

  void clearFilters() {
    classFilter.value = null;
    teacherFilter.value = null;
    typeFilter.value = null;
    _applyFilters();
  }

  void _applyFilters() {
    final filtered = _allBehaviors.where((behavior) {
      final matchesClass =
          classFilter.value == null || classFilter.value!.isEmpty
              ? true
              : behavior.classId == classFilter.value;
      final matchesTeacher =
          teacherFilter.value == null || teacherFilter.value!.isEmpty
              ? true
              : behavior.teacherId == teacherFilter.value;
      final matchesType =
          typeFilter.value == null || behavior.type == typeFilter.value;
      return matchesClass && matchesTeacher && matchesType;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    behaviors.assignAll(filtered);
  }

  String? className(String classId) {
    return classes.firstWhereOrNull((item) => item.id == classId)?.name;
  }

  String? teacherName(String teacherId) {
    return teachers.firstWhereOrNull((item) => item.id == teacherId)?.name;
  }

  Future<void> refreshData() async {
    final classSnapshot = await _db.firestore.collection('classes').get();
    setClasses(
      classSnapshot.docs.map(SchoolClassModel.fromDoc).toList(),
    );

    final teacherSnapshot = await _db.firestore.collection('teachers').get();
    setTeachers(
      teacherSnapshot.docs.map(TeacherModel.fromDoc).toList(),
    );

    final behaviorSnapshot = await _db.firestore.collection('behaviors').get();
    setBehaviors(
      behaviorSnapshot.docs.map(BehaviorModel.fromDoc).toList(),
    );
  }

  void _initialize() {
    isLoading.value = true;

    _classesSubscription =
        _db.firestore.collection('classes').snapshots().listen((snapshot) {
      setClasses(snapshot.docs.map(SchoolClassModel.fromDoc).toList());
      _classesLoaded = true;
      _maybeFinishLoading();
    });

    _teachersSubscription =
        _db.firestore.collection('teachers').snapshots().listen((snapshot) {
      setTeachers(snapshot.docs.map(TeacherModel.fromDoc).toList());
      _teachersLoaded = true;
      _maybeFinishLoading();
    });

    _behaviorsSubscription =
        _db.firestore.collection('behaviors').snapshots().listen((snapshot) {
      setBehaviors(snapshot.docs.map(BehaviorModel.fromDoc).toList());
      _behaviorsLoaded = true;
      _maybeFinishLoading();
    });
  }

  void _maybeFinishLoading() {
    if (_classesLoaded && _teachersLoaded && _behaviorsLoaded) {
      isLoading.value = false;
    }
  }
}
