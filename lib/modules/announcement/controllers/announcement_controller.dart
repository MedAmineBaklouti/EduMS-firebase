import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
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
        'announcement_snackbar_select_title'.tr,
        'announcement_snackbar_select_message'.tr,
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
        isEditingExisting
            ? 'announcement_snackbar_update_title'.tr
            : 'announcement_snackbar_publish_title'.tr,
        isEditingExisting
            ? 'announcement_snackbar_update_message'.tr
            : 'announcement_snackbar_publish_message'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'announcement_snackbar_error_title'.tr,
        'announcement_snackbar_save_error'.trParams({'error': e.toString()}),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> deleteAnnouncement(String id) async {
    await _db.deleteAnnouncement(id);
  }

  Future<void> refreshAnnouncements() async {
    Query query = _db.firestore.collection('announcements');
    if (audienceFilter != null) {
      query = query.where('audience', arrayContains: audienceFilter);
    }
    final snapshot = await query.get();
    final now = DateTime.now();
    final refreshed = <AnnouncementModel>[];

    for (final doc in snapshot.docs) {
      final announcement = AnnouncementModel.fromDoc(doc);
      if (now.difference(announcement.createdAt).inDays >= 7) {
        await deleteAnnouncement(announcement.id);
      } else {
        refreshed.add(announcement);
      }
    }

    refreshed.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    announcements.assignAll(refreshed);
  }

  void clearForm() {
    titleController.clear();
    descriptionController.clear();
    teachersSelected.value = true;
    parentsSelected.value = true;
    formKey.currentState?.reset();
  }
}
