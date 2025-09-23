import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../data/models/homework_model.dart';
import '../../common/widgets/module_card.dart';
import '../../common/widgets/module_empty_state.dart';
import '../../common/widgets/module_page_container.dart';
import '../controllers/parent_homework_controller.dart';

class ParentHomeworkListView extends GetView<ParentHomeworkController> {
  const ParentHomeworkListView({super.key});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMMd();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Homework Overview'),
        centerTitle: true,
      ),
      body: ModulePageContainer(
        child: Column(
          children: [
            const _ParentHomeworkFilters(),
            Obx(() {
              final activeChild = controller.activeChild;
              if (controller.children.length > 1 && activeChild == null) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Select a child to manage homework completion status.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
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
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 120, 16, 160),
                    children: const [
                      ModuleEmptyState(
                        icon: Icons.checklist_rtl_outlined,
                        title: 'No homework assignments are available',
                        message:
                            'When teachers publish new homework, it will appear here for your review.',
                      ),
                    ],
                  );
                }
                final activeChildId = controller.activeChildId;
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  physics: const BouncingScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final homework = items[index];
                    final isLocked = homework.isLockedForParent(DateTime.now());
                    final isCompleted = activeChildId == null
                        ? false
                        : homework.isCompletedForChild(activeChildId);
                    return _ParentHomeworkCard(
                      homework: homework,
                      dateFormat: dateFormat,
                      isLocked: isLocked,
                      isCompleted: isCompleted,
                      onChanged: activeChildId == null || isLocked
                          ? null
                          : (value) {
                              controller.markCompletion(
                                homework,
                                activeChildId,
                                value ?? false,
                              );
                            },
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

class _ParentHomeworkFilters extends StatelessWidget {
  const _ParentHomeworkFilters();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: GetBuilder<ParentHomeworkController>(
        builder: (controller) {
          return ModuleCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter homeworks',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
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
            ),
          );
        },
      ),
    );
  }
}

class _ParentHomeworkCard extends StatelessWidget {
  const _ParentHomeworkCard({
    required this.homework,
    required this.dateFormat,
    required this.isLocked,
    required this.isCompleted,
    required this.onChanged,
  });

  final HomeworkModel homework;
  final DateFormat dateFormat;
  final bool isLocked;
  final bool isCompleted;
  final ValueChanged<bool?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = isLocked
        ? theme.colorScheme.outline
        : isCompleted
            ? Colors.green
            : Colors.orange;
    final statusLabel = isLocked
        ? 'Locked'
        : isCompleted
            ? 'Completed'
            : 'Pending';
    return ModuleCard(
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
                    const SizedBox(height: 8),
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
              ),
              Checkbox(
                value: isCompleted,
                onChanged: onChanged,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            statusLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (homework.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              homework.description,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}
