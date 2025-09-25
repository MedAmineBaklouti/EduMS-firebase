import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/database_service.dart';
import '../../../data/models/pickup_model.dart';
import '../../../data/models/school_class_model.dart';

class AdminArchivedPickupController extends GetxController {
  final DatabaseService _db = Get.find();

  StreamSubscription? _classesSubscription;
  StreamSubscription? _ticketsSubscription;

  final RxList<PickupTicketModel> _allTickets = <PickupTicketModel>[].obs;
  final RxList<PickupTicketModel> tickets = <PickupTicketModel>[].obs;
  final RxList<SchoolClassModel> classes = <SchoolClassModel>[].obs;

  final RxnString classFilter = RxnString();
  final Rxn<DateTimeRange> dateFilter = Rxn<DateTimeRange>();
  final RxString searchQuery = ''.obs;
  final TextEditingController searchController = TextEditingController();
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_handleSearchInput);
    _initialize();
  }

  @override
  void onClose() {
    searchController.removeListener(_handleSearchInput);
    searchController.dispose();
    _classesSubscription?.cancel();
    _ticketsSubscription?.cancel();
    super.onClose();
  }

  void setClasses(List<SchoolClassModel> items) {
    classes.assignAll(
      List<SchoolClassModel>.from(items)
        ..sort((a, b) => a.name.compareTo(b.name)),
    );
    if (classFilter.value != null &&
        classes.every((element) => element.id != classFilter.value)) {
      classFilter.value = null;
    }
    _applyFilters();
  }

  void setTickets(List<PickupTicketModel> items) {
    _allTickets.assignAll(items.where((ticket) => ticket.isArchived).toList());
    _applyFilters();
  }

  void setClassFilter(String? classId) {
    classFilter.value = classId == null || classId.isEmpty ? null : classId;
    _applyFilters();
  }

  void setDateFilter(DateTimeRange? range) {
    dateFilter.value = range;
    _applyFilters();
  }

  void setSearchQuery(String value) {
    if (searchController.text != value) {
      searchController.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    } else {
      final normalized = value.trim();
      if (searchQuery.value != normalized) {
        searchQuery.value = normalized;
        _applyFilters();
      }
    }
  }

  void clearFilters() {
    classFilter.value = null;
    dateFilter.value = null;
    if (searchController.text.isNotEmpty) {
      searchController.clear();
    } else {
      if (searchQuery.value.isNotEmpty) {
        searchQuery.value = '';
      }
      _applyFilters();
    }
  }

  void clearSearchQuery() {
    if (searchController.text.isNotEmpty) {
      searchController.clear();
    } else if (searchQuery.value.isNotEmpty) {
      searchQuery.value = '';
      _applyFilters();
    }
  }

  String className(String id) {
    return classes.firstWhereOrNull((item) => item.id == id)?.name ?? 'Class';
  }

  Future<void> refreshTickets() async {
    try {
      isLoading.value = true;
      final classesSnapshot = await _db.firestore.collection('classes').get();
      final ticketsSnapshot =
          await _db.firestore.collection('pickupTickets').get();
      setClasses(classesSnapshot.docs.map(SchoolClassModel.fromDoc).toList());
      setTickets(ticketsSnapshot.docs.map(PickupTicketModel.fromDoc).toList());
    } catch (error) {
      Get.snackbar(
        'Refresh failed',
        'Unable to refresh archived pickups: $error',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _initialize() {
    isLoading.value = true;

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
      isLoading.value = false;
    });
  }

  void _applyFilters() {
    final classId = classFilter.value;
    final range = dateFilter.value;
    final query = searchQuery.value.toLowerCase();
    final filtered = _allTickets.where((ticket) {
      final matchesClass = classId == null || classId.isEmpty
          ? true
          : ticket.classId == classId;

      final archivedAt = ticket.archivedAt ?? ticket.adminValidatedAt;
      final matchesDate = () {
        if (range == null || archivedAt == null) {
          return true;
        }
        final start = DateTime(range.start.year, range.start.month, range.start.day);
        final end = DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59, 999);
        return !archivedAt.isBefore(start) && !archivedAt.isAfter(end);
      }();

      final matchesQuery = query.isEmpty
          ? true
          : ticket.childName.toLowerCase().contains(query) ||
              ticket.parentName.toLowerCase().contains(query);

      return matchesClass && matchesDate && matchesQuery;
    }).toList()
      ..sort((a, b) {
        final aDate = a.archivedAt ?? a.adminValidatedAt ?? a.createdAt;
        final bDate = b.archivedAt ?? b.adminValidatedAt ?? b.createdAt;
        return bDate.compareTo(aDate);
      });

    tickets.assignAll(filtered);
  }

  void _handleSearchInput() {
    final normalized = searchController.text.trim();
    if (searchQuery.value == normalized) {
      return;
    }
    searchQuery.value = normalized;
    _applyFilters();
  }
}
