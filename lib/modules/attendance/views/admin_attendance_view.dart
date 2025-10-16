import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../models/attendance_record_model.dart';
import '../../common/widgets/module_card.dart';
import '../../common/widgets/module_empty_state.dart';
import '../../common/widgets/module_page_container.dart';
import '../controllers/admin_attendance_controller.dart';
import 'admin_child_attendance_detail_view.dart';
import 'widgets/attendance_date_card.dart';

class AdminAttendanceView extends GetView<AdminAttendanceController> {
  const AdminAttendanceView({super.key});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMMd();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        title: const Text('Student Attendance'),
        centerTitle: true,
      ),
      body: ModulePageContainer(
        child: Column(
          children: [
            const _AdminAttendanceFilters(),
            _StudentAttendanceDateCard(dateFormat: dateFormat),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                final summaries = controller.childSummaries;
                final shortDateFormat = DateFormat.yMMMd();
                return RefreshIndicator(
                  onRefresh: controller.refreshData,
                  child: summaries.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 120, 16, 160),
                          children: const [
                            ModuleEmptyState(
                              icon: Icons.school_outlined,
                              title: 'No attendance data found',
                              message:
                                  'Adjust the filters above to review attendance submissions for students.',
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
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
                            final presentCount = summary.presentCount;
                            final absentCount = summary.absentCount;
                            final pendingCount = summary.pendingCount;
                            final totalSubjects = summary.totalSubjects;
                            final avatarText = summary.childName.isNotEmpty
                                ? summary.childName[0].toUpperCase()
                                : '?';
                            final theme = Theme.of(context);
                            return ModuleCard(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AdminChildAttendanceDetailView(
                                    summary: summary,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 26,
                                        backgroundColor: theme.colorScheme.primary
                                            .withOpacity(0.12),
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
                                              summary.childName,
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              summary.className,
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: theme
                                                    .colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              '$totalSubjects subject${totalSubjects == 1 ? '' : 's'} tracked',
                                              style: theme.textTheme.bodySmall,
                                            ),
                                            if (latestDateLabel != null) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                'Latest entry: $latestDateLabel',
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  color: theme.colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              ),
                                            ],
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
                                      if (presentCount > 0)
                                        _AttendanceSummaryPill(
                                          backgroundColor: Colors.green.shade50,
                                          iconColor: Colors.green.shade600,
                                          icon: Icons.check_circle,
                                          label: '$presentCount present',
                                        ),
                                      if (absentCount > 0)
                                        _AttendanceSummaryPill(
                                          backgroundColor: theme.colorScheme.error
                                              .withOpacity(0.12),
                                          iconColor: theme.colorScheme.error,
                                          icon: Icons.cancel_outlined,
                                          label: '$absentCount absent',
                                        ),
                                      if (pendingCount > 0)
                                        _AttendanceSummaryPill(
                                          backgroundColor: theme.colorScheme.primary
                                              .withOpacity(0.12),
                                          iconColor: theme.colorScheme.primary,
                                          icon: Icons.hourglass_empty,
                                          label: '$pendingCount pending',
                                        ),
                                    ],
                                  ),
                                ],
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

class _AdminAttendanceFilters extends StatelessWidget {
  const _AdminAttendanceFilters();

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMMd();
    final theme = Theme.of(context);
    final controller = Get.find<AdminAttendanceController>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() {
            final hasFilters =
                (controller.classFilter.value ?? '').isNotEmpty ||
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
            final classId = controller.classFilter.value;
            if (classId != null && classId.isNotEmpty) {
              chips.add(
                _ActiveFilterChip(
                  label: 'Class: ${controller.className(classId)}',
                  onRemoved: () => controller.setClassFilter(null),
                ),
              );
            }
            final date = controller.dateFilter.value;
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
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 640;
              final fieldWidth = isWide
                  ? constraints.maxWidth / 2 - 8
                  : double.infinity;
              return SizedBox(
                width: fieldWidth,
                child: Obx(() {
                  final classes = controller.classes;
                  final value = controller.classFilter.value;
                  return DropdownButtonFormField<String?>(
                    value: value,
                    decoration: const InputDecoration(
                      labelText: 'Class',
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('All classes'),
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
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StudentAttendanceDateCard extends StatelessWidget {
  const _StudentAttendanceDateCard({required this.dateFormat});

  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminAttendanceController>();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Obx(() {
        final selectedDate = controller.dateFilter.value;
        final classId = controller.classFilter.value;
        final classLabel = (classId == null || classId.isEmpty)
            ? 'All classes'
            : controller.className(classId);
        final dateLabel = selectedDate == null
            ? 'All dates'
            : dateFormat.format(selectedDate);
        final summaries = controller.childSummaries;
        final totalStudents = summaries.length;
        return AttendanceDateCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Attendance overview',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$classLabel • $dateLabel',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (selectedDate != null)
                        OutlinedButton.icon(
                          onPressed: () => controller.setDateFilter(null),
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Clear date'),
                        ),
                      TextButton.icon(
                        onPressed: () async {
                          final now = DateTime.now();
                          final initialDate = selectedDate ?? now;
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: initialDate,
                            firstDate: DateTime(now.year - 1),
                            lastDate: DateTime(now.year + 1),
                          );
                          if (picked != null) {
                            controller.setDateFilter(DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                            ));
                          }
                        },
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(
                          selectedDate == null
                              ? 'Select date'
                              : 'Change date',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                totalStudents == 0
                    ? 'No students match the selected filters.'
                    : 'Review attendance records for $totalStudents student${totalStudents == 1 ? '' : 's'}.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      }),
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
