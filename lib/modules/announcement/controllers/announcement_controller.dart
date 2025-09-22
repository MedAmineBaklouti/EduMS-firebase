import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/database_service.dart';
import '../../../data/models/announcement_model.dart';
import '../views/announcement_form_view.dart';

class AnnouncementController extends GetxController {
  final DatabaseService _db = Get.find();

  final String? audienceFilter;

  AnnouncementController({this.audienceFilter});

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
      valid.sort((a, b) => b.createdAt.compareTo(a.createdAt));
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
      final announcement = AnnouncementModel(
        id: editing?.id ?? '',
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        audience: audience,
        createdAt: editing?.createdAt ?? DateTime.now(),
      );
      final isEditingExisting = editing != null;

      if (isEditingExisting) {
        await _db.updateAnnouncement(announcement);
      } else {
        await _db.addAnnouncement(announcement);
      }

      clearForm();
      editing = null;

      Get.back();
      Get.snackbar(
        isEditingExisting ? 'Announcement updated' : 'Announcement published',
        isEditingExisting
            ? 'Changes have been saved successfully.'
            : 'Your announcement is now visible to the selected audience.',
        snackPosition: SnackPosition.BOTTOM,
      );
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
}
