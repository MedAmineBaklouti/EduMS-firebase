import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../models/behavior_model.dart';
import '../../../common/widgets/module_card.dart';
import '../../../common/widgets/module_empty_state.dart';
import '../../../common/widgets/module_page_container.dart';
import '../controllers/teacher_behavior_controller.dart';
import '../widgets/behavior_type_chip.dart';
import '../../../common/widgets/swipe_action_background.dart';
import 'behavior_detail_view.dart';
import 'teacher_behavior_form_view.dart';

class TeacherBehaviorListView extends GetView<TeacherBehaviorController> {
  const TeacherBehaviorListView({super.key});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd().add_jm();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        title: Text('behavior_teacher_title'.tr),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          controller.startCreate();
          Get.to(() => const TeacherBehaviorFormView());
        },
        icon: const Icon(Icons.add),
        label: Text('behavior_teacher_new_record'.tr),
      ),
      body: ModulePageContainer(
        child: Column(
          children: [
            _TeacherBehaviorFilters(controller: controller),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = controller.behaviors;
                return RefreshIndicator(
                  onRefresh: controller.refreshData,
                  child: items.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 120, 16, 160),
                          children: [
                            ModuleEmptyState(
                              icon: Icons.emoji_people_outlined,
                              title: 'behavior_teacher_empty_title'.tr,
                              message: 'behavior_teacher_empty_message'.trParams({
                                'action': 'behavior_teacher_new_record'.tr,
                              }),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final behavior = items[index];
                            return Dismissible(
                              key: ValueKey(behavior.id),
                              background: SwipeActionBackground(
                                alignment: Alignment.centerLeft,
                                color: Theme.of(context).colorScheme.primary,
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
                                  controller.startEdit(behavior);
                                  await Get.to(() => const TeacherBehaviorFormView());
                                  return false;
                                }
                                return _confirmDelete(context);
                              },
                              onDismissed: (_) {
                                controller.removeBehavior(behavior);
                              },
                              child: _BehaviorCard(
                                behavior: behavior,
                                dateFormat: dateFormat,
                                onTap: () {
                                  Get.to(
                                  () => BehaviorDetailView(
                                      behavior: behavior,
                                      onEdit: () async {
                                        Get.back();
                                        controller.startEdit(behavior);
                                        await Get.to(
                                            () => const TeacherBehaviorFormView());
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

class _TeacherBehaviorFilters extends StatelessWidget {
  const _TeacherBehaviorFilters({required this.controller});

  final TeacherBehaviorController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 640;
          final fieldWidth =
              isWide ? constraints.maxWidth / 2 - 8 : double.infinity;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'behavior_filters_title'.tr,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Obx(() {
                    final hasFilters =
                        (controller.classFilter.value ?? '').isNotEmpty ||
                            controller.typeFilter.value != null;
                    return TextButton.icon(
                      onPressed: hasFilters ? controller.clearFilters : null,
                      icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                      label: Text('common_clear'.tr),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 12),
              Obx(() {
                final chips = <Widget>[];
                final classFilter = controller.classFilter.value;
                if (classFilter != null && classFilter.isNotEmpty) {
                  chips.add(
                    _buildActiveFilterChip(
                      context,
                      label: 'behavior_filter_chip_class'.trParams({
                        'class': controller.classNameFor(classFilter) ??
                            'behavior_filter_label_class'.tr,
                      }),
                      onRemoved: () => controller.setClassFilter(null),
                    ),
                  );
                }
                final typeFilter = controller.typeFilter.value;
                if (typeFilter != null) {
                  chips.add(
                    _buildActiveFilterChip(
                      context,
                      label: 'behavior_filter_chip_type'
                          .trParams({'type': _behaviorTypeLabel(typeFilter)}),
                      onRemoved: () => controller.setTypeFilter(null),
                    ),
                  );
                }
                if (chips.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: chips,
                  ),
                );
              }),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: fieldWidth,
                    child: Obx(() {
                      final classes = controller.classes;
                      final classFilter = controller.classFilter.value;
                      return DropdownButtonFormField<String?>(
                        value: classFilter,
                        decoration: InputDecoration(
                          labelText: 'behavior_teacher_filter_label_class'.tr,
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child:
                                Text('behavior_filter_all_classes'.tr),
                          ),
                          ...classes.map(
                            (item) => DropdownMenuItem<String?>(
                              value: item.id,
                              child: Text(item.name),
                            ),
                          ),
                        ],
                        onChanged: controller.setClassFilter,
                      );
                    }),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: Obx(() {
                      final typeFilter = controller.typeFilter.value;
                      return DropdownButtonFormField<BehaviorType?>(
                        value: typeFilter,
                        decoration: InputDecoration(
                          labelText: 'behavior_teacher_filter_label_type'.tr,
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem<BehaviorType?>(
                            value: null,
                            child:
                                Text('behavior_filter_all_types'.tr),
                          ),
                          DropdownMenuItem<BehaviorType?>(
                            value: BehaviorType.positive,
                            child: Text('behavior_type_positive'.tr),
                          ),
                          DropdownMenuItem<BehaviorType?>(
                            value: BehaviorType.negative,
                            child: Text('behavior_type_negative'.tr),
                          ),
                        ],
                        onChanged: controller.setTypeFilter,
                      );
                    }),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActiveFilterChip(
    BuildContext context, {
    required String label,
    required VoidCallback onRemoved,
  }) {
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

  String _behaviorTypeLabel(BehaviorType type) {
    return type.label;
  }
}

Future<bool> _confirmDelete(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final dialogTheme = Theme.of(dialogContext);
      return AlertDialog(
        title: Text('behavior_teacher_confirm_delete_title'.tr),
        content: Text(
          'behavior_teacher_confirm_delete_message'.tr,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'common_cancel'.tr,
              style:
                  TextStyle(color: dialogTheme.colorScheme.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'common_delete'.tr,
              style: TextStyle(color: dialogTheme.colorScheme.error),
            ),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

class _BehaviorCard extends StatelessWidget {
  const _BehaviorCard({
    required this.behavior,
    required this.dateFormat,
    this.onTap,
  });

  final BehaviorModel behavior;
  final DateFormat dateFormat;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trimmedName = behavior.childName.trim();
    final avatarText =
        trimmedName.isNotEmpty ? trimmedName[0].toUpperCase() : '?';
    return ModuleCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                child: Text(
                  avatarText,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      behavior.childName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      behavior.className,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              BehaviorTypeChip(type: behavior.type),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            behavior.description.isEmpty
                ? 'behavior_card_no_description'.tr
                : behavior.description,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Icon(Icons.schedule, size: 16),
              const SizedBox(width: 4),
              Text(
                'behavior_card_recorded'.trParams(
                    {'date': dateFormat.format(behavior.createdAt)}),
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

