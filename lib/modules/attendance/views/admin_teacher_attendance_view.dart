import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../models/attendance_record_model.dart';
import '../../../common/widgets/module_card.dart';
import '../../../common/widgets/module_empty_state.dart';
import '../../../common/widgets/module_page_container.dart';
import '../controllers/admin_teacher_attendance_controller.dart';
import 'widgets/attendance_date_card.dart';

class AdminTeacherAttendanceView
    extends GetView<AdminTeacherAttendanceController> {
  const AdminTeacherAttendanceView({super.key});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMMd();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        title: const Text('Teacher Attendance'),
        centerTitle: true,
        actions: [
          Obx(() {
            final isSaving = controller.isSaving.value;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
                onPressed: isSaving ? null : () => controller.saveAttendance(),
                child: isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            );
          }),
        ],
      ),
      body: ModulePageContainer(
        child: Column(
          children: [
            const _AdminTeacherAttendanceFilters(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: _AttendanceHeader(dateFormat: dateFormat),
            ),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                final entries = controller.currentEntries;
                return RefreshIndicator(
                  onRefresh: controller.refreshData,
                  child: entries.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 120, 16, 160),
                          children: const [
                            ModuleEmptyState(
                              icon: Icons.person_outline,
                              title: 'No teacher attendance records',
                              message:
                                  'Adjust the filters above to review attendance for specific classes or subjects.',
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          itemCount: entries.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final entry = entries[index];
                            final subjectLabel =
                                controller.subjectLabelForTeacher(entry.teacherId);
                            final classesLabel =
                                controller.classNamesForTeacher(entry.teacherId);
                            return _TeacherAttendanceTile(
                              entry: entry,
                              subjectLabel: subjectLabel,
                              classNames: classesLabel,
                              onStatusChanged: (status) =>
                                  controller.updateStatus(entry.teacherId, status),
                            );
                          },
                        ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Obx(() {
                final isExporting = controller.isExporting.value;
                final hasEntries = controller.currentEntries.isNotEmpty;
                final theme = Theme.of(context);
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isExporting || !hasEntries
                        ? null
                        : () => controller.exportAttendanceAsPdf(),
                    icon: isExporting
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.onPrimary,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.picture_as_pdf_outlined,
                            color: theme.colorScheme.onPrimary,
                          ),
                    label: Text(
                      isExporting ? 'Preparing PDF...' : 'Download as PDF',
                    ),
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

class _AttendanceHeader extends StatelessWidget {
  const _AttendanceHeader({required this.dateFormat});

  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminTeacherAttendanceController>();
    final theme = Theme.of(context);
    return Obx(() {
      final date = controller.selectedDate.value;
      final entries = controller.currentEntries;
      final presentCount = entries
          .where((entry) => entry.status == AttendanceStatus.present)
          .length;
      final absentCount = entries
          .where((entry) => entry.status == AttendanceStatus.absent)
          .length;
      final pendingCount = entries
          .where((entry) => entry.status == AttendanceStatus.pending)
          .length;
      final total = entries.length;
      final dateLabel = dateFormat.format(date);
      final now = DateTime.now();
      final isToday = DateUtils.isSameDay(date, now);
      final overviewLabel = total == 0
          ? 'Teacher attendance'
          : '$total teacher${total == 1 ? '' : 's'} tracked';
      final statusMessage = total == 0
          ? 'No teachers are scheduled for this day.'
          : pendingCount > 0
              ? 'Awaiting submission – mark ${pendingCount == 1 ? 'the remaining teacher' : '$pendingCount teachers'} before saving.'
              : 'Ready to save – $presentCount present and $absentCount absent.';
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
                        '$overviewLabel • $dateLabel',
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
                    if (!isToday)
                      OutlinedButton.icon(
                        onPressed: () => controller.setDate(
                          DateTime(now.year, now.month, now.day),
                        ),
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Clear date'),
                      ),
                    TextButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: date,
                          firstDate: DateTime(date.year - 1),
                          lastDate: DateTime(date.year + 1),
                        );
                        if (picked != null) {
                          controller.setDate(picked);
                        }
                      },
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: const Text('Change date'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              statusMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (total > 0) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (presentCount > 0)
                    _AttendanceStatusChip(
                      icon: Icons.check_circle,
                      backgroundColor: Colors.green.shade50,
                      iconColor: Colors.green.shade600,
                      label: '$presentCount present',
                    ),
                  if (absentCount > 0)
                    _AttendanceStatusChip(
                      icon: Icons.cancel_outlined,
                      backgroundColor:
                          theme.colorScheme.error.withOpacity(0.12),
                      iconColor: theme.colorScheme.error,
                      label: '$absentCount absent',
                    ),
                  if (pendingCount > 0)
                    _AttendanceStatusChip(
                      icon: Icons.hourglass_empty,
                      backgroundColor:
                          theme.colorScheme.primary.withOpacity(0.12),
                      iconColor: theme.colorScheme.primary,
                      label: '$pendingCount pending',
                    ),
                ],
              ),
            ],
          ],
        ),
      );
    });
  }
}

class _AdminTeacherAttendanceFilters extends StatelessWidget {
  const _AdminTeacherAttendanceFilters();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.find<AdminTeacherAttendanceController>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() {
            final hasFilters =
                (controller.classFilter.value ?? '').isNotEmpty ||
                    (controller.subjectFilter.value ?? '').isNotEmpty;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter teachers',
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
              final className = controller.className(classId) ?? 'Class';
              chips.add(
                _FilterChip(
                  label: 'Class: $className',
                  onRemoved: () => controller.setClassFilter(null),
                ),
              );
            }
            final subjectId = controller.subjectFilter.value;
            if (subjectId != null && subjectId.isNotEmpty) {
              final subjectName = controller.subjectName(subjectId) ?? 'Subject';
              chips.add(
                _FilterChip(
                  label: 'Subject: $subjectName',
                  onRemoved: () => controller.setSubjectFilter(null),
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
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: fieldWidth,
                    child: Obx(() {
                      final classes = controller.classes;
                      final selected = controller.classFilter.value;
                      return DropdownButtonFormField<String?>(
                        value: selected,
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
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: Obx(() {
                      final subjects = controller.subjects;
                      final selected = controller.subjectFilter.value;
                      return DropdownButtonFormField<String?>(
                        value: selected,
                        decoration: const InputDecoration(
                          labelText: 'Subject',
                          border: OutlineInputBorder(),
                        ),
                        hint: const Text('All subjects'),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All subjects'),
                          ),
                          ...subjects.map(
                            (item) => DropdownMenuItem<String?>(
                              value: item.id,
                              child: Text(item.name),
                            ),
                          ),
                        ],
                        onChanged: controller.setSubjectFilter,
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
  }
}

class _TeacherAttendanceTile extends StatelessWidget {
  const _TeacherAttendanceTile({
    required this.entry,
    required this.subjectLabel,
    required this.classNames,
    required this.onStatusChanged,
  });

  final TeacherAttendanceRecord entry;
  final String subjectLabel;
  final List<String> classNames;
  final ValueChanged<AttendanceStatus> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = entry.status;
    final isPresent = status == AttendanceStatus.present;
    final isAbsent = status == AttendanceStatus.absent;
    final isPending = status == AttendanceStatus.pending;
    Color statusColor;
    IconData statusIcon;
    String statusText;
    if (isPresent) {
      statusColor = Colors.green.shade600;
      statusIcon = Icons.check_circle;
      statusText = 'Marked present';
    } else if (isAbsent) {
      statusColor = theme.colorScheme.error;
      statusIcon = Icons.cancel_outlined;
      statusText = 'Marked absent';
    } else {
      statusColor = theme.colorScheme.primary;
      statusIcon = Icons.hourglass_empty;
      statusText = 'Awaiting submission';
    }
    final classesLabel = classNames.isEmpty
        ? 'No class assigned'
        : classNames.join(', ');
    final avatarText = entry.teacherName.isNotEmpty
        ? entry.teacherName[0].toUpperCase()
        : '?';
    return ModuleCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
                      entry.teacherName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.book_outlined, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            subjectLabel,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      classesLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              _AttendanceToggle(
                status: status,
                onChanged: onStatusChanged,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, color: statusColor, size: 18),
                const SizedBox(width: 6),
                Text(
                  statusText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.onRemoved});

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

class _AttendanceToggle extends StatelessWidget {
  const _AttendanceToggle({
    required this.status,
    required this.onChanged,
  });

  final AttendanceStatus status;
  final ValueChanged<AttendanceStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPresent = status == AttendanceStatus.present;
    final isAbsent = status == AttendanceStatus.absent;
    final isPending = status == AttendanceStatus.pending;
    Color labelColor;
    String labelText;
    if (isPresent) {
      labelColor = Colors.green.shade600;
      labelText = 'Present';
    } else if (isAbsent) {
      labelColor = theme.colorScheme.error;
      labelText = 'Absent';
    } else {
      labelColor = theme.colorScheme.primary;
      labelText = 'Awaiting submission';
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Switch.adaptive(
          value: isPresent,
          onChanged: (value) => onChanged(
            value ? AttendanceStatus.present : AttendanceStatus.absent,
          ),
          activeColor: Colors.green.shade600,
          activeTrackColor: Colors.green.shade200,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        const SizedBox(height: 4),
        Text(
          labelText,
          style: theme.textTheme.labelSmall?.copyWith(
            color: labelColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (!isPending)
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurfaceVariant,
            ),
            onPressed: () => onChanged(AttendanceStatus.pending),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Mark pending'),
          ),
      ],
    );
  }
}

class _AttendanceStatusChip extends StatelessWidget {
  const _AttendanceStatusChip({
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.label,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
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
