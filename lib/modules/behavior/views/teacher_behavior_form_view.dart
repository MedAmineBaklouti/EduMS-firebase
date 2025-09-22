import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/behavior_model.dart';
import '../../../data/models/child_model.dart';
import '../../../data/models/school_class_model.dart';
import '../controllers/teacher_behavior_controller.dart';

class TeacherBehaviorFormView extends GetView<TeacherBehaviorController> {
  const TeacherBehaviorFormView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(controller.editing == null
            ? 'Add Behavior'
            : 'Edit Behavior'),
      ),
      body: Obx(() {
        final classes = controller.classes;
        final availableChildren = controller.availableChildren;
        final selectedClass = controller.selectedClass.value;
        final selectedChild = controller.selectedChild.value;
        final behaviorType = controller.selectedBehaviorType.value;
        final isSaving = controller.isSaving.value;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    controller.selectClass(value);
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ChildModel?>(
                value: selectedChild,
                decoration: const InputDecoration(
                  labelText: 'Child',
                  border: OutlineInputBorder(),
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
                decoration: const InputDecoration(
                  labelText: 'Behavior type',
                  border: OutlineInputBorder(),
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
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
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
                              final success = await controller.saveBehavior();
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
