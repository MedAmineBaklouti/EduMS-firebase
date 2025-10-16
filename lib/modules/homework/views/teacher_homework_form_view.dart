import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../common/models/school_class_model.dart';
import '../controllers/teacher_homework_controller.dart';

class TeacherHomeworkFormView extends GetView<TeacherHomeworkController> {
  const TeacherHomeworkFormView({super.key});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMMd();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        title: Text(
          controller.editing == null
              ? 'homework_form_title_add'.tr
              : 'homework_form_title_edit'.tr,
        ),
      ),
      body: Obx(() {
        final classes = controller.classes;
        final selectedClass = controller.selectedClass.value;
        final dueDate = controller.dueDate.value;
        final isSaving = controller.isSaving.value;
        final isEditing = controller.editing != null;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: controller.titleController,
                decoration: InputDecoration(
                  labelText: 'homework_form_field_title'.tr,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.descriptionController,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: 'homework_form_field_description'.tr,
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<SchoolClassModel?>(
                value: selectedClass,
                decoration: InputDecoration(
                  labelText: 'homework_form_field_class'.tr,
                  border: const OutlineInputBorder(),
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
                      ? 'homework_form_select_due_date'.tr
                      : 'homework_form_due_date'
                          .trParams({'date': dateFormat.format(dueDate)}),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final success = await controller.saveHomework();
                          if (success) {
                            Get.back();
                          }
                        },
                  icon: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          isEditing ? Icons.save_outlined : Icons.send_rounded,
                          color: Colors.white,
                        ),
                  label: Text(
                    isSaving
                        ? 'homework_form_action_saving'.tr
                        : 'homework_form_action_save'.tr,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
