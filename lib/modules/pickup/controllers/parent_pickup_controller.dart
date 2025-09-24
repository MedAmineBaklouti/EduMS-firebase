import 'dart:async';

import 'package:collection/collection.dart';
import 'package:get/get.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/database_service.dart';
import '../../../data/models/child_model.dart';
import '../../../data/models/pickup_model.dart';

class ParentPickupController extends GetxController {
  final DatabaseService _db = Get.find();
  final AuthService _auth = Get.find();

  StreamSubscription? _childrenSubscription;
  StreamSubscription? _ticketsSubscription;

  bool _childrenLoaded = false;
  bool _ticketsLoaded = false;

  final Set<String> _childIds = <String>{};

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  @override
  void onClose() {
    _childrenSubscription?.cancel();
    _ticketsSubscription?.cancel();
    super.onClose();
  }

  final RxList<PickupTicketModel> _allTickets = <PickupTicketModel>[].obs;
  final RxList<PickupTicketModel> tickets = <PickupTicketModel>[].obs;
  final RxList<ChildModel> children = <ChildModel>[].obs;

  final RxnString childFilter = RxnString();
  final RxBool isLoading = false.obs;

  void clearFilters() {
    childFilter.value = null;
    _applyFilters();
  }

  void setChildren(List<ChildModel> items) {
    children.assignAll(items);
    if (childFilter.value != null &&
        children.firstWhereOrNull((child) => child.id == childFilter.value) ==
            null) {
      childFilter.value = null;
    }
    _childIds
      ..clear()
      ..addAll(items.map((child) => child.id));
    if (children.length == 1 &&
        (childFilter.value == null || childFilter.value!.isEmpty)) {
      childFilter.value = children.first.id;
    }
    _applyFilters();
    _childrenLoaded = true;
    _maybeFinishLoading();
  }

  void setTickets(List<PickupTicketModel> items) {
    _allTickets.assignAll(items);
    _applyFilters();
    _ticketsLoaded = true;
    _maybeFinishLoading();
  }

  void setChildFilter(String? childId) {
    childFilter.value = childId;
    _applyFilters();
  }

  void _applyFilters() {
    final childId = childFilter.value;
    if (_childIds.isEmpty) {
      tickets.clear();
      return;
    }
    final relevantTickets = _allTickets.where((ticket) {
      return _childIds.contains(ticket.childId);
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (childId == null || childId.isEmpty) {
      tickets.assignAll(relevantTickets);
      return;
    }

    tickets.assignAll(
      relevantTickets.where((ticket) => ticket.childId == childId).toList(),
    );
  }

  Future<void> confirmPickup(PickupTicketModel ticket) async {
    final updated = ticket.copyWith(
      parentConfirmedAt: DateTime.now(),
    );
    final index = _allTickets.indexWhere((item) => item.id == ticket.id);
    if (index != -1) {
      _allTickets[index] = updated;
      _applyFilters();
    }
    await _db.firestore
        .collection('pickupTickets')
        .doc(ticket.id)
        .update(updated.toMap());
  }

  void _initialize() {
    final parentId = _auth.currentUser?.uid;
    if (parentId == null) {
      Get.snackbar(
        'Authentication required',
        'Unable to determine the authenticated parent.',
        snackPosition: SnackPosition.BOTTOM,
      );
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

    _ticketsSubscription = _db.firestore
        .collection('pickupTickets')
        .snapshots()
        .listen((snapshot) {
      setTickets(snapshot.docs.map(PickupTicketModel.fromDoc).toList());
    });
  }

  void _maybeFinishLoading() {
    if (_childrenLoaded && _ticketsLoaded) {
      isLoading.value = false;
    }
  }
}
