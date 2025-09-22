import 'package:collection/collection.dart';
import 'package:get/get.dart';

import '../../../data/models/attendance_record_model.dart';
import '../../../data/models/child_model.dart';

class ParentAttendanceController extends GetxController {
  final RxList<AttendanceSessionModel> _allSessions =
      <AttendanceSessionModel>[].obs;
  final RxList<AttendanceSessionModel> sessions =
      <AttendanceSessionModel>[].obs;
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

  void setSessions(List<AttendanceSessionModel> items) {
    _allSessions.assignAll(items);
    _applyFilters();
  }

  void setChildFilter(String? childId) {
    childFilter.value = childId;
    _applyFilters();
  }

  void _applyFilters() {
    final childId = childFilter.value;
    if (childId == null || childId.isEmpty) {
      sessions.assignAll(
        _allSessions.toList()..sort((a, b) => b.date.compareTo(a.date)),
      );
      return;
    }
    final filtered = _allSessions.where((session) {
      return session.records.any((entry) => entry.childId == childId);
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    sessions.assignAll(filtered);
  }

  ChildAttendanceEntry? entryFor(AttendanceSessionModel session, String childId) {
    return session.records
        .firstWhereOrNull((entry) => entry.childId == childId);
  }
}
