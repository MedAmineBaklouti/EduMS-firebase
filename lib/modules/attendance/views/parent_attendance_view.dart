import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../common/widgets/module_card.dart';
import '../../../common/widgets/module_empty_state.dart';
import '../../../common/widgets/module_page_container.dart';
import '../controllers/parent_attendance_controller.dart';
import '../models/child_attendance_summary.dart';
import 'parent_child_attendance_detail_view.dart';
import 'widgets/attendance_date_card.dart';

class ParentAttendanceView extends GetView<ParentAttendanceController> {
  const ParentAttendanceView({super.key});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMMd();
    final shortDateFormat = DateFormat.yMMMd();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        title: Text('attendance_parent_title'.tr),
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
                return RefreshIndicator(
                  onRefresh: controller.refreshData,
                  child: summaries.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding:
                              const EdgeInsets.fromLTRB(16, 120, 16, 160),
                          children: [
                            ModuleEmptyState(
                              icon: Icons.event_busy_outlined,
                              title: 'attendance_parent_empty_title'.tr,
                              message: 'attendance_parent_empty_message'.tr,
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(16, 16, 16, 32),
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
                            return _ParentChildSummaryCard(
                              summary: summary,
                              latestDateLabel: latestDateLabel,
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
    final latestDate = latestDateLabel;
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
                    Builder(
                      builder: (context) {
                        final subjectKey = summary.totalSubjects == 1
                            ? 'attendance_summary_subjects_single'
                            : 'attendance_summary_subjects_plural';
                        final subjectLabel = subjectKey.trParams({
                          'count': summary.totalSubjects.toString(),
                        });
                        return Text(
                          subjectLabel,
                          style: theme.textTheme.bodySmall,
                        );
                      },
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
              if (latestDate != null)
                _AttendanceSummaryPill(
                  backgroundColor:
                      theme.colorScheme.secondary.withOpacity(0.12),
                  iconColor: theme.colorScheme.secondary,
                  icon: Icons.event,
                  label: 'attendance_summary_latest'
                      .trParams({'date': latestDate}),
                ),
              if (presentCount > 0)
                _AttendanceSummaryPill(
                  backgroundColor: Colors.green.shade50,
                  iconColor: Colors.green.shade600,
                  icon: Icons.check_circle,
                  label: (presentCount == 1
                          ? 'attendance_summary_present_single'
                          : 'attendance_summary_present_plural')
                      .trParams({'count': presentCount.toString()}),
                ),
              if (absentCount > 0)
                _AttendanceSummaryPill(
                  backgroundColor: theme.colorScheme.error.withOpacity(0.12),
                  iconColor: theme.colorScheme.error,
                  icon: Icons.cancel_outlined,
                  label: (absentCount == 1
                          ? 'attendance_summary_absent_single'
                          : 'attendance_summary_absent_plural')
                      .trParams({'count': absentCount.toString()}),
                ),
              if (pendingCount > 0)
                _AttendanceSummaryPill(
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                  iconColor: theme.colorScheme.primary,
                  icon: Icons.hourglass_empty,
                  label: (pendingCount == 1
                          ? 'attendance_summary_pending_single'
                          : 'attendance_summary_pending_plural')
                      .trParams({'count': pendingCount.toString()}),
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
                  'attendance_filters_title'.tr,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton.icon(
                  onPressed: hasFilters ? controller.clearFilters : null,
                  icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                  label: Text('common_clear'.tr),
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
              final childName = child?.name ?? 'attendance_filters_child_label'.tr;
              chips.add(
                _ActiveFilterChip(
                  label: 'attendance_filters_child_chip'
                      .trParams({'name': childName}),
                  onRemoved: () => controller.setChildFilter(null),
                ),
              );
            }
            if (date != null) {
              chips.add(
                _ActiveFilterChip(
                  label: 'attendance_filters_date_chip'
                      .trParams({'date': dateFormat.format(date)}),
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
              decoration: InputDecoration(
                labelText: 'attendance_filters_child_label'.tr,
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text('attendance_filters_child_all'.tr),
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
            final childId = controller.childFilter.value;
            final child = childId == null || childId.isEmpty
                ? null
                : controller.children
                    .firstWhereOrNull((element) => element.id == childId);
            final now = DateTime.now();
            final hasDate = selectedDate != null;
            final dateLabel = hasDate
                ? dateFormat.format(selectedDate!)
                : 'attendance_overview_date_all'.tr;
            final rawChildName = child?.name ?? '';
            final normalizedChildName = rawChildName.trim();
            final hasNamedChild = normalizedChildName.isNotEmpty;
            final childLabel = child == null
                ? 'attendance_overview_child_all'.tr
                : hasNamedChild
                    ? normalizedChildName
                    : 'attendance_overview_child_selected'.tr;
            final messageChild = child == null
                ? 'attendance_overview_message_all_children'.tr
                : hasNamedChild
                    ? normalizedChildName
                    : 'attendance_overview_message_selected_child'.tr;
            final overviewLabel = 'attendance_overview_label'
                .trParams({'child': childLabel, 'date': dateLabel});
            final description = hasDate
                ? 'attendance_overview_description_date'
                    .trParams({'child': messageChild, 'date': dateLabel})
                : 'attendance_overview_description_all_dates'
                    .trParams({'child': messageChild});
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
                              'attendance_overview_title'.tr,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              overviewLabel,
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
                          if (hasDate)
                            OutlinedButton.icon(
                              onPressed: () => controller.setDateFilter(null),
                              icon: const Icon(Icons.refresh, size: 18),
                              label:
                                  Text('attendance_filters_clear_date'.tr),
                            ),
                          TextButton.icon(
                            onPressed: () async {
                              final initialDate = selectedDate ?? now;
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: initialDate,
                                firstDate: DateTime(now.year - 1),
                                lastDate: DateTime(now.year + 1),
                              );
                              if (picked != null) {
                                controller.setDateFilter(picked);
                              }
                            },
                            icon: const Icon(Icons.calendar_today, size: 18),
                            label: Text(
                              hasDate
                                  ? 'attendance_filters_change_date'.tr
                                  : 'attendance_filters_select_date'.tr,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
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
