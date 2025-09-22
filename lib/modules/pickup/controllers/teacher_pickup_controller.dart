import 'package:collection/collection.dart';
import 'package:get/get.dart';

import '../../../data/models/pickup_model.dart';
import '../../../data/models/school_class_model.dart';
import '../../../data/models/teacher_model.dart';

class TeacherPickupController extends GetxController {
  final RxList<PickupTicketModel> _allTickets = <PickupTicketModel>[].obs;
  final RxList<PickupTicketModel> tickets = <PickupTicketModel>[].obs;
  final RxList<SchoolClassModel> classes = <SchoolClassModel>[].obs;

  final RxnString classFilter = RxnString();
  final Rxn<TeacherModel> teacher = Rxn<TeacherModel>();
  final RxBool isLoading = false.obs;

  void setTeacher(TeacherModel value) {
    teacher.value = value;
  }

  void setClasses(List<SchoolClassModel> items) {
    classes.assignAll(items);
    if (classFilter.value != null &&
        classes.firstWhereOrNull((item) => item.id == classFilter.value) ==
            null) {
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

  void _applyFilters() {
    final classId = classFilter.value;
    final filtered = _allTickets.where((ticket) {
      final matchesClass = classId == null || classId.isEmpty
          ? true
          : ticket.classId == classId;
      final requiresTeacher =
          ticket.stage == PickupStage.awaitingTeacher ||
              ticket.stage == PickupStage.awaitingAdmin ||
              ticket.stage == PickupStage.completed;
      return matchesClass && requiresTeacher;
    }).toList()
      ..sort((a, b) => a.stage.index.compareTo(b.stage.index));
    tickets.assignAll(filtered);
  }

  void validatePickup(PickupTicketModel ticket) {
    final currentTeacher = teacher.value;
    if (currentTeacher == null) {
      Get.snackbar(
        'Missing profile',
        'Unable to determine the authenticated teacher.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    final updated = ticket.copyWith(
      teacherValidatorId: currentTeacher.id,
      teacherValidatorName: currentTeacher.name,
      teacherValidatedAt: DateTime.now(),
    );
    final index = _allTickets.indexWhere((item) => item.id == ticket.id);
    if (index != -1) {
      _allTickets[index] = updated;
      _applyFilters();
    }
  }
}
