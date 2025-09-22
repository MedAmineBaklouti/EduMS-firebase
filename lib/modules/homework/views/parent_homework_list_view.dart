import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../data/models/homework_model.dart';
import '../controllers/parent_homework_controller.dart';

class ParentHomeworkListView extends GetView<ParentHomeworkController> {
  const ParentHomeworkListView({super.key});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMMd();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Homework Overview'),
      ),
      body: Column(
        children: [
          const _ParentHomeworkFilters(),
          Obx(() {
            final activeChild = controller.activeChild;
            if (controller.children.length > 1 && activeChild == null) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Select a child to manage homework completion status.',
                    style: TextStyle(color: Colors.orangeAccent),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              final items = controller.homeworks;
              if (items.isEmpty) {
                return const Center(
                  child: Text('No homework assignments are available.'),
                );
              }
              final activeChildId = controller.activeChildId;
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final homework = items[index];
                  final isLocked = homework.isLockedForParent(DateTime.now());
                  final isCompleted = activeChildId == null
                      ? false
                      : homework.isCompletedForChild(activeChildId);
                  return Card(
                    child: CheckboxListTile(
                      value: isCompleted,
                      onChanged: activeChildId == null || isLocked
                          ? null
                          : (value) {
                              controller.markCompletion(
                                homework,
                                activeChildId,
                                value ?? false,
                              );
                            },
                      title: Text(homework.title),
                      subtitle: Text(
                        '${homework.className} • Due ${dateFormat.format(homework.dueDate)}',
                      ),
                      secondary: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isLocked
                                ? 'Locked'
                                : (isCompleted ? 'Done' : 'Pending'),
                            style: TextStyle(
                              color: isLocked
                                  ? Colors.grey
                                  : isCompleted
                                      ? Colors.green
                                      : Colors.orange,
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

class _ParentHomeworkFilters extends StatelessWidget {
  const _ParentHomeworkFilters();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: GetBuilder<ParentHomeworkController>(
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
                final completionFilter = controller.completionFilter.value;
                return DropdownButtonFormField<bool?>(
                  value: completionFilter,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem<bool?>(
                      value: null,
                      child: Text('All homeworks'),
                    ),
                    DropdownMenuItem<bool?>(
                      value: false,
                      child: Text('Pending only'),
                    ),
                    DropdownMenuItem<bool?>(
                      value: true,
                      child: Text('Completed only'),
                    ),
                  ],
                  onChanged: controller.setCompletionFilter,
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
