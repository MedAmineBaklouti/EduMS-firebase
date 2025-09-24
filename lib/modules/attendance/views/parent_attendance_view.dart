import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../common/widgets/module_card.dart';
import '../../common/widgets/module_empty_state.dart';
import '../../common/widgets/module_page_container.dart';
import '../controllers/parent_attendance_controller.dart';
import '../models/child_attendance_summary.dart';
import 'parent_child_attendance_detail_view.dart';

class ParentAttendanceView extends GetView<ParentAttendanceController> {
  const ParentAttendanceView({super.key});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMMd();
    final shortDateFormat = DateFormat.yMMMd();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
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
                final summaries = controller.childSummaries;
                if (summaries.isEmpty) {
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
                  itemCount: summaries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final summary = summaries[index];
                    final latestEntry = summary.subjectEntries.isEmpty
                        ? null
                        : summary.subjectEntries.first;
                    final latestDateLabel = latestEntry == null
                        ? null
                        : shortDateFormat.format(latestEntry.date);
                    return _ParentChildSummaryCard(
                      summary: summary,
                      latestDateLabel: latestDateLabel,
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

class _ParentChildSummaryCard extends StatelessWidget {
  const _ParentChildSummaryCard({
    required this.summary,
    this.latestDateLabel,
  });

  final ChildAttendanceSummary summary;
  final String? latestDateLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final presentCount = summary.presentCount;
    final absentCount = summary.absentCount;
    final pendingCount = summary.pendingCount;
    return ModuleCard(
      onTap: () => Get.to(
        () => ParentChildAttendanceDetailView(summary: summary),
      ),
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
                  summary.childName.isNotEmpty
                      ? summary.childName[0].toUpperCase()
                      : '?',
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
                      summary.childName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      summary.className,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${summary.totalSubjects} subject${summary.totalSubjects == 1 ? '' : 's'} tracked',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (latestDateLabel != null)
                _AttendanceSummaryPill(
                  backgroundColor:
                      theme.colorScheme.secondary.withOpacity(0.12),
                  iconColor: theme.colorScheme.secondary,
                  icon: Icons.event,
                  label: 'Latest: $latestDateLabel',
                ),
              if (presentCount > 0)
                _AttendanceSummaryPill(
                  backgroundColor: Colors.green.shade50,
                  iconColor: Colors.green.shade600,
                  icon: Icons.check_circle,
                  label: '$presentCount present',
                ),
              if (absentCount > 0)
                _AttendanceSummaryPill(
                  backgroundColor: theme.colorScheme.error.withOpacity(0.12),
                  iconColor: theme.colorScheme.error,
                  icon: Icons.cancel_outlined,
                  label: '$absentCount absent',
                ),
              if (pendingCount > 0)
                _AttendanceSummaryPill(
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                  iconColor: theme.colorScheme.primary,
                  icon: Icons.hourglass_empty,
                  label: '$pendingCount pending',
                ),
            ],
          ),
        ],
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
    final dateFormat = DateFormat.yMMMMd();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() {
            final hasFilters =
                (controller.childFilter.value ?? '').isNotEmpty ||
                    controller.dateFilter.value != null;
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
                  onPressed: hasFilters ? controller.clearFilters : null,
                  icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                  label: const Text('Clear'),
                ),
              ],
            );
          }),
          const SizedBox(height: 12),
          Obx(() {
            final chips = <Widget>[];
            final childId = controller.childFilter.value;
            final date = controller.dateFilter.value;
            if (childId != null && childId.isNotEmpty) {
              final child = controller.children
                  .firstWhereOrNull((element) => element.id == childId);
              final childName = child?.name ?? 'Child';
              chips.add(
                _ActiveFilterChip(
                  label: 'Child: $childName',
                  onRemoved: () => controller.setChildFilter(null),
                ),
              );
            }
            if (date != null) {
              chips.add(
                _ActiveFilterChip(
                  label: 'Date: ${dateFormat.format(date)}',
                  onRemoved: () => controller.setDateFilter(null),
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
          Obx(() {
            final children = controller.children;
            final childValue = controller.childFilter.value;
            return DropdownButtonFormField<String?>(
              value: childValue,
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
          const SizedBox(height: 12),
          Obx(() {
            final selectedDate = controller.dateFilter.value;
            return GestureDetector(
              onTap: () async {
                final now = DateTime.now();
                final initialDate = selectedDate ?? now;
                final picked = await showDatePicker(
                  context: context,
                  initialDate: initialDate,
                  firstDate: DateTime(now.year - 1),
                  lastDate: DateTime(now.year + 1),
                );
                controller.setDateFilter(picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today, size: 18),
                ),
                isEmpty: selectedDate == null,
                child: Text(
                  selectedDate == null
                      ? 'Any date'
                      : dateFormat.format(selectedDate),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: selectedDate == null
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _AttendanceSummaryPill extends StatelessWidget {
  const _AttendanceSummaryPill({
    required this.backgroundColor,
    required this.iconColor,
    required this.icon,
    required this.label,
  });

  final Color backgroundColor;
  final Color iconColor;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: iconColor,
              fontWeight: FontWeight.w600,
            ),
          ),
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
