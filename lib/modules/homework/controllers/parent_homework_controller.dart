import 'dart:async';

import 'package:collection/collection.dart';
import 'package:get/get.dart';

import 'package:edums/modules/auth/service/auth_service.dart';
import '../../../common/services/database_service.dart';
import '../../common/models/child_model.dart';
import '../models/homework_model.dart';

class ParentHomeworkController extends GetxController {
  final DatabaseService _db = Get.find();
  final AuthService _auth = Get.find();

  final List<HomeworkModel> _rawHomeworks = <HomeworkModel>[];
  final Set<String> _classIds = <String>{};

  StreamSubscription? _childrenSubscription;
  StreamSubscription? _homeworksSubscription;

  bool _childrenLoaded = false;
  bool _homeworksLoaded = false;

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  @override
  void onClose() {
    _childrenSubscription?.cancel();
    _homeworksSubscription?.cancel();
    super.onClose();
  }

  final RxList<HomeworkModel> _allHomeworks = <HomeworkModel>[].obs;
  final RxList<HomeworkModel> homeworks = <HomeworkModel>[].obs;
  final RxList<ChildModel> children = <ChildModel>[].obs;

  final RxnString childFilter = RxnString();
  final RxnBool completionFilter = RxnBool();
  final RxBool isLoading = false.obs;

  String? get activeChildId {
    final filter = childFilter.value;
    if (filter != null && filter.isNotEmpty) {
      return filter;
    }
    if (children.length == 1) {
      return children.first.id;
    }
    return null;
  }

  ChildModel? get activeChild {
    final id = activeChildId;
    if (id == null) {
      return null;
    }
    return children.firstWhereOrNull((child) => child.id == id);
  }

  void setChildren(List<ChildModel> items) {
    children.assignAll(items);
    if (childFilter.value != null &&
        children.firstWhereOrNull((child) => child.id == childFilter.value) ==
            null) {
      childFilter.value = null;
    }
    _classIds
      ..clear()
      ..addAll(
        items
            .map((child) => child.classId)
            .where((classId) => classId.isNotEmpty),
      );
    if (children.length == 1 &&
        (childFilter.value == null || childFilter.value!.isEmpty)) {
      childFilter.value = children.first.id;
    }
    _childrenLoaded = true;
    _updateVisibleHomeworks();
    _maybeFinishLoading();
  }

  void setHomeworks(List<HomeworkModel> items) {
    _rawHomeworks
      ..clear()
      ..addAll(items);
    _homeworksLoaded = true;
    _updateVisibleHomeworks();
    _maybeFinishLoading();
  }

  void setChildFilter(String? childId) {
    childFilter.value = childId;
    _applyFilters();
  }

  void setCompletionFilter(bool? value) {
    completionFilter.value = value;
    _applyFilters();
  }

  void clearFilters() {
    childFilter.value = null;
    completionFilter.value = null;
    _applyFilters();
  }

  List<ChildModel> childrenForClass(String classId) {
    return children
        .where((child) => child.classId == classId)
        .toList();
  }

  int childCountForClass(String classId) {
    return childrenForClass(classId).length;
  }

  String childName(String id) {
    return children
            .firstWhereOrNull((child) => child.id == id)
            ?.name ??
        'Child';
  }

  Future<void> refreshData() async {
    final parentId = _auth.currentUser?.uid;
    if (parentId == null) {
      return;
    }
    final childrenSnapshot = await _db.firestore
        .collection('children')
        .where('parentId', isEqualTo: parentId)
        .get();
    setChildren(childrenSnapshot.docs.map(ChildModel.fromDoc).toList());

    final homeworkSnapshot = await _db.firestore.collection('homeworks').get();
    setHomeworks(homeworkSnapshot.docs.map(HomeworkModel.fromDoc).toList());
  }

  void _applyFilters() {
    final selectedChildId = childFilter.value;
    final selectedChild = children
        .firstWhereOrNull((child) => child.id == selectedChildId);
    final classIdForChild = selectedChild?.classId;
    final completion = completionFilter.value;

    final filtered = _allHomeworks.where((homework) {
      final matchesChild = classIdForChild == null
          ? true
          : homework.classId == classIdForChild;
      bool matchesCompletion = true;
      if (completion != null && selectedChildId != null) {
        final isCompleted = homework.isCompletedForChild(selectedChildId);
        matchesCompletion = completion ? isCompleted : !isCompleted;
      }
      return matchesChild && matchesCompletion;
    }).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    homeworks.assignAll(filtered);
  }

  Future<bool> markCompletion(
      HomeworkModel homework, String childId, bool completed) async {
    final updatedMap = Map<String, bool>.from(homework.completionByChildId)
      ..[childId] = completed;
    final updatedHomework =
        homework.copyWith(completionByChildId: updatedMap);

    final index = _allHomeworks.indexWhere((item) => item.id == homework.id);
    final rawIndex = _rawHomeworks.indexWhere((item) => item.id == homework.id);

    if (index == -1) {
      return false;
    }

    _allHomeworks[index] = updatedHomework;
    if (rawIndex != -1) {
      _rawHomeworks[rawIndex] = updatedHomework;
    }
    _applyFilters();

    try {
      await _db.firestore.collection('homeworks').doc(homework.id).update({
        'completionByChildId.$childId': completed,
      });
      return true;
    } catch (e) {
      _allHomeworks[index] = homework;
      if (rawIndex != -1) {
        _rawHomeworks[rawIndex] = homework;
      }
      _applyFilters();
      Get.snackbar(
        'Update failed',
        'Unable to update the homework status. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  void _initialize() {
    final parentId = _auth.currentUser?.uid;
    if (parentId == null) {
      isLoading.value = false;
      return;
    }
    isLoading.value = true;

    _childrenSubscription = _db.firestore
        .collection('children')
        .where('parentId', isEqualTo: parentId)
        .snapshots()
        .listen((snapshot) {
      setChildren(snapshot.docs.map(ChildModel.fromDoc).toList());
    });

    _homeworksSubscription =
        _db.firestore.collection('homeworks').snapshots().listen((snapshot) {
      setHomeworks(snapshot.docs.map(HomeworkModel.fromDoc).toList());
    });
  }

  void _updateVisibleHomeworks() {
    if (_classIds.isEmpty) {
      _allHomeworks.clear();
      _applyFilters();
      return;
    }
    final relevant = _rawHomeworks
        .where((homework) => _classIds.contains(homework.classId))
        .toList();
    _allHomeworks.assignAll(relevant);
    _applyFilters();
  }

  void _maybeFinishLoading() {
    if (_childrenLoaded && _homeworksLoaded) {
      isLoading.value = false;
    }
  }
}
