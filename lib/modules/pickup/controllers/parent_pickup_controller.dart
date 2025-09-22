import 'package:collection/collection.dart';
import 'package:get/get.dart';

import '../../../data/models/child_model.dart';
import '../../../data/models/pickup_model.dart';

class ParentPickupController extends GetxController {
  final RxList<PickupTicketModel> _allTickets = <PickupTicketModel>[].obs;
  final RxList<PickupTicketModel> tickets = <PickupTicketModel>[].obs;
  final RxList<ChildModel> children = <ChildModel>[].obs;

  final RxnString childFilter = RxnString();
  final RxBool isLoading = false.obs;

  void setChildren(List<ChildModel> items) {
    children.assignAll(items);
    if (childFilter.value != null &&
        children.firstWhereOrNull((child) => child.id == childFilter.value) ==
            null) {
      childFilter.value = null;
    }
    _applyFilters();
  }

  void setTickets(List<PickupTicketModel> items) {
    _allTickets.assignAll(items);
    _applyFilters();
  }

  void setChildFilter(String? childId) {
    childFilter.value = childId;
    _applyFilters();
  }

  void _applyFilters() {
    final childId = childFilter.value;
    final filtered = _allTickets.where((ticket) {
      return childId == null || childId.isEmpty
          ? true
          : ticket.childId == childId;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    tickets.assignAll(filtered);
  }

  void confirmPickup(PickupTicketModel ticket) {
    final updated = ticket.copyWith(
      parentConfirmedAt: DateTime.now(),
    );
    final index = _allTickets.indexWhere((item) => item.id == ticket.id);
    if (index != -1) {
      _allTickets[index] = updated;
      _applyFilters();
    }
  }
}
