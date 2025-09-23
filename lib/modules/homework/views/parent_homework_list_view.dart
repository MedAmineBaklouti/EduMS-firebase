import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../data/models/homework_model.dart';
import '../../common/widgets/module_card.dart';
import '../../common/widgets/module_empty_state.dart';
import '../../common/widgets/module_page_container.dart';
import '../controllers/parent_homework_controller.dart';
import 'homework_detail_view.dart';

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
                final now = DateTime.now();
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  physics: const BouncingScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final homework = items[index];
                    final isLocked = homework.isLockedForParent(now);
                    final relevantChildren =
                        controller.childrenForClass(homework.classId)
                          ..sort((a, b) => a.name.compareTo(b.name));
                    final childStatuses = relevantChildren
                        .map(
                          (child) => _ParentChildStatus(
                            childId: child.id,
                            name: child.name,
                            completed:
                                homework.isCompletedForChild(child.id),
                          ),
                        )
                        .toList();
                    return _ParentHomeworkCard(
                      homework: homework,
                      dateFormat: dateFormat,
                      isLocked: isLocked,
                      childStatuses: childStatuses,
                      onTap: () {
                        final relevantChildren =
                            controller.childrenForClass(homework.classId)
                              ..sort((a, b) => a.name.compareTo(b.name));
                        Get.to(
                          () => HomeworkDetailView(
                            homework: homework,
                            showParentControls: true,
                            parentChildren: relevantChildren,
                            isParentLocked: isLocked,
                            initialChildCount: relevantChildren.length,
                            onParentToggle: (childId, value) => controller
                                .markCompletion(homework, childId, value),
                          ),
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
          return Obx(() {
            final childFilter = controller.childFilter.value;
            final completionFilter = controller.completionFilter.value;
            final hasChildFilter = (childFilter ?? '').isNotEmpty;
            final hasStatusFilter = completionFilter != null;
            final hasFilters = hasChildFilter || hasStatusFilter;
            return ModuleCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter homeworks',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: hasFilters ? controller.clearFilters : null,
                        icon:
                            const Icon(Icons.filter_alt_off_outlined, size: 18),
                        label: const Text('Clear'),
                      ),
                    ],
                  ),
                  if (hasFilters) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (hasChildFilter)
                          _ParentFilterChip(
                            label:
                                'Child: ${controller.childName(childFilter!)}',
                            onRemoved: () => controller.setChildFilter(null),
                          ),
                        if (hasStatusFilter)
                          _ParentFilterChip(
                            label: completionFilter == true
                                ? 'Status: Completed'
                                : 'Status: Pending',
                            onRemoved: () => controller.setCompletionFilter(null),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    value: childFilter,
                    decoration: const InputDecoration(
                      labelText: 'Child',
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('All children'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All children'),
                      ),
                      ...controller.children.map(
                        (child) => DropdownMenuItem<String?>(
                          value: child.id,
                          child: Text(child.name),
                        ),
                      ),
                    ],
                    onChanged: controller.setChildFilter,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<bool?>(
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
                  ),
                ],
              ),
            );
          });
        },
      ),
    );
  }
}

class _ParentFilterChip extends StatelessWidget {
  const _ParentFilterChip({required this.label, required this.onRemoved});

  final String label;
  final VoidCallback onRemoved;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      avatar: Icon(
        Icons.filter_alt_outlined,
        size: 18,
        color: theme.colorScheme.primary,
      ),
      label: Text(label),
      deleteIcon: const Icon(Icons.close, size: 18),
      onDeleted: onRemoved,
      backgroundColor: theme.colorScheme.primary.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      labelStyle: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ParentHomeworkCard extends StatelessWidget {
  const _ParentHomeworkCard({
    required this.homework,
    required this.dateFormat,
    required this.isLocked,
    required this.childStatuses,
    this.onTap,
  });

  final HomeworkModel homework;
  final DateFormat dateFormat;
  final bool isLocked;
  final List<_ParentChildStatus> childStatuses;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalChildren = childStatuses.length;
    final completedChildren =
        childStatuses.where((status) => status.completed).length;
    final allCompleted = totalChildren > 0 && completedChildren == totalChildren;
    final summaryColor = isLocked
        ? theme.colorScheme.outline
        : allCompleted
            ? Colors.green
            : theme.colorScheme.secondary;
    final summaryLabel = totalChildren == 0
        ? 'No linked children'
        : allCompleted
            ? 'Completed for all children'
            : '$completedChildren of $totalChildren completed';
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
              const Icon(Icons.chevron_right),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            summaryLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: summaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (isLocked) ...[
            const SizedBox(height: 6),
            Text(
              'Marked as closed. Updates can be managed from the homework details.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (childStatuses.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: childStatuses
                  .map(
                    (status) => Chip(
                      avatar: Icon(
                        status.completed
                            ? Icons.check_circle_outline
                            : Icons.radio_button_unchecked,
                        size: 18,
                        color: status.completed
                            ? Colors.green
                            : theme.colorScheme.secondary,
                      ),
                      label: Text(status.name),
                      backgroundColor: status.completed
                          ? Colors.green.withOpacity(0.12)
                          : theme.colorScheme.secondary.withOpacity(0.12),
                      labelStyle: theme.textTheme.bodySmall?.copyWith(
                        color: status.completed
                            ? Colors.green.shade700
                            : theme.colorScheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ]
          else ...[
            const SizedBox(height: 12),
            Text(
              'This homework isn\'t linked to any of your children.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
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

class _ParentChildStatus {
  const _ParentChildStatus({
    required this.childId,
    required this.name,
    required this.completed,
  });

  final String childId;
  final String name;
  final bool completed;
}
