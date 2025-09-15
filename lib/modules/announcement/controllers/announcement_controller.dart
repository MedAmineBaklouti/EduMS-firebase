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
    final audience = <String>[];
    if (teachersSelected.value) audience.add('teachers');
    if (parentsSelected.value) audience.add('parents');
    final announcement = AnnouncementModel(
      id: editing?.id ?? '',
      title: titleController.text,
      description: descriptionController.text,
      audience: audience,
      createdAt: editing?.createdAt ?? DateTime.now(),
    );
    if (editing == null) {
      await _db.addAnnouncement(announcement);
    } else {
      await _db.updateAnnouncement(announcement);
    }
    Get.back();
  }

  Future<void> deleteAnnouncement(String id) async {
    await _db.deleteAnnouncement(id);
  }

  void clearForm() {
    titleController.clear();
    descriptionController.clear();
    teachersSelected.value = true;
    parentsSelected.value = true;
  }
}
