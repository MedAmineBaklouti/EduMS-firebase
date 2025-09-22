import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../data/models/school_class_model.dart';
import '../controllers/teacher_homework_controller.dart';

class TeacherHomeworkFormView extends GetView<TeacherHomeworkController> {
  const TeacherHomeworkFormView({super.key});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMMd();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          controller.editing == null ? 'Add Homework' : 'Edit Homework',
        ),
      ),
      body: Obx(() {
        final classes = controller.classes;
        final selectedClass = controller.selectedClass.value;
        final dueDate = controller.dueDate.value;
        final isSaving = controller.isSaving.value;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: controller.titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.descriptionController,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<SchoolClassModel?>(
                value: selectedClass,
                decoration: const InputDecoration(
                  labelText: 'Class',
                  border: OutlineInputBorder(),
                ),
                items: classes
                    .map(
                      (item) => DropdownMenuItem<SchoolClassModel?>(
                        value: item,
                        child: Text(item.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    controller.selectedClass.value = value;
                  }
                },
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: isSaving
                    ? null
                    : () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: dueDate ?? now,
                          firstDate: now,
                          lastDate: DateTime(now.year + 5),
                        );
                        if (picked != null) {
                          controller.dueDate.value = picked;
                        }
                      },
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  dueDate == null
                      ? 'Select due date'
                      : 'Due ${dateFormat.format(dueDate)}',
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: isSaving
                        ? null
                        : () {
                            Get.back();
                          },
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isSaving
                          ? null
                          : () async {
                              final success = await controller.saveHomework();
                              if (success) {
                                Get.back();
                              }
                            },
                      icon: const Icon(Icons.save),
                      label: Text(isSaving ? 'Saving...' : 'Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }
}
