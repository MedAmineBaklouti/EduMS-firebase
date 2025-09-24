import 'dart:async';

import 'package:collection/collection.dart';
import 'package:get/get.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/database_service.dart';
import '../../../data/models/attendance_record_model.dart';
import '../../../data/models/child_model.dart';

class ParentAttendanceController extends GetxController {
  final DatabaseService _db = Get.find();
  final AuthService _auth = Get.find();

  StreamSubscription? _childrenSubscription;
  StreamSubscription? _sessionsSubscription;

  bool _childrenLoaded = false;
  bool _sessionsLoaded = false;

  final Set<String> _childIds = <String>{};

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  @override
  void onClose() {
    _childrenSubscription?.cancel();
    _sessionsSubscription?.cancel();
    super.onClose();
  }

  final RxList<AttendanceSessionModel> _allSessions =
      <AttendanceSessionModel>[].obs;
  final RxList<AttendanceSessionModel> sessions =
      <AttendanceSessionModel>[].obs;
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

  void setSessions(List<AttendanceSessionModel> items) {
    _allSessions.assignAll(items);
    _applyFilters();
    _sessionsLoaded = true;
    _maybeFinishLoading();
  }

  void setChildFilter(String? childId) {
    childFilter.value = childId;
    _applyFilters();
  }

  void _applyFilters() {
    final childId = childFilter.value;
    if (_childIds.isEmpty) {
      sessions.clear();
      return;
    }
    final relevantSessions = _allSessions.where((session) {
      return session.records
          .any((entry) => _childIds.contains(entry.childId));
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (childId == null || childId.isEmpty) {
      sessions.assignAll(relevantSessions);
      return;
    }

    final filtered = relevantSessions
        .where((session) =>
            session.records.any((entry) => entry.childId == childId))
        .toList();
    sessions.assignAll(filtered);
  }

  ChildAttendanceEntry? entryFor(AttendanceSessionModel session, String childId) {
    return session.records
        .firstWhereOrNull((entry) => entry.childId == childId);
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

    _sessionsSubscription = _db.firestore
        .collection('attendanceSessions')
        .snapshots()
        .listen((snapshot) {
      setSessions(snapshot.docs.map(AttendanceSessionModel.fromDoc).toList());
    });
  }

  void _maybeFinishLoading() {
    if (_childrenLoaded && _sessionsLoaded) {
      isLoading.value = false;
    }
  }
}
