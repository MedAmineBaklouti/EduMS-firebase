import 'package:get/get.dart';

import '../../../data/models/behavior_model.dart';
import '../../../data/models/child_model.dart';

class ParentBehaviorController extends GetxController {
  final RxList<BehaviorModel> _allBehaviors = <BehaviorModel>[].obs;
  final RxList<BehaviorModel> behaviors = <BehaviorModel>[].obs;
  final RxList<ChildModel> children = <ChildModel>[].obs;

  final RxnString childFilter = RxnString();
  final Rxn<BehaviorType> typeFilter = Rxn<BehaviorType>();
  final RxBool isLoading = false.obs;

  void setChildren(List<ChildModel> items) {
    children.assignAll(items);
    if (childFilter.value != null &&
        !children.any((child) => child.id == childFilter.value)) {
      childFilter.value = null;
    }
  }

  void setBehaviors(List<BehaviorModel> items) {
    _allBehaviors.assignAll(items);
    _applyFilters();
  }

  void setChildFilter(String? childId) {
    childFilter.value = childId;
    _applyFilters();
  }

  void setTypeFilter(BehaviorType? type) {
    typeFilter.value = type;
    _applyFilters();
  }

  void _applyFilters() {
    final filtered = _allBehaviors.where((behavior) {
      final matchesChild =
          childFilter.value == null || childFilter.value!.isEmpty
              ? true
              : behavior.childId == childFilter.value;
      final matchesType =
          typeFilter.value == null || behavior.type == typeFilter.value;
      return matchesChild && matchesType;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    behaviors.assignAll(filtered);
  }
}
