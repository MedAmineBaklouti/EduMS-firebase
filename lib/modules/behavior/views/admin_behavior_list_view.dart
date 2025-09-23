import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../data/models/behavior_model.dart';
import '../controllers/admin_behavior_controller.dart';
import '../widgets/behavior_type_chip.dart';

class AdminBehaviorListView extends GetView<AdminBehaviorController> {
  const AdminBehaviorListView({super.key});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd().add_jm();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Behavior Oversight'),
      ),
      body: Column(
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 48,
                        ),
                        children: const [
                          _AdminEmptyState(),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final behavior = items[index];
                          return _AdminBehaviorCard(
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

class _AdminBehaviorFilters extends StatelessWidget {
  const _AdminBehaviorFilters();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: GetBuilder<AdminBehaviorController>(
        builder: (controller) {
          return Wrap(
            runSpacing: 12,
            spacing: 12,
            children: [
              Obx(() {
                final classes = controller.classes;
                final classFilter = controller.classFilter.value;
                return SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String?>(
                    value: classFilter,
                    decoration: const InputDecoration(
                      labelText: 'Class',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All classes'),
                      ),
                      ...classes.map(
                        (item) => DropdownMenuItem<String?>(
                          value: item.id,
                          child: Text(item.name),
                        ),
                      ),
                    ],
                    onChanged: controller.setClassFilter,
                  ),
                );
              }),
              Obx(() {
                final teachers = controller.teachers;
                final teacherFilter = controller.teacherFilter.value;
                return SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String?>(
                    value: teacherFilter,
                    decoration: const InputDecoration(
                      labelText: 'Teacher',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All teachers'),
                      ),
                      ...teachers.map(
                        (item) => DropdownMenuItem<String?>(
                          value: item.id,
                          child: Text(item.name),
                        ),
                      ),
                    ],
                    onChanged: controller.setTeacherFilter,
                  ),
                );
              }),
              Obx(() {
                final typeFilter = controller.typeFilter.value;
                return SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<BehaviorType?>(
                    value: typeFilter,
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
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _AdminBehaviorCard extends StatelessWidget {
  const _AdminBehaviorCard({
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
                        '${behavior.className} • ${behavior.teacherName}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
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

class _AdminEmptyState extends StatelessWidget {
  const _AdminEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.fact_check_outlined,
          size: 64,
          color: theme.colorScheme.outline,
        ),
        const SizedBox(height: 16),
        Text(
          'No behaviors recorded for the selected filters.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}
