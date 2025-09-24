import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../data/models/attendance_record_model.dart';
import '../../common/widgets/module_card.dart';
import '../../common/widgets/module_empty_state.dart';
import '../../common/widgets/module_page_container.dart';
import '../controllers/admin_teacher_attendance_controller.dart';

class AdminTeacherAttendanceView
    extends GetView<AdminTeacherAttendanceController> {
  const AdminTeacherAttendanceView({super.key});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMMd();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Attendance'),
        centerTitle: true,
        actions: [
          Obx(() {
            final isExporting = controller.isExporting.value;
            return IconButton(
              tooltip: 'Download PDF',
              onPressed:
                  isExporting ? null : () => controller.exportAttendanceAsPdf(),
              icon: isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf_outlined),
            );
          }),
          Obx(() {
            final isSaving = controller.isSaving.value;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TextButton(
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
            _AttendanceHeader(dateFormat: dateFormat),
            const SizedBox(height: 12),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                final entries = controller.currentEntries;
                if (entries.isEmpty) {
                  return ListView(
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
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
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
                      onToggle: () => controller.toggleStatus(entry.teacherId),
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
      final total = entries.length;
      return ModuleCard(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Attendance for ${dateFormat.format(date)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
            const SizedBox(height: 12),
            Text(
              total == 0
                  ? 'No teachers to mark on this day.'
                  : '$presentCount of $total teacher${total == 1 ? '' : 's'} marked present.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Toggle the switch next to each teacher to mark them present or absent before saving.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
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
    required this.onToggle,
  });

  final TeacherAttendanceRecord entry;
  final String subjectLabel;
  final List<String> classNames;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPresent = entry.status == AttendanceStatus.present;
    final statusColor =
        isPresent ? Colors.green.shade600 : theme.colorScheme.error;
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
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Switch.adaptive(
                    value: isPresent,
                    onChanged: (_) => onToggle(),
                    activeColor: Colors.green,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isPresent ? 'Present' : 'Absent',
                    style: theme.textTheme.labelSmall,
                  ),
                ],
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
                Icon(
                  isPresent ? Icons.check_circle : Icons.cancel_outlined,
                  color: statusColor,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  isPresent ? 'Marked present' : 'Marked absent',
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
