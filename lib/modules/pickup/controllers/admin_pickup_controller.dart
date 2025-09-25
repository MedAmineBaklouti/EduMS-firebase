import 'dart:async';

import 'package:collection/collection.dart';
import 'package:get/get.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/database_service.dart';
import '../../../data/models/admin_model.dart';
import '../../../data/models/pickup_model.dart';
import '../../../data/models/school_class_model.dart';

class AdminPickupController extends GetxController {
  final DatabaseService _db = Get.find();
  final AuthService _auth = Get.find();

  StreamSubscription? _adminSubscription;
  StreamSubscription? _classesSubscription;
  StreamSubscription? _ticketsSubscription;

  bool _adminLoaded = false;
  bool _classesLoaded = false;
  bool _ticketsLoaded = false;

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  @override
  void onClose() {
    _adminSubscription?.cancel();
    _classesSubscription?.cancel();
    _ticketsSubscription?.cancel();
    super.onClose();
  }

  final RxList<PickupTicketModel> _allTickets = <PickupTicketModel>[].obs;
  final RxList<PickupTicketModel> tickets = <PickupTicketModel>[].obs;
  final RxList<SchoolClassModel> classes = <SchoolClassModel>[].obs;

  final RxnString classFilter = RxnString();
  final Rxn<PickupStage> stageFilter = Rxn<PickupStage>();
  final Rxn<AdminModel> admin = Rxn<AdminModel>();
  final RxBool isLoading = false.obs;

  void clearFilters() {
    classFilter.value = null;
    stageFilter.value = null;
    _applyFilters();
  }

  String className(String id) {
    return classes.firstWhereOrNull((item) => item.id == id)?.name ?? 'Class';
  }

  void setAdmin(AdminModel value) {
    admin.value = value;
    _adminLoaded = true;
    _maybeFinishLoading();
  }

  void setClasses(List<SchoolClassModel> items) {
    classes.assignAll(items);
    if (classFilter.value != null &&
        !classes.any((element) => element.id == classFilter.value)) {
      classFilter.value = null;
    }
    _applyFilters();
    _classesLoaded = true;
    _maybeFinishLoading();
  }

  void setTickets(List<PickupTicketModel> items) {
    _allTickets.assignAll(items);
    _applyFilters();
    _ticketsLoaded = true;
    _maybeFinishLoading();
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
      if (ticket.isArchived) {
        return false;
      }
      final matchesClass = classId == null || classId.isEmpty
          ? true
          : ticket.classId == classId;
      final matchesStage = stage == null ? true : ticket.stage == stage;
      return matchesClass && matchesStage;
    }).toList()
      ..sort((a, b) => a.stage.index.compareTo(b.stage.index));
    tickets.assignAll(filtered);
  }

  Future<void> finalizeTicket(PickupTicketModel ticket) async {
    final adminUser = admin.value;
    if (adminUser == null) {
      Get.snackbar(
        'Missing profile',
        'Unable to determine the administrator user.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    final now = DateTime.now();
    final updated = ticket.copyWith(
      adminValidatorId: adminUser.id,
      adminValidatorName: adminUser.name,
      adminValidatedAt: now,
      archivedAt: now,
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

  Future<void> refreshTickets() async {
    final adminId = _auth.currentUser?.uid;
    if (adminId == null) {
      return;
    }
    try {
      isLoading.value = true;
      final adminSnapshot =
          await _db.firestore.collection('admins').doc(adminId).get();
      final classesSnapshot =
          await _db.firestore.collection('classes').get();
      final ticketsSnapshot =
          await _db.firestore.collection('pickupTickets').get();
      if (adminSnapshot.exists) {
        setAdmin(AdminModel.fromFirestore(adminSnapshot));
      }
      setClasses(classesSnapshot.docs.map(SchoolClassModel.fromDoc).toList());
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

  void _initialize() {
    final adminId = _auth.currentUser?.uid;
    if (adminId == null) {
      Get.snackbar(
        'Authentication required',
        'Unable to determine the authenticated administrator.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isLoading.value = true;

    _adminSubscription = _db.firestore
        .collection('admins')
        .doc(adminId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        setAdmin(AdminModel.fromFirestore(snapshot));
      }
    });

    _classesSubscription = _db.firestore
        .collection('classes')
        .snapshots()
        .listen((snapshot) {
      setClasses(snapshot.docs.map(SchoolClassModel.fromDoc).toList());
    });

    _ticketsSubscription = _db.firestore
        .collection('pickupTickets')
        .snapshots()
        .listen((snapshot) {
      setTickets(snapshot.docs.map(PickupTicketModel.fromDoc).toList());
    });
  }

  void _maybeFinishLoading() {
    if (_adminLoaded && _classesLoaded && _ticketsLoaded) {
      isLoading.value = false;
    }
  }
}
