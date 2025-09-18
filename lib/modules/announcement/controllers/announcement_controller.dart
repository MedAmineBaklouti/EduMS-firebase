import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_pages.dart';
import '../../../core/services/database_service.dart';
import '../../../data/models/announcement_model.dart';
import '../views/announcement_form_view.dart';

class AnnouncementController extends GetxController {
  final DatabaseService _db = Get.find();

  final String? audienceFilter;
  final bool isAdminView;

  AnnouncementController({this.audienceFilter, this.isAdminView = false});

  final RxList<AnnouncementModel> announcements = <AnnouncementModel>[].obs;

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final RxBool teachersSelected = true.obs;
  final RxBool parentsSelected = true.obs;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final RxBool isSaving = false.obs;

  AnnouncementModel? editing;
  StreamSubscription? _subscription;

  @override
  void onInit() {
    super.onInit();
    _subscription = _db
        .streamAnnouncements(audience: audienceFilter)
        .listen((data) {
      final now = DateTime.now();
      final valid = <AnnouncementModel>[];
      for (final ann in data) {
        if (now.difference(ann.createdAt).inDays >= 7) {
          deleteAnnouncement(ann.id);
        } else {
          valid.add(ann);
        }
      }
      announcements.value = valid;
    });
  }

  @override
  void onClose() {
    _subscription?.cancel();
    titleController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  void openForm({AnnouncementModel? announcement}) {
    if (announcement != null) {
      editing = announcement;
      titleController.text = announcement.title;
      descriptionController.text = announcement.description;
      teachersSelected.value = announcement.audience.contains('teachers');
      parentsSelected.value = announcement.audience.contains('parents');
    } else {
      editing = null;
      clearForm();
    }
    Get.to(() => AnnouncementFormView());
  }

  Future<void> saveAnnouncement() async {
    if (formKey.currentState?.validate() != true) {
      return;
    }
    if (!teachersSelected.value && !parentsSelected.value) {
      Get.snackbar(
        'Select audience',
        'Choose at least one audience for this announcement.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isSaving.value = true;
      final audience = <String>[];
      if (teachersSelected.value) audience.add('teachers');
      if (parentsSelected.value) audience.add('parents');
      var announcement = AnnouncementModel(
        id: editing?.id ?? '',
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        audience: audience,
        createdAt: editing?.createdAt ?? DateTime.now(),
      );
      if (editing == null) {
        final newId = await _db.addAnnouncement(announcement);
        announcement = announcement.copyWith(id: newId);
        Get.snackbar(
          'Announcement published',
          'Your announcement is now visible to the selected audience.',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        await _db.updateAnnouncement(announcement);
        Get.snackbar(
          'Announcement updated',
          'Changes have been saved successfully.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      editing = null;
      clearForm();
      _navigateToListView();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save the announcement. ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> deleteAnnouncement(String id) async {
    await _db.deleteAnnouncement(id);
  }

  void clearForm() {
    titleController.clear();
    descriptionController.clear();
    teachersSelected.value = true;
    parentsSelected.value = true;
    formKey.currentState?.reset();
  }

  void _navigateToListView() {
    final targetRoute = _resolveListRoute();
    if (targetRoute == null) {
      if (Get.key.currentState?.canPop() ?? false) {
        Get.back();
      }
      return;
    }

    if (Get.currentRoute == targetRoute) {
      return;
    }

    Get.until((route) => route.settings.name == targetRoute);
    if (Get.currentRoute != targetRoute) {
      Get.offAllNamed(targetRoute);
    }
  }

  String? _resolveListRoute() {
    if (isAdminView) {
      return AppPages.ADMIN_ANNOUNCEMENTS;
    }
    if (audienceFilter == 'teachers') {
      return AppPages.TEACHER_ANNOUNCEMENTS;
    }
    if (audienceFilter == 'parents') {
      return AppPages.PARENT_ANNOUNCEMENTS;
    }
    return null;
  }
}
