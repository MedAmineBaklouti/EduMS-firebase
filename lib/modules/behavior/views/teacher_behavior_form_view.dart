import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/behavior_model.dart';
import '../../../common/models/child_model.dart';
import '../../../common/models/school_class_model.dart';
import '../controllers/teacher_behavior_controller.dart';

class TeacherBehaviorFormView extends GetView<TeacherBehaviorController> {
  const TeacherBehaviorFormView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        title: Text(controller.editing == null
            ? 'behavior_form_title_add'.tr
            : 'behavior_form_title_edit'.tr),
      ),
      body: Obx(() {
        final classes = controller.classes;
        final availableChildren = controller.availableChildren;
        final selectedClass = controller.selectedClass.value;
        final selectedChild = controller.selectedChild.value;
        final behaviorType = controller.selectedBehaviorType.value;
        final isSaving = controller.isSaving.value;
        final isEditing = controller.editing != null;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (classes.isEmpty)
                _InfoBanner(
                  icon: Icons.info_outline,
                  message: 'behavior_form_info_no_classes'.tr,
                ),
              if (classes.isNotEmpty) const SizedBox(height: 8),
              DropdownButtonFormField<SchoolClassModel?>(
                value: selectedClass,
                decoration: InputDecoration(
                  labelText: 'behavior_form_field_class'.tr,
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
                    controller.selectClass(value);
                  }
                },
              ),
              const SizedBox(height: 16),
              if (selectedClass != null && availableChildren.isEmpty)
                _InfoBanner(
                  icon: Icons.groups_2_outlined,
                  message: 'behavior_form_info_no_students'.tr,
                ),
              if (selectedClass != null && availableChildren.isEmpty)
                const SizedBox(height: 16),
              DropdownButtonFormField<ChildModel?>(
                value: selectedChild,
                decoration: InputDecoration(
                  labelText: 'behavior_form_field_child'.tr,
                  border: const OutlineInputBorder(),
                ),
                items: availableChildren
                    .map(
                      (item) => DropdownMenuItem<ChildModel?>(
                        value: item,
                        child: Text(item.name),
                      ),
                    )
                    .toList(),
                onChanged: selectedClass == null
                    ? null
                    : (value) {
                        if (value != null) {
                          controller.selectChild(value);
                        }
                      },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<BehaviorType>(
                value: behaviorType,
                decoration: InputDecoration(
                  labelText: 'behavior_form_field_type'.tr,
                  border: const OutlineInputBorder(),
                ),
                items: BehaviorType.values
                    .map(
                      (type) => DropdownMenuItem<BehaviorType>(
                        value: type,
                        child: Text(type.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    controller.selectedBehaviorType.value = value;
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.descriptionController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'behavior_form_field_description'.tr,
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isSaving || selectedClass == null || selectedChild == null
                      ? null
                      : () async {
                          final success = await controller.saveBehavior();
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
                    isSaving ? 'common_saving'.tr : 'common_save'.tr,
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

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
