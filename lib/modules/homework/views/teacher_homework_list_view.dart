import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../data/models/homework_model.dart';
import '../../common/widgets/module_card.dart';
import '../../common/widgets/module_empty_state.dart';
import '../../common/widgets/module_page_container.dart';
import '../../common/widgets/swipe_action_background.dart';
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
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          controller.startCreate();
          Get.to(() => const TeacherHomeworkFormView());
        },
        icon: const Icon(Icons.add),
        label: const Text('New homework'),
      ),
      body: ModulePageContainer(
        child: Column(
          children: [
            const _TeacherHomeworkFilters(),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = controller.homeworks;
                if (items.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 120, 16, 160),
                    children: const [
                      ModuleEmptyState(
                        icon: Icons.menu_book_outlined,
                        title: 'No homework assignments found',
                        message:
                            'Create your first assignment to help students stay on track.',
                      ),
                    ],
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final homework = items[index];
                    return Dismissible(
                      key: ValueKey(homework.id),
                      background: SwipeActionBackground(
                        alignment: Alignment.centerLeft,
                        color: Theme.of(context).colorScheme.primary,
                        icon: Icons.edit_outlined,
                        label: 'Edit',
                      ),
                      secondaryBackground: SwipeActionBackground(
                        alignment: Alignment.centerRight,
                        color: Theme.of(context).colorScheme.error,
                        icon: Icons.delete_outline,
                        label: 'Delete',
                      ),
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          controller.startEdit(homework);
                          await Get.to(
                            () => const TeacherHomeworkFormView(),
                          );
                          return false;
                        }
                        return _confirmDelete(context);
                      },
                      onDismissed: (_) {
                        controller.removeHomework(homework);
                      },
                      child: _TeacherHomeworkCard(
                        homework: homework,
                        dateFormat: dateFormat,
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
      ),
    );
  }
}

class _TeacherHomeworkFilters extends StatelessWidget {
  const _TeacherHomeworkFilters();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: ModuleCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter assignments',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Obx(() {
              final controller = Get.find<TeacherHomeworkController>();
              final classes = controller.classes;
              final classFilter = controller.filterClassId.value;
              return DropdownButtonFormField<String?>(
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
              );
            }),
          ],
        ),
      ),
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

class _TeacherHomeworkCard extends StatelessWidget {
  const _TeacherHomeworkCard({
    required this.homework,
    required this.dateFormat,
    this.onTap,
  });

  final HomeworkModel homework;
  final DateFormat dateFormat;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ModuleCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      homework.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      homework.className,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16),
              const SizedBox(width: 6),
              Text(
                'Due ${dateFormat.format(homework.dueDate)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
