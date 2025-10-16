import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../models/homework_model.dart';
import '../../../common/widgets/module_card.dart';
import '../../../common/widgets/module_empty_state.dart';
import '../../../common/widgets/module_page_container.dart';
import '../controllers/parent_homework_controller.dart';
import 'homework_detail_view.dart';

class ParentHomeworkListView extends GetView<ParentHomeworkController> {
  const ParentHomeworkListView({super.key});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMMd();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        title: Text('homework_parent_list_title'.tr),
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
                return RefreshIndicator(
                  onRefresh: controller.refreshData,
                  child: items.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding:
                              const EdgeInsets.fromLTRB(16, 120, 16, 160),
                          children: [
                            ModuleEmptyState(
                              icon: Icons.checklist_rtl_outlined,
                              title: 'homework_parent_empty_title'.tr,
                              message: 'homework_parent_empty_message'.tr,
                            ),
                          ],
                        )
                      : _ParentHomeworkList(
                          items: items,
                          dateFormat: dateFormat,
                        ),
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
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'homework_filters_title'.tr,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: hasFilters ? controller.clearFilters : null,
                      icon:
                          const Icon(Icons.filter_alt_off_outlined, size: 18),
                      label: Text('common_clear'.tr),
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
                          label: 'homework_filter_chip_child'.trParams({
                            'child': controller.childName(childFilter!),
                          }),
                          onRemoved: () => controller.setChildFilter(null),
                        ),
                      if (hasStatusFilter)
                        _ParentFilterChip(
                          label: completionFilter == true
                              ? 'homework_filter_chip_status_completed'.tr
                              : 'homework_filter_chip_status_pending'.tr,
                          onRemoved: () => controller.setCompletionFilter(null),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  value: childFilter,
                  decoration: InputDecoration(
                    labelText: 'homework_filter_label_child'.tr,
                    border: const OutlineInputBorder(),
                  ),
                  hint: Text('homework_filter_all_children'.tr),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text('homework_filter_all_children'.tr),
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
                  decoration: InputDecoration(
                    labelText: 'homework_filter_label_status'.tr,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem<bool?>(
                      value: null,
                      child: Text('homework_filter_status_all'.tr),
                    ),
                    DropdownMenuItem<bool?>(
                      value: false,
                      child: Text('homework_filter_status_pending'.tr),
                    ),
                    DropdownMenuItem<bool?>(
                      value: true,
                      child: Text('homework_filter_status_completed'.tr),
                    ),
                  ],
                  onChanged: controller.setCompletionFilter,
                ),
              ],
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
        ? 'homework_parent_summary_none'.tr
        : allCompleted
            ? 'homework_parent_summary_all'.tr
            : 'homework_parent_summary_partial'.trParams({
                'completed': '$completedChildren',
                'total': '$totalChildren',
              });
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
                      'homework_due_date'.trParams(
                        {'date': dateFormat.format(homework.dueDate)},
                      ),
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
              'homework_parent_locked_message'.tr,
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Colors.transparent),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ]
          else ...[
            const SizedBox(height: 12),
            Text(
              'homework_parent_unlinked'.tr,
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

class _ParentHomeworkList extends StatelessWidget {
  const _ParentHomeworkList({
    required this.items,
    required this.dateFormat,
  });

  final List<HomeworkModel> items;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ParentHomeworkController>();
    final now = DateTime.now();
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
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
                completed: homework.isCompletedForChild(child.id),
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
                onParentToggle: (childId, value) =>
                    controller.markCompletion(homework, childId, value),
              ),
            );
          },
        );
      },
    );
  }
}
