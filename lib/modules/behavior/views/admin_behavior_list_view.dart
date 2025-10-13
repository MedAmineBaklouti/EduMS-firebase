import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:edums/core/widgets/module_card.dart';
import 'package:edums/core/widgets/module_empty_state.dart';
import 'package:edums/core/widgets/module_page_container.dart';
import '../../../data/models/behavior_model.dart';
import '../controllers/admin_behavior_controller.dart';
import '../widgets/behavior_type_chip.dart';
import 'behavior_detail_view.dart';

class AdminBehaviorListView extends GetView<AdminBehaviorController> {
  const AdminBehaviorListView({super.key});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd().add_jm();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        title: Text('behavior_admin_title'.tr),
        centerTitle: true,
      ),
      body: ModulePageContainer(
        child: Column(
          children: [
            const _AdminBehaviorFilters(),
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
                              icon: Icons.fact_check_outlined,
                              title: 'behavior_admin_empty_title'.tr,
                              message: 'behavior_admin_empty_message'.tr,
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
                            final behavior = items[index];
                            return _AdminBehaviorCard(
                              behavior: behavior,
                              dateFormat: dateFormat,
                              onTap: () {
                                Get.to(
                                  () => BehaviorDetailView(
                                    behavior: behavior,
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

class _AdminBehaviorFilters extends StatelessWidget {
  const _AdminBehaviorFilters();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminBehaviorController>();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
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
                        (controller.teacherFilter.value ?? '').isNotEmpty ||
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
            final classId = controller.classFilter.value;
            if (classId != null && classId.isNotEmpty) {
              final className = controller.className(classId) ??
                  'behavior_filter_label_class'.tr;
              chips.add(
                _buildActiveFilterChip(
                  context,
                  label: 'behavior_filter_chip_class'
                      .trParams({'class': className}),
                  onRemoved: () => controller.setClassFilter(null),
                ),
              );
            }
            final teacherId = controller.teacherFilter.value;
            if (teacherId != null && teacherId.isNotEmpty) {
              final teacherName = controller.teacherName(teacherId) ??
                  'behavior_filter_label_teacher'.tr;
              chips.add(
                _buildActiveFilterChip(
                  context,
                  label: 'behavior_filter_chip_teacher'
                      .trParams({'teacher': teacherName}),
                  onRemoved: () => controller.setTeacherFilter(null),
                ),
              );
            }
            final type = controller.typeFilter.value;
            if (type != null) {
              chips.add(
                _buildActiveFilterChip(
                  context,
                  label: 'behavior_filter_chip_type'
                      .trParams({'type': _behaviorTypeLabel(type)}),
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
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 12.0;
              final maxWidth = constraints.maxWidth;
              double itemWidth;
              if (maxWidth >= 900) {
                itemWidth = (maxWidth - (2 * spacing)) / 3;
              } else if (maxWidth >= 600) {
                itemWidth = (maxWidth - spacing) / 2;
              } else {
                itemWidth = maxWidth;
              }
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: Obx(() {
                      final classes = controller.classes;
                      final selected = controller.classFilter.value;
                      final value =
                          selected == null || selected.isEmpty ? null : selected;
                      return DropdownButtonFormField<String?>(
                        value: value,
                        decoration: InputDecoration(
                          labelText: 'behavior_filter_label_class'.tr,
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
                    width: itemWidth,
                    child: Obx(() {
                      final teachers = controller.teachers;
                      final selected = controller.teacherFilter.value;
                      final value =
                          selected == null || selected.isEmpty ? null : selected;
                      return DropdownButtonFormField<String?>(
                        value: value,
                        decoration: InputDecoration(
                          labelText: 'behavior_filter_label_teacher'.tr,
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child:
                                Text('behavior_filter_all_teachers'.tr),
                          ),
                          ...teachers.map(
                            (item) => DropdownMenuItem<String?>(
                              value: item.id,
                              child: Text(item.name),
                            ),
                          ),
                        ],
                        onChanged: controller.setTeacherFilter,
                      );
                    }),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: Obx(() {
                      final type = controller.typeFilter.value;
                      return DropdownButtonFormField<BehaviorType?>(
                        value: type,
                        decoration: InputDecoration(
                          labelText: 'behavior_filter_label_type'.tr,
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
              );
            },
          ),
        ],
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

class _AdminBehaviorCard extends StatelessWidget {
  const _AdminBehaviorCard({
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
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            behavior.teacherName,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.class_outlined, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    behavior.className,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(behavior.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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
