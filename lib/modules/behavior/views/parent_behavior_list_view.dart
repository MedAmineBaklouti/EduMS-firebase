import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:edums/core/widgets/module_card.dart';
import 'package:edums/core/widgets/module_empty_state.dart';
import 'package:edums/core/widgets/module_page_container.dart';
import '../../../data/models/behavior_model.dart';
import '../controllers/parent_behavior_controller.dart';
import '../widgets/behavior_type_chip.dart';
import 'behavior_detail_view.dart';

class ParentBehaviorListView extends GetView<ParentBehaviorController> {
  const ParentBehaviorListView({super.key});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd().add_jm();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        title: Text('behavior_parent_title'.tr),
        centerTitle: true,
      ),
      body: ModulePageContainer(
        child: Column(
          children: [
            const _ParentBehaviorFilters(),
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
                              icon: Icons.family_restroom_outlined,
                              title: 'behavior_parent_empty_title'.tr,
                              message:
                                  'behavior_parent_empty_message'.tr,
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
                            return _ParentBehaviorCard(
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

class _ParentBehaviorFilters extends StatelessWidget {
  const _ParentBehaviorFilters();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ParentBehaviorController>();
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
                    (controller.childFilter.value ?? '').isNotEmpty ||
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
            final childId = controller.childFilter.value;
            if (childId != null && childId.isNotEmpty) {
              String? childName;
              for (final child in controller.children) {
                if (child.id == childId) {
                  childName = child.name;
                  break;
                }
              }
              childName ??= 'behavior_filter_label_child'.tr;
              chips.add(
                _buildActiveFilterChip(
                  context,
                  label: 'behavior_filter_chip_child'
                      .trParams({'child': childName!}),
                  onRemoved: () => controller.setChildFilter(null),
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
          Row(
            children: [
              Expanded(
                child: Obx(() {
                  final children = controller.children;
                  final selected = controller.childFilter.value;
                  final value =
                      selected == null || selected.isEmpty ? null : selected;
                  return DropdownButtonFormField<String?>(
                    value: value,
                    decoration: InputDecoration(
                      labelText: 'behavior_filter_label_child'.tr,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text('behavior_filter_all_children'.tr),
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
              ),
              const SizedBox(width: 12),
              Expanded(
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
                        child: Text('behavior_filter_all_types'.tr),
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

class _ParentBehaviorCard extends StatelessWidget {
  const _ParentBehaviorCard({
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
                    Text(
                      'behavior_card_teacher'
                          .trParams({'teacher': behavior.teacherName}),
                      style: theme.textTheme.bodySmall,
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
    );
  }
}
