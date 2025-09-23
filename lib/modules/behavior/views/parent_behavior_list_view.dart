import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../data/models/behavior_model.dart';
import '../controllers/parent_behavior_controller.dart';
import '../widgets/behavior_type_chip.dart';

class ParentBehaviorListView extends GetView<ParentBehaviorController> {
  const ParentBehaviorListView({super.key});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd().add_jm();
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Children Behaviors'),
      ),
      body: Column(
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 48,
                        ),
                        children: const [
                          _ParentEmptyState(),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final behavior = items[index];
                          return _ParentBehaviorCard(
                            behavior: behavior,
                            dateFormat: dateFormat,
                          );
                        },
                      ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _ParentBehaviorFilters extends StatelessWidget {
  const _ParentBehaviorFilters();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: GetBuilder<ParentBehaviorController>(
        builder: (controller) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                final typeFilter = controller.typeFilter.value;
                return DropdownButtonFormField<BehaviorType?>(
                  value: typeFilter,
                  decoration: const InputDecoration(
                    labelText: 'Filter by type',
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
            ],
          );
        },
      ),
    );
  }
}

class _ParentBehaviorCard extends StatelessWidget {
  const _ParentBehaviorCard({
    required this.behavior,
    required this.dateFormat,
  });

  final BehaviorModel behavior;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trimmedName = behavior.childName.trim();
    final avatarText =
        trimmedName.isNotEmpty ? trimmedName[0].toUpperCase() : '?';
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    avatarText,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        behavior.childName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        behavior.className,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 4),
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
            const SizedBox(height: 12),
            Text(
              behavior.description.isEmpty
                  ? 'No description provided.'
                  : behavior.description,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                dateFormat.format(behavior.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParentEmptyState extends StatelessWidget {
  const _ParentEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.family_restroom_outlined,
          size: 64,
          color: theme.colorScheme.outline,
        ),
        const SizedBox(height: 16),
        Text(
          'No behavior records are available yet.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}
