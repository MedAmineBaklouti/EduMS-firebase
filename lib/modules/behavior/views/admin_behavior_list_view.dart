import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../data/models/behavior_model.dart';
import '../../common/widgets/module_card.dart';
import '../../common/widgets/module_empty_state.dart';
import '../../common/widgets/module_page_container.dart';
import '../controllers/admin_behavior_controller.dart';
import '../widgets/behavior_type_chip.dart';
import 'behavior_detail_view.dart';

class AdminBehaviorListView extends GetView<AdminBehaviorController> {
  const AdminBehaviorListView({super.key});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd().add_jm();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Behavior Oversight'),
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
                          children: const [
                            ModuleEmptyState(
                              icon: Icons.fact_check_outlined,
                              title: 'No behaviors match the filters',
                              message:
                                  'Adjust the filters above to explore behavior records shared by teachers across the school.',
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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: GetBuilder<AdminBehaviorController>(
        builder: (controller) {
          return ModuleCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter records',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 640;
                    final fieldWidth = isWide ? constraints.maxWidth / 3 - 8 : double.infinity;
                    return Wrap(
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
                            );
                          }),
                        ),
                        SizedBox(
                          width: fieldWidth,
                          child: Obx(() {
                            final teachers = controller.teachers;
                            final teacherFilter = controller.teacherFilter.value;
                            return DropdownButtonFormField<String?>(
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
                    );
                  },
                ),
              ],
            ),
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
                ? 'No description provided.'
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
