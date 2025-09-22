import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/behavior_model.dart';
import '../controllers/admin_behavior_controller.dart';

class AdminBehaviorListView extends GetView<AdminBehaviorController> {
  const AdminBehaviorListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Behavior Oversight'),
      ),
      body: Column(
        children: [
          const _AdminBehaviorFilters(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              final items = controller.behaviors;
              if (items.isEmpty) {
                return const Center(
                  child: Text('No behaviors recorded for the selected filters.'),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final behavior = items[index];
                  return Card(
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
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _AdminBehaviorFilters extends StatelessWidget {
  const _AdminBehaviorFilters();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: GetBuilder<AdminBehaviorController>(
        builder: (controller) {
          return Wrap(
            runSpacing: 12,
            spacing: 12,
            children: [
              Obx(() {
                final classes = controller.classes;
                final classFilter = controller.classFilter.value;
                return SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String?>(
                    value: classFilter,
                    decoration: const InputDecoration(
                      labelText: 'Class',
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
                );
              }),
              Obx(() {
                final teachers = controller.teachers;
                final teacherFilter = controller.teacherFilter.value;
                return SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String?>(
                    value: teacherFilter,
                    decoration: const InputDecoration(
                      labelText: 'Teacher',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All teachers'),
                      ),
                      ...teachers.map(
                        (item) => DropdownMenuItem<String?>(
                          value: item.id,
                          child: Text(item.name),
                        ),
                      ),
                    ],
                    onChanged: controller.setTeacherFilter,
                  ),
                );
              }),
              Obx(() {
                final typeFilter = controller.typeFilter.value;
                return SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<BehaviorType?>(
                    value: typeFilter,
                    decoration: const InputDecoration(
                      labelText: 'Type',
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
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
