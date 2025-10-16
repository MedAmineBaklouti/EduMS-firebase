import 'dart:async';

import 'package:get/get.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/database_service.dart';
import '../models/behavior_model.dart';
import '../../common/models/child_model.dart';

class ParentBehaviorController extends GetxController {
  final DatabaseService _db = Get.find();
  final AuthService _auth = Get.find();

  final RxList<BehaviorModel> _allBehaviors = <BehaviorModel>[].obs;
  final RxList<BehaviorModel> behaviors = <BehaviorModel>[].obs;
  final RxList<ChildModel> children = <ChildModel>[].obs;

  final List<BehaviorModel> _rawBehaviors = <BehaviorModel>[];
  final List<String> _childIds = <String>[];

  StreamSubscription? _childrenSubscription;
  StreamSubscription? _behaviorsSubscription;

  final RxnString childFilter = RxnString();
  final Rxn<BehaviorType> typeFilter = Rxn<BehaviorType>();
  final RxBool isLoading = false.obs;

  bool _childrenLoaded = false;
  bool _behaviorsLoaded = false;

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  @override
  void onClose() {
    _childrenSubscription?.cancel();
    _behaviorsSubscription?.cancel();
    super.onClose();
  }

  void setChildren(List<ChildModel> items) {
    children.assignAll(items);
    _childIds
      ..clear()
      ..addAll(items.map((child) => child.id));
    if (childFilter.value != null &&
        !children.any((child) => child.id == childFilter.value)) {
      childFilter.value = null;
    }
    if (children.length == 1 &&
        (childFilter.value == null || childFilter.value!.isEmpty)) {
      childFilter.value = children.first.id;
    }
    _childrenLoaded = true;
    _updateVisibleBehaviors();
    _maybeFinishLoading();
  }

  void setBehaviors(List<BehaviorModel> items) {
    _rawBehaviors
      ..clear()
      ..addAll(items);
    _behaviorsLoaded = true;
    _updateVisibleBehaviors();
    _maybeFinishLoading();
  }

  void setChildFilter(String? childId) {
    childFilter.value = childId;
    _applyFilters();
  }

  void setTypeFilter(BehaviorType? type) {
    typeFilter.value = type;
    _applyFilters();
  }

  void clearFilters() {
    childFilter.value = null;
    typeFilter.value = null;
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

    final behaviorSnapshot = await _db.firestore.collection('behaviors').get();
    setBehaviors(behaviorSnapshot.docs.map(BehaviorModel.fromDoc).toList());
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

    _behaviorsSubscription =
        _db.firestore.collection('behaviors').snapshots().listen((snapshot) {
      setBehaviors(snapshot.docs.map(BehaviorModel.fromDoc).toList());
    });
  }

  void _updateVisibleBehaviors() {
    if (_childIds.isEmpty) {
      _allBehaviors.clear();
      _applyFilters();
      return;
    }
    final relevant = _rawBehaviors
        .where((behavior) => _childIds.contains(behavior.childId))
        .toList();
    _allBehaviors.assignAll(relevant);
    _applyFilters();
  }

  void _maybeFinishLoading() {
    if (_childrenLoaded && _behaviorsLoaded) {
      isLoading.value = false;
    }
  }
}
