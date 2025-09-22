import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/behavior_model.dart';
import '../controllers/parent_behavior_controller.dart';

class ParentBehaviorListView extends GetView<ParentBehaviorController> {
  const ParentBehaviorListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Children Behaviors'),
      ),
      body: Column(
        children: [
          const _ParentBehaviorFilters(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              final items = controller.behaviors;
              if (items.isEmpty) {
                return const Center(
                  child: Text('No behavior records are available yet.'),
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
                        'Teacher: ${behavior.teacherName}\n${behavior.description}',
                      ),
                      isThreeLine: true,
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            behavior.type.label,
                            style: TextStyle(
                              color: behavior.type == BehaviorType.positive
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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

class _ParentBehaviorFilters extends StatelessWidget {
  const _ParentBehaviorFilters();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: GetBuilder<ParentBehaviorController>(
        builder: (controller) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Obx(() {
                final children = controller.children;
                final childFilter = controller.childFilter.value;
                return DropdownButtonFormField<String?>(
                  value: childFilter,
                  decoration: const InputDecoration(
                    labelText: 'Filter by child',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All children'),
                    ),
                    ...children.map(
                      (child) => DropdownMenuItem<String?>(
                        value: child.id,
                        child: Text(child.name),
                      ),
                    ),
                  ],
                  onChanged: controller.setChildFilter,
                );
              }),
              const SizedBox(height: 12),
              Obx(() {
                final typeFilter = controller.typeFilter.value;
                return DropdownButtonFormField<BehaviorType?>(
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
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
