import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../data/models/behavior_model.dart';
import '../../common/widgets/module_card.dart';
import '../../common/widgets/module_empty_state.dart';
import '../../common/widgets/module_page_container.dart';
import '../controllers/parent_behavior_controller.dart';
import '../widgets/behavior_type_chip.dart';
import 'behavior_detail_view.dart';

class ParentBehaviorListView extends GetView<ParentBehaviorController> {
  const ParentBehaviorListView({super.key});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd().add_jm();
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Children Behaviors'),
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
                          children: const [
                            ModuleEmptyState(
                              icon: Icons.family_restroom_outlined,
                              title: 'No behavior records yet',
                              message:
                                  'Behavior updates for your children will appear here once teachers start sharing them.',
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
                'Filter behaviors',
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
                  label: const Text('Clear'),
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
              chips.add(
                _buildActiveFilterChip(
                  context,
                  label: 'Child: ${childName ?? 'Child'}',
                  onRemoved: () => controller.setChildFilter(null),
                ),
              );
            }
            final type = controller.typeFilter.value;
            if (type != null) {
              chips.add(
                _buildActiveFilterChip(
                  context,
                  label: 'Type: ${_behaviorTypeLabel(type)}',
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
                    decoration: const InputDecoration(
                      labelText: 'Child',
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
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(() {
                  final type = controller.typeFilter.value;
                  return DropdownButtonFormField<BehaviorType?>(
                    value: type,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem<BehaviorType?>(
                        value: null,
                        child: Text('All types'),
                      ),
                      DropdownMenuItem<BehaviorType?>(
                        value: BehaviorType.positive,
                        child: Text('Positive'),
                      ),
                      DropdownMenuItem<BehaviorType?>(
                        value: BehaviorType.negative,
                        child: Text('Negative'),
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
    switch (type) {
      case BehaviorType.positive:
        return 'Positive';
      case BehaviorType.negative:
        return 'Negative';
    }
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
                      'Teacher: ${behavior.teacherName}',
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
                ? 'No description provided.'
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
