import 'package:get/get.dart';

import '../../../core/services/database_service.dart';
import '../../../data/models/announcement_model.dart';

class AnnouncementController extends GetxController {
  final DatabaseService _db = Get.find();

  final RxList<AnnouncementModel> announcements = <AnnouncementModel>[].obs;
  final RxString audienceFilter = 'all'.obs;

  @override
  void onInit() {
    super.onInit();
    announcements.bindStream(_db.announcementStream());
  }

  List<AnnouncementModel> get filteredAnnouncements {
    if (audienceFilter.value == 'all') return announcements;
    return announcements
        .where((a) => a.audience == audienceFilter.value)
        .toList();
  }

  Future<void> addAnnouncement(AnnouncementModel announcement) async {
    await _db.addAnnouncement(announcement);
  }

  Future<void> deleteAnnouncement(String id) async {
    await _db.deleteAnnouncement(id);
  }
}
