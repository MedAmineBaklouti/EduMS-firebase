import 'package:get/get.dart';

import '../../../data/models/admin_model.dart';
import '../../../data/models/pickup_model.dart';
import '../../../data/models/school_class_model.dart';

class AdminPickupController extends GetxController {
  final RxList<PickupTicketModel> _allTickets = <PickupTicketModel>[].obs;
  final RxList<PickupTicketModel> tickets = <PickupTicketModel>[].obs;
  final RxList<SchoolClassModel> classes = <SchoolClassModel>[].obs;

  final RxnString classFilter = RxnString();
  final Rxn<PickupStage> stageFilter = Rxn<PickupStage>();
  final Rxn<AdminModel> admin = Rxn<AdminModel>();
  final RxBool isLoading = false.obs;

  void setAdmin(AdminModel value) {
    admin.value = value;
  }

  void setClasses(List<SchoolClassModel> items) {
    classes.assignAll(items);
    if (classFilter.value != null &&
        !classes.any((element) => element.id == classFilter.value)) {
      classFilter.value = null;
    }
    _applyFilters();
  }

  void setTickets(List<PickupTicketModel> items) {
    _allTickets.assignAll(items);
    _applyFilters();
  }

  void setClassFilter(String? classId) {
    classFilter.value = classId;
    _applyFilters();
  }

  void setStageFilter(PickupStage? stage) {
    stageFilter.value = stage;
    _applyFilters();
  }

  void _applyFilters() {
    final classId = classFilter.value;
    final stage = stageFilter.value;
    final filtered = _allTickets.where((ticket) {
      final matchesClass = classId == null || classId.isEmpty
          ? true
          : ticket.classId == classId;
      final matchesStage = stage == null ? true : ticket.stage == stage;
      return matchesClass && matchesStage;
    }).toList()
      ..sort((a, b) => a.stage.index.compareTo(b.stage.index));
    tickets.assignAll(filtered);
  }

  void finalizeTicket(PickupTicketModel ticket) {
    final adminUser = admin.value;
    if (adminUser == null) {
      Get.snackbar(
        'Missing profile',
        'Unable to determine the administrator user.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    final updated = ticket.copyWith(
      adminValidatorId: adminUser.id,
      adminValidatorName: adminUser.name,
      adminValidatedAt: DateTime.now(),
    );
    final index = _allTickets.indexWhere((item) => item.id == ticket.id);
    if (index != -1) {
      _allTickets[index] = updated;
      _applyFilters();
    }
  }
}
