import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/teacher_homework_controller.dart';
import 'teacher_homework_form_view.dart';

class TeacherHomeworkListView extends GetView<TeacherHomeworkController> {
  const TeacherHomeworkListView({super.key});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMMd();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Homework Manager'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          controller.startCreate();
          Get.to(() => const TeacherHomeworkFormView());
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          const _TeacherHomeworkFilters(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              final items = controller.homeworks;
              if (items.isEmpty) {
                return const Center(
                  child: Text('No homework assignments found.'),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final homework = items[index];
                  return Dismissible(
                    key: ValueKey(homework.id),
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
                        controller.startEdit(homework);
                        await Get.to(() => const TeacherHomeworkFormView());
                        return false;
                      }
                      return _confirmDelete(context);
                    },
                    onDismissed: (_) {
                      controller.removeHomework(homework);
                    },
                    child: ListTile(
                      title: Text(homework.title),
                      subtitle: Text(
                        '${homework.className} • Due ${dateFormat.format(homework.dueDate)}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        controller.startEdit(homework);
                        Get.to(() => const TeacherHomeworkFormView());
                      },
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

class _TeacherHomeworkFilters extends StatelessWidget {
  const _TeacherHomeworkFilters();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Obx(() {
        final controller = Get.find<TeacherHomeworkController>();
        final classes = controller.classes;
        final classFilter = controller.filterClassId.value;
        return SizedBox(
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
            onChanged: controller.setFilterClass,
          ),
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
            title: const Text('Delete homework'),
            content: const Text(
              'Are you sure you want to delete this homework assignment?',
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
