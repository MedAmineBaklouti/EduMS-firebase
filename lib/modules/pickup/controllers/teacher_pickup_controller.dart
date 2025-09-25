import 'dart:async';

import 'package:collection/collection.dart';
import 'package:get/get.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/database_service.dart';
import '../../../data/models/pickup_model.dart';
import '../../../data/models/school_class_model.dart';
import '../../../data/models/teacher_model.dart';

class TeacherPickupController extends GetxController {
  final DatabaseService _db = Get.find();
  final AuthService _auth = Get.find();

  StreamSubscription? _teacherSubscription;
  StreamSubscription? _classesSubscription;
  StreamSubscription? _ticketsSubscription;

  bool _teacherLoaded = false;
  bool _classesLoaded = false;
  bool _ticketsLoaded = false;

  final RxList<PickupTicketModel> _allTickets = <PickupTicketModel>[].obs;
  final RxList<PickupTicketModel> tickets = <PickupTicketModel>[].obs;
  final RxList<SchoolClassModel> classes = <SchoolClassModel>[].obs;

  final RxnString classFilter = RxnString();
  final Rxn<TeacherModel> teacher = Rxn<TeacherModel>();
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  @override
  void onClose() {
    _teacherSubscription?.cancel();
    _classesSubscription?.cancel();
    _ticketsSubscription?.cancel();
    super.onClose();
  }

  void setTeacher(TeacherModel value) {
    teacher.value = value;
  }

  void setClasses(List<SchoolClassModel> items) {
    classes.assignAll(
      List<SchoolClassModel>.from(items)
        ..sort((a, b) => a.name.compareTo(b.name)),
    );
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
    classFilter.value = classId == null || classId.isEmpty ? null : classId;
    _applyFilters();
  }

  void clearFilters() {
    classFilter.value = null;
    _applyFilters();
  }

  String className(String id) {
    return classes.firstWhereOrNull((item) => item.id == id)?.name ?? 'Class';
  }

  void _applyFilters() {
    final teacherClassIds = classes.map((item) => item.id).toSet();
    if (teacherClassIds.isEmpty) {
      tickets.clear();
      return;
    }
    final classId = classFilter.value;
    final filtered = _allTickets.where((ticket) {
      if (ticket.isArchived) {
        return false;
      }
      if (!teacherClassIds.contains(ticket.classId)) {
        return false;
      }
      if (ticket.stage != PickupStage.awaitingTeacher) {
        return false;
      }
      if (classId != null && classId.isNotEmpty && ticket.classId != classId) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) {
        final aTime = _ticketSortTime(a);
        final bTime = _ticketSortTime(b);
        return bTime.compareTo(aTime);
      });
    tickets.assignAll(filtered);
  }

  DateTime _ticketSortTime(PickupTicketModel ticket) {
    return ticket.parentConfirmedAt ?? ticket.createdAt;
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
    final now = DateTime.now();
    final updated = ticket.copyWith(
      teacherValidatorId: currentTeacher.id,
      teacherValidatorName: currentTeacher.name,
      teacherValidatedAt: now,
      archivedAt: now,
    );
    final index = _allTickets.indexWhere((item) => item.id == ticket.id);
    if (index != -1) {
      _allTickets[index] = updated;
      _applyFilters();
    }
    _db.firestore
        .collection('pickupTickets')
        .doc(ticket.id)
        .update(updated.toMap());
  }

  Future<void> _initialize() async {
    try {
      final teacherId = _auth.currentUser?.uid;
      if (teacherId == null) {
        Get.snackbar(
          'Authentication required',
          'Unable to determine the authenticated teacher.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      isLoading.value = true;

      _teacherSubscription = _db.firestore
          .collection('teachers')
          .doc(teacherId)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          setTeacher(TeacherModel.fromDoc(snapshot));
        }
        _teacherLoaded = true;
        _maybeFinishLoading();
      });

      _classesSubscription = _db.firestore
          .collection('classes')
          .snapshots()
          .listen((snapshot) {
        final teacherClasses = snapshot.docs
            .map(SchoolClassModel.fromDoc)
            .where((item) => item.teacherSubjects.values.contains(teacherId))
            .toList();
        setClasses(teacherClasses);
        _classesLoaded = true;
        _maybeFinishLoading();
      });

      _ticketsSubscription = _db.firestore
          .collection('pickupTickets')
          .snapshots()
          .listen((snapshot) {
        setTickets(snapshot.docs.map(PickupTicketModel.fromDoc).toList());
        _ticketsLoaded = true;
        _maybeFinishLoading();
      });
    } catch (error) {
      isLoading.value = false;
      Get.snackbar(
        'Load failed',
        'Unable to load pickup data: $error',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _maybeFinishLoading() {
    if (_teacherLoaded && _classesLoaded && _ticketsLoaded) {
      isLoading.value = false;
    }
  }

  Future<void> refreshTickets() async {
    final teacherId = _auth.currentUser?.uid;
    if (teacherId == null) {
      return;
    }
    try {
      isLoading.value = true;
      final classesSnapshot = await _db.firestore.collection('classes').get();
      final ticketsSnapshot =
          await _db.firestore.collection('pickupTickets').get();
      final teacherClasses = classesSnapshot.docs
          .map(SchoolClassModel.fromDoc)
          .where((item) => item.teacherSubjects.values.contains(teacherId))
          .toList();
      setClasses(teacherClasses);
      setTickets(ticketsSnapshot.docs.map(PickupTicketModel.fromDoc).toList());
    } catch (error) {
      Get.snackbar(
        'Refresh failed',
        'Unable to refresh pickup data: $error',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
