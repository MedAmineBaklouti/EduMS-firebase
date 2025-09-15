import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/announcement_controller.dart';

class AnnouncementFormView extends StatelessWidget {
  AnnouncementFormView({super.key});

  final AnnouncementController controller = Get.find();

  @override
  Widget build(BuildContext context) {
    final isEditing = controller.editing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Announcement' : 'Add Announcement'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: controller.titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller.descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            Obx(() => CheckboxListTile(
                  value: controller.teachersSelected.value,
                  onChanged: (v) => controller.teachersSelected.value = v ?? false,
                  title: const Text('Teachers'),
                )),
            Obx(() => CheckboxListTile(
                  value: controller.parentsSelected.value,
                  onChanged: (v) => controller.parentsSelected.value = v ?? false,
                  title: const Text('Parents'),
                )),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: controller.saveAnnouncement,
              child: const Text('Save'),
            )
          ],
        ),
      ),
    );
  }
}
