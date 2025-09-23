import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../data/models/behavior_model.dart';
import '../../common/widgets/module_card.dart';
import '../../common/widgets/module_empty_state.dart';
import '../../common/widgets/module_page_container.dart';
import '../controllers/teacher_behavior_controller.dart';
import '../widgets/behavior_type_chip.dart';
import '../../common/widgets/swipe_action_background.dart';
import 'behavior_detail_view.dart';
import 'teacher_behavior_form_view.dart';

class TeacherBehaviorListView extends GetView<TeacherBehaviorController> {
  const TeacherBehaviorListView({super.key});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd().add_jm();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Behaviors'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          controller.startCreate();
          Get.to(() => const TeacherBehaviorFormView());
        },
        icon: const Icon(Icons.add),
        label: const Text('New record'),
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
                          children: const [
                            ModuleEmptyState(
                              icon: Icons.emoji_people_outlined,
                              title: 'No behaviors recorded yet',
                              message:
                                  'Tap the “New record” button to capture your first classroom observation.',
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
                                label: 'Edit',
                              ),
                              secondaryBackground: SwipeActionBackground(
                                alignment: Alignment.centerRight,
                                color: Theme.of(context).colorScheme.error,
                                icon: Icons.delete_outline,
                                label: 'Delete',
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
                                      onDelete: () async {
                                        await controller.removeBehavior(behavior);
                                        Get.back();
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
                    'Filter behaviors',
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
                      label: const Text('Clear'),
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
                      label: 'Class: ${controller.classNameFor(classFilter)}',
                      onRemoved: () => controller.setClassFilter(null),
                    ),
                  );
                }
                final typeFilter = controller.typeFilter.value;
                if (typeFilter != null) {
                  chips.add(
                    _buildActiveFilterChip(
                      context,
                      label: 'Type: ${_behaviorTypeLabel(typeFilter)}',
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
                        decoration: const InputDecoration(
                          labelText: 'Filter by class',
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
                      );
                    }),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: Obx(() {
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
    switch (type) {
      case BehaviorType.positive:
        return 'Positive';
      case BehaviorType.negative:
        return 'Negative';
    }
  }
}

Future<bool> _confirmDelete(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final dialogTheme = Theme.of(dialogContext);
      return AlertDialog(
        title: const Text('Delete behavior'),
        content: const Text(
          'Are you sure you want to delete this behavior record?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancel',
              style:
                  TextStyle(color: dialogTheme.colorScheme.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Delete',
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
                'Recorded ${dateFormat.format(behavior.createdAt)}',
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

