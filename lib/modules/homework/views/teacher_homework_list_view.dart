import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../models/homework_model.dart';
import '../../common/widgets/module_card.dart';
import '../../common/widgets/module_empty_state.dart';
import '../../common/widgets/module_page_container.dart';
import '../../common/widgets/swipe_action_background.dart';
import '../controllers/teacher_homework_controller.dart';
import 'homework_detail_view.dart';
import 'teacher_homework_form_view.dart';

class TeacherHomeworkListView extends GetView<TeacherHomeworkController> {
  const TeacherHomeworkListView({super.key});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMMd();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        title: Text('homework_teacher_list_title'.tr),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          controller.startCreate();
          Get.to(() => const TeacherHomeworkFormView());
        },
        icon: const Icon(Icons.add),
        label: Text('homework_teacher_action_new'.tr),
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
                return RefreshIndicator(
                  onRefresh: controller.refreshData,
                  child: items.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding:
                              const EdgeInsets.fromLTRB(16, 120, 16, 160),
                          children: [
                            ModuleEmptyState(
                              icon: Icons.menu_book_outlined,
                              title: 'homework_teacher_empty_title'.tr,
                              message: 'homework_teacher_empty_message'.tr,
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(16, 16, 16, 120),
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final homework = items[index];
                            final totalChildren =
                                controller.childCountForClass(homework.classId);
                            return Dismissible(
                              key: ValueKey(homework.id),
                              background: SwipeActionBackground(
                                alignment: Alignment.centerLeft,
                                color:
                                    Theme.of(context).colorScheme.primary,
                                icon: Icons.edit_outlined,
                                label: 'common_edit'.tr,
                              ),
                              secondaryBackground: SwipeActionBackground(
                                alignment: Alignment.centerRight,
                                color: Theme.of(context).colorScheme.error,
                                icon: Icons.delete_outline,
                                label: 'common_delete'.tr,
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
                                totalChildren: totalChildren,
                                onTap: () {
                                  Get.to(
                                    () => HomeworkDetailView(
                                      homework: homework,
                                      initialChildCount: totalChildren,
                                      showTeacherInsights: true,
                                      onEdit: () async {
                                        Get.back();
                                        await Future<void>.delayed(
                                            Duration.zero);
                                        controller.startEdit(homework);
                                        await Get.to(
                                          () =>
                                              const TeacherHomeworkFormView(),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
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

class _TeacherHomeworkFilters extends StatelessWidget {
  const _TeacherHomeworkFilters();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.find<TeacherHomeworkController>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'homework_teacher_filters_title'.tr,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Obx(() {
                final hasFilter =
                    (controller.filterClassId.value ?? '').isNotEmpty;
                return TextButton.icon(
                  onPressed: hasFilter ? controller.clearFilters : null,
                  icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                  label: Text('common_clear'.tr),
                );
              }),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() {
            final classFilter = controller.filterClassId.value;
            if (classFilter == null || classFilter.isEmpty) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ActiveFilterChip(
                    label: 'homework_filter_chip_class'.trParams({
                      'class': controller.className(classFilter),
                    }),
                    onRemoved: controller.clearFilters,
                  ),
                ],
              ),
            );
          }),
          Obx(() {
            final classes = controller.classes;
            final classFilter = controller.filterClassId.value;
            final isDisabled = classes.isEmpty;
            return DropdownButtonFormField<String?>(
              value: classFilter,
              decoration: InputDecoration(
                labelText: 'homework_filter_label_class'.tr,
                border: const OutlineInputBorder(),
              ),
              hint: Text(
                isDisabled
                    ? 'homework_teacher_filter_hint_none'.tr
                    : 'homework_filter_all_classes'.tr,
              ),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text('homework_filter_all_classes'.tr),
                ),
                ...classes.map(
                  (item) => DropdownMenuItem<String?>(
                    value: item.id,
                    child: Text(item.name),
                  ),
                ),
              ],
              onChanged: isDisabled ? null : controller.setFilterClass,
            );
          }),
        ],
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

Future<bool> _confirmDelete(BuildContext context) async {
  final theme = Theme.of(context);
  return await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('homework_confirm_delete_title'.tr),
            content: Text(
              'homework_confirm_delete_message'.tr,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'common_cancel'.tr,
                  style:
                      TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'common_delete'.tr,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
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
    final completedCount =
        homework.completionByChildId.values.where((value) => value).length;
    final totalCount = totalChildren ?? homework.completionByChildId.length;
    final completionLabel = totalCount > 0
        ? 'homework_completion_summary_full'.trParams({
            'completed': '$completedCount',
            'total': '$totalCount',
          })
        : 'homework_completion_summary_partial'
            .trParams({'completed': '$completedCount'});
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
                'homework_due_date'
                    .trParams({'date': dateFormat.format(homework.dueDate)}),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.assignment_turned_in_outlined,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                completionLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
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
