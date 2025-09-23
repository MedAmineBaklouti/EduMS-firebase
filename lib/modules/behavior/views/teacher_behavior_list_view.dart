import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../data/models/behavior_model.dart';
import '../controllers/teacher_behavior_controller.dart';
import '../widgets/behavior_type_chip.dart';
import 'teacher_behavior_form_view.dart';

class TeacherBehaviorListView extends GetView<TeacherBehaviorController> {
  const TeacherBehaviorListView({super.key});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd().add_jm();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Behaviors'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          controller.startCreate();
          Get.to(() => const TeacherBehaviorFormView());
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 48,
                        ),
                        children: const [
                          _EmptyBehaviorState(
                            message:
                                'No behaviors have been recorded yet. Use the button below to add your first entry.',
                          ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final behavior = items[index];
                          return Dismissible(
                            key: ValueKey(behavior.id),
                            background: Container(
                              color: Colors.blue,
                              alignment: Alignment.centerLeft,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child:
                                  const Icon(Icons.edit, color: Colors.white),
                            ),
                            secondaryBackground: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child:
                                  const Icon(Icons.delete, color: Colors.white),
                            ),
                            confirmDismiss: (direction) async {
                              if (direction == DismissDirection.startToEnd) {
                                controller.startEdit(behavior);
                                await Get.to(
                                    () => const TeacherBehaviorFormView());
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
                                controller.startEdit(behavior);
                                Get.to(() => const TeacherBehaviorFormView());
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
    );
  }
}

class _TeacherBehaviorFilters extends StatelessWidget {
  const _TeacherBehaviorFilters({required this.controller});

  final TeacherBehaviorController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Obx(() {
        final classes = controller.classes;
        final classFilter = controller.classFilter.value;
        final typeFilter = controller.typeFilter.value;
        return Wrap(
          runSpacing: 12,
          spacing: 12,
          children: [
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<String?>(
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
              ),
            ),
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<BehaviorType?>(
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
              ),
            ),
          ],
        );
      }),
    );
  }
}

Future<bool> _confirmDelete(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Delete behavior'),
            content: const Text(
              'Are you sure you want to remove this behavior record?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          );
        },
      ) ??
      false;
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
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
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
                  'Recorded ${dateFormat.format(behavior.createdAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyBehaviorState extends StatelessWidget {
  const _EmptyBehaviorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.emoji_people_outlined,
          size: 64,
          color: theme.colorScheme.outline,
        ),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}
