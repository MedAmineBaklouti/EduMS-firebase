import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../data/models/homework_model.dart';
import '../../common/widgets/module_card.dart';
import '../../common/widgets/module_empty_state.dart';
import '../../common/widgets/module_page_container.dart';
import '../controllers/admin_homework_controller.dart';

class AdminHomeworkListView extends GetView<AdminHomeworkController> {
  const AdminHomeworkListView({super.key});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMMd();
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Homeworks'),
        centerTitle: true,
      ),
      body: ModulePageContainer(
        child: Column(
          children: [
            const _AdminHomeworkFilters(),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = controller.homeworks;
                if (items.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 120, 16, 160),
                    children: const [
                      ModuleEmptyState(
                        icon: Icons.library_books_outlined,
                        title: 'No homeworks match the filters',
                        message:
                            'Adjust the filters above to explore assignments shared across classes.',
                      ),
                    ],
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final homework = items[index];
                    return _AdminHomeworkCard(
                      homework: homework,
                      dateFormat: dateFormat,
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminHomeworkFilters extends StatelessWidget {
  const _AdminHomeworkFilters();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: GetBuilder<AdminHomeworkController>(
        builder: (controller) {
          return ModuleCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter homeworks',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 720;
                    final fieldWidth = isWide ? constraints.maxWidth / 2 - 8 : double.infinity;
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

class _AdminHomeworkCard extends StatelessWidget {
  const _AdminHomeworkCard({
    required this.homework,
    required this.dateFormat,
  });

  final HomeworkModel homework;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = theme.colorScheme.primary;
    return ModuleCard(
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
            '${homework.className} • ${homework.teacherName}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Due ${dateFormat.format(homework.dueDate)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.assignment_turned_in_outlined, size: 16, color: statusColor),
                  const SizedBox(width: 4),
                  Text(
                    '${homework.completionByChildId.values.where((v) => v).length}/${homework.completionByChildId.length} completed',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: statusColor,
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
