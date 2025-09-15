import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/announcement_controller.dart';
import '../../../data/models/announcement_model.dart';
import 'announcement_detail_view.dart';

class AnnouncementListView extends StatelessWidget {
  final bool isAdmin;
  final String? audience;

  AnnouncementListView({this.isAdmin = false, this.audience});

  @override
  Widget build(BuildContext context) {
    final controller =
        Get.put(AnnouncementController(audienceFilter: audience));
    return Scaffold(
      appBar: AppBar(title: const Text('Announcements')),
      body: Obx(() {
        if (controller.announcements.isEmpty) {
          return const Center(child: Text('No announcements'));
        }
        return ListView.builder(
          itemCount: controller.announcements.length,
          itemBuilder: (context, index) {
            final ann = controller.announcements[index];
            return isAdmin
                ? _buildAdminItem(controller, ann)
                : _buildItem(ann);
          },
        );
      }),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () => controller.openForm(),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildItem(AnnouncementModel ann) {
    return ListTile(
      title: Text(ann.title),
      subtitle: Text(ann.description),
      onTap: () => Get.to(() => AnnouncementDetailView(announcement: ann)),
    );
  }

  Widget _buildAdminItem(
      AnnouncementController controller, AnnouncementModel ann) {
    return Dismissible(
      key: Key(ann.id),
      background: Container(
        color: Colors.blue,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          controller.openForm(announcement: ann);
          return false;
        } else if (direction == DismissDirection.endToStart) {
          await controller.deleteAnnouncement(ann.id);
          return true;
        }
        return false;
      },
      child: _buildItem(ann),
    );
  }
}
