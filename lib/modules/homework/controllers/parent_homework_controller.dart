import 'package:collection/collection.dart';
import 'package:get/get.dart';

import '../../../data/models/child_model.dart';
import '../../../data/models/homework_model.dart';

class ParentHomeworkController extends GetxController {
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
    _applyFilters();
  }

  void setHomeworks(List<HomeworkModel> items) {
    _allHomeworks.assignAll(items);
    _applyFilters();
  }

  void setChildFilter(String? childId) {
    childFilter.value = childId;
    _applyFilters();
  }

  void setCompletionFilter(bool? value) {
    completionFilter.value = value;
    _applyFilters();
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

  void markCompletion(HomeworkModel homework, String childId, bool completed) {
    final updatedMap = Map<String, bool>.from(homework.completionByChildId)
      ..[childId] = completed;
    final updatedHomework =
        homework.copyWith(completionByChildId: updatedMap);
    final index = _allHomeworks.indexWhere((item) => item.id == homework.id);
    if (index != -1) {
      _allHomeworks[index] = updatedHomework;
      _applyFilters();
    }
  }
}
