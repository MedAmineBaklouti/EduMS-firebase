import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../data/models/homework_model.dart';
import '../../common/widgets/module_card.dart';
import '../../common/widgets/module_empty_state.dart';
import '../../common/widgets/module_page_container.dart';
import '../controllers/admin_homework_controller.dart';
import 'homework_detail_view.dart';

class AdminHomeworkListView extends GetView<AdminHomeworkController> {
  const AdminHomeworkListView({super.key});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMMd();
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Homeworks'),
        centerTitle: true,
      ),
      body: ModulePageContainer(
        child: Column(
          children: [
            const _AdminHomeworkFilters(),
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
                          padding: const EdgeInsets.fromLTRB(16, 120, 16, 160),
                          children: const [
                            ModuleEmptyState(
                              icon: Icons.library_books_outlined,
                              title: 'No homeworks match the filters',
                              message:
                                  'Adjust the filters above to explore assignments shared across classes.',
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final homework = items[index];
                            final totalChildren =
                                controller.childCountForClass(homework.classId);
                            return _AdminHomeworkCard(
                              homework: homework,
                              dateFormat: dateFormat,
                              totalChildren: totalChildren,
                              onTap: () {
                                Get.to(
                                  () => HomeworkDetailView(
                                    homework: homework,
                                    initialChildCount: totalChildren,
                                  ),
                                );
                              },
                            );
                          },
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

class _AdminHomeworkFilters extends StatelessWidget {
  const _AdminHomeworkFilters();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: GetBuilder<AdminHomeworkController>(
        builder: (controller) {
          return Obx(() {
            final hasClassFilter =
                (controller.classFilter.value ?? '').isNotEmpty;
            final hasTeacherFilter =
                (controller.teacherFilter.value ?? '').isNotEmpty;
            final hasFilters = hasClassFilter || hasTeacherFilter;
            return Column(
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
                      if (hasClassFilter)
                        _ActiveFilterChip(
                          label:
                              'Class: ${controller.className(controller.classFilter.value!)}',
                          onRemoved: () => controller.setClassFilter(null),
                        ),
                      if (hasTeacherFilter)
                        _ActiveFilterChip(
                          label:
                              'Teacher: ${controller.teacherName(controller.teacherFilter.value!)}',
                          onRemoved: () => controller.setTeacherFilter(null),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 720;
                    final fieldWidth =
                        isWide ? constraints.maxWidth / 2 - 8 : double.infinity;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: fieldWidth,
                          child: DropdownButtonFormField<String?>(
                            value: controller.classFilter.value,
                            decoration: const InputDecoration(
                              labelText: 'Class',
                              border: OutlineInputBorder(),
                            ),
                            hint: const Text('All classes'),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('All classes'),
                              ),
                              ...controller.classes.map(
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
                          width: fieldWidth,
                          child: DropdownButtonFormField<String?>(
                            value: controller.teacherFilter.value,
                            decoration: const InputDecoration(
                              labelText: 'Teacher',
                              border: OutlineInputBorder(),
                            ),
                            hint: const Text('All teachers'),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('All teachers'),
                              ),
                              ...controller.teachers.map(
                                (item) => DropdownMenuItem<String?>(
                                  value: item.id,
                                  child: Text(item.name),
                                ),
                              ),
                            ],
                            onChanged: controller.setTeacherFilter,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            );
          });
        },
      ),
    );
  }
}

class _ActiveFilterChip extends StatelessWidget {
  const _ActiveFilterChip({required this.label, required this.onRemoved});

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

class _AdminHomeworkCard extends StatelessWidget {
  const _AdminHomeworkCard({
    required this.homework,
    required this.dateFormat,
    this.totalChildren,
    this.onTap,
  });

  final HomeworkModel homework;
  final DateFormat dateFormat;
  final int? totalChildren;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = theme.colorScheme.primary;
    final completedCount =
        homework.completionByChildId.values.where((v) => v).length;
    final totalCount = totalChildren ?? homework.completionByChildId.length;
    final completionLabel = totalCount > 0
        ? '$completedCount/$totalCount completed'
        : '$completedCount completed';
    return ModuleCard(
      onTap: onTap,
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
            '${homework.className} • ${homework.teacherName}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
              Row(
                children: [
                  Icon(Icons.assignment_turned_in_outlined, size: 16, color: statusColor),
                  const SizedBox(width: 4),
                  Text(
                    completionLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
