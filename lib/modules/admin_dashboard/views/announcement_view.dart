import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/announcement_controller.dart';
import '../../../data/models/announcement_model.dart';

class AnnouncementView extends StatelessWidget {
  final AnnouncementController c = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
        actions: [
          Obx(() => DropdownButton<String>(
                value: c.audienceFilter.value,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All')),
                  DropdownMenuItem(value: 'parents', child: Text('Parents')),
                  DropdownMenuItem(value: 'teachers', child: Text('Teachers')),
                  DropdownMenuItem(value: 'both', child: Text('Both')),
                ],
                onChanged: (v) {
                  if (v != null) c.audienceFilter.value = v;
                },
              ))
        ],
      ),
      body: Obx(() {
        final list = c.filteredAnnouncements;
        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (context, index) {
            final ann = list[index];
            return Dismissible(
              key: ValueKey(ann.id),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (_) async {
                return await showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete'),
                    content: const Text('Are you sure?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('No')),
                      TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Yes')),
                    ],
                  ),
                );
              },
              onDismissed: (_) => c.deleteAnnouncement(ann.id),
              child: ListTile(
                title: Text(ann.title),
                subtitle: Text(ann.body),
                trailing: Text(ann.audience),
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog() {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    String audience = 'parents';
    Get.dialog(StatefulBuilder(builder: (context, setState) {
      return AlertDialog(
        title: const Text('New Announcement'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
              TextField(controller: bodyCtrl, decoration: const InputDecoration(labelText: 'Body')),
              DropdownButton<String>(
                value: audience,
                items: const [
                  DropdownMenuItem(value: 'parents', child: Text('Parents')),
                  DropdownMenuItem(value: 'teachers', child: Text('Teachers')),
                  DropdownMenuItem(value: 'both', child: Text('Both')),
                ],
                onChanged: (v) => setState(() => audience = v ?? 'parents'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          TextButton(
              onPressed: () {
                final now = DateTime.now();
                final model = AnnouncementModel(
                  id: '',
                  title: titleCtrl.text,
                  body: bodyCtrl.text,
                  audience: audience,
                  createdAt: now,
                  expireAt: now.add(const Duration(days: 7)),
                );
                c.addAnnouncement(model);
                Get.back();
              },
              child: const Text('Save')),
        ],
      );
    }));
  }
}
