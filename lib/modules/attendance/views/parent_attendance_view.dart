import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../data/models/attendance_record_model.dart';
import '../../common/widgets/module_card.dart';
import '../../common/widgets/module_empty_state.dart';
import '../../common/widgets/module_page_container.dart';
import '../controllers/parent_attendance_controller.dart';

class ParentAttendanceView extends GetView<ParentAttendanceController> {
  const ParentAttendanceView({super.key});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMMd();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance History'),
        centerTitle: true,
      ),
      body: ModulePageContainer(
        child: Column(
          children: [
            const _ParentAttendanceFilters(),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                final sessions = controller.sessions;
                final childId = controller.childFilter.value;
                if (sessions.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 120, 16, 160),
                    children: const [
                      ModuleEmptyState(
                        icon: Icons.event_busy_outlined,
                        title: 'No attendance records',
                        message:
                            'Attendance updates for your children will appear here once they are recorded.',
                      ),
                    ],
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  physics: const BouncingScrollPhysics(),
                  itemCount: sessions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    final entry = childId == null
                        ? null
                        : controller.entryFor(session, childId);
                    final statusLabel = entry == null
                        ? '${session.records.where((e) => e.status == AttendanceStatus.present).length} present / ${session.records.length}'
                        : entry.status == AttendanceStatus.present
                            ? 'Present'
                            : 'Absent';
                    return ModuleCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dateFormat.format(session.date),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            childId == null
                                ? '${session.className} • ${session.teacherName}'
                                : session.className,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                entry == null
                                    ? Icons.groups_outlined
                                    : entry.status == AttendanceStatus.present
                                        ? Icons.check_circle
                                        : Icons.cancel_outlined,
                                color: entry == null
                                    ? Theme.of(context).colorScheme.primary
                                    : entry.status == AttendanceStatus.present
                                        ? Colors.green
                                        : Theme.of(context).colorScheme.error,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                statusLabel,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

class _ParentAttendanceFilters extends StatelessWidget {
  const _ParentAttendanceFilters();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ParentAttendanceController>();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() {
            final hasFilter = (controller.childFilter.value ?? '').isNotEmpty;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter attendance',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton.icon(
                  onPressed: hasFilter ? controller.clearFilters : null,
                  icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                  label: const Text('Clear'),
                ),
              ],
            );
          }),
          const SizedBox(height: 12),
          Obx(() {
            final childId = controller.childFilter.value;
            if (childId == null || childId.isEmpty) {
              return const SizedBox.shrink();
            }
            final child = controller.children
                .firstWhereOrNull((element) => element.id == childId);
            final childName = child?.name ?? 'Child';
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ActiveFilterChip(
                label: 'Child: $childName',
                onRemoved: controller.clearFilters,
              ),
            );
          }),
          Obx(() {
            final children = controller.children;
            final childFilter = controller.childFilter.value;
            return DropdownButtonFormField<String?>(
              value: childFilter,
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
        ],
      ),
    );
  }
}

class _ActiveFilterChip extends StatelessWidget {
  const _ActiveFilterChip({required this.label, required this.onRemoved});

  final String label;
  final VoidCallback onRemoved;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      label: Text(label),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onRemoved,
      backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      labelStyle: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
