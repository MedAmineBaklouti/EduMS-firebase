import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/behavior_model.dart';
import '../controllers/teacher_behavior_controller.dart';
import 'teacher_behavior_form_view.dart';

class TeacherBehaviorListView extends GetView<TeacherBehaviorController> {
  const TeacherBehaviorListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Behaviors'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          controller.startCreate();
          Get.to(() => const TeacherBehaviorFormView());
        },
        child: const Icon(Icons.add),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: [
            _TeacherBehaviorFilters(controller: controller),
            Expanded(
              child: Obx(() {
                final items = controller.behaviors;
                if (items.isEmpty) {
                  return const Center(
                    child: Text('No behaviors have been recorded yet.'),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final behavior = items[index];
                    return Dismissible(
                      key: ValueKey(behavior.id),
                      background: Container(
                        color: Colors.blue,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: const Icon(Icons.edit, color: Colors.white),
                      ),
                      secondaryBackground: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          controller.startEdit(behavior);
                          await Get.to(() => const TeacherBehaviorFormView());
                          return false;
                        }
                        return _confirmDelete(context);
                      },
                      onDismissed: (direction) {
                        controller.removeBehavior(behavior);
                      },
                      child: ListTile(
                        title: Text(behavior.childName),
                        subtitle: Text(
                          '${behavior.className} • ${behavior.teacherName}\n${behavior.description}',
                        ),
                        isThreeLine: true,
                        trailing: Text(
                          behavior.type.label,
                          style: TextStyle(
                            color: behavior.type == BehaviorType.positive
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () {
                          controller.startEdit(behavior);
                          Get.to(() => const TeacherBehaviorFormView());
                        },
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        );
      }),
    );
  }
}

class _TeacherBehaviorFilters extends StatelessWidget {
  const _TeacherBehaviorFilters({required this.controller});

  final TeacherBehaviorController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Obx(() {
        final classes = controller.classes;
        final classFilter = controller.classFilter.value;
        final typeFilter = controller.typeFilter.value;
        return Wrap(
          runSpacing: 12,
          spacing: 12,
          children: [
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<String?>(
                value: classFilter,
                decoration: const InputDecoration(
                  labelText: 'Filter by class',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All classes'),
                  ),
                  ...classes.map(
                    (item) => DropdownMenuItem<String?>(
                      value: item.id,
                      child: Text(item.name),
                    ),
                  ),
                ],
                onChanged: controller.setClassFilter,
              ),
            ),
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<BehaviorType?>(
                value: typeFilter,
                decoration: const InputDecoration(
                  labelText: 'Filter by type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem<BehaviorType?>(
                    value: null,
                    child: Text('All types'),
                  ),
                  DropdownMenuItem<BehaviorType?>(
                    value: BehaviorType.positive,
                    child: Text('Positive'),
                  ),
                  DropdownMenuItem<BehaviorType?>(
                    value: BehaviorType.negative,
                    child: Text('Negative'),
                  ),
                ],
                onChanged: controller.setTypeFilter,
              ),
            ),
          ],
        );
      }),
    );
  }
}

Future<bool> _confirmDelete(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Delete behavior'),
            content: const Text(
              'Are you sure you want to remove this behavior record?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          );
        },
      ) ??
      false;
}
