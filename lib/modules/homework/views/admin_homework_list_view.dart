import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../data/models/homework_model.dart';
import '../controllers/admin_homework_controller.dart';

class AdminHomeworkListView extends GetView<AdminHomeworkController> {
  const AdminHomeworkListView({super.key});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMMd();
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Homeworks'),
      ),
      body: Column(
        children: [
          const _AdminHomeworkFilters(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              final items = controller.homeworks;
              if (items.isEmpty) {
                return const Center(
                  child: Text('No homework assignments match the filters.'),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final homework = items[index];
                  return Card(
                    child: ListTile(
                      title: Text(homework.title),
                      subtitle: Text(
                        '${homework.className} • ${homework.teacherName}\nDue ${dateFormat.format(homework.dueDate)}',
                      ),
                      isThreeLine: true,
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

class _AdminHomeworkFilters extends StatelessWidget {
  const _AdminHomeworkFilters();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: GetBuilder<AdminHomeworkController>(
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
            ],
          );
        },
      ),
    );
  }
}
