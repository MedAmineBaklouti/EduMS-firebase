import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../data/models/attendance_record_model.dart';
import '../../../data/models/school_class_model.dart';
import '../../common/widgets/module_card.dart';
import '../../common/widgets/module_empty_state.dart';
import '../../common/widgets/module_page_container.dart';
import '../controllers/teacher_attendance_controller.dart';

class TeacherAttendanceView extends GetView<TeacherAttendanceController> {
  const TeacherAttendanceView({super.key});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMMd();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        centerTitle: true,
        leading: Obx(() {
          final selectedClass = controller.selectedClass.value;
          if (selectedClass == null) {
            return IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Get.back<void>(),
            );
          }
          return IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: controller.returnToClassList,
          );
        }),
        actions: [
          Obx(() {
            final selectedClass = controller.selectedClass.value;
            if (selectedClass == null) {
              return const SizedBox.shrink();
            }
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
            final selectedClass = controller.selectedClass.value;
            if (selectedClass == null) {
              return const SizedBox.shrink();
            }
            final isSaving = controller.isSaving.value;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TextButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        final success = await controller.submitAttendance();
                        if (success) {
                          Get.snackbar(
                            'Attendance saved',
                            'The attendance list has been stored.',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                          controller.returnToClassList();
                        }
                      },
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
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          final selectedClass = controller.selectedClass.value;
          if (selectedClass == null) {
            return _TeacherClassList(dateFormat: dateFormat);
          }
          return _TeacherClassDetail(
            classModel: selectedClass,
            dateFormat: dateFormat,
          );
        }),
      ),
    );
  }
}

class _TeacherClassList extends StatelessWidget {
  const _TeacherClassList({required this.dateFormat});

  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TeacherAttendanceController>();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(() {
          final selectedDate = controller.selectedDate.value;
          final now = DateTime.now();
          final isToday = DateUtils.isSameDay(selectedDate, now);
          final dateLabel = dateFormat.format(selectedDate);
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: ModuleCard(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
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
                              dateLabel,
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
                              onPressed: () =>
                                  controller.setDate(DateTime.now()),
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Clear date'),
                            ),
                          TextButton.icon(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(selectedDate.year - 1),
                                lastDate: DateTime(selectedDate.year + 1),
                              );
                              if (picked != null) {
                                controller.setDate(picked);
                              }
                            },
                            icon: const Icon(Icons.calendar_today, size: 18),
                            label: Text(isToday ? 'Select date' : 'Change date'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Choose a date to review and mark attendance for your classes.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        Expanded(
          child: Obx(() {
            final classes = controller.classes;
            final selectedDate = controller.selectedDate.value;
            if (classes.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 120, 16, 160),
                children: const [
                  ModuleEmptyState(
                    icon: Icons.class_outlined,
                    title: 'No classes assigned',
                    message:
                        'Once your classes are assigned, they will appear here.',
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: classes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final schoolClass = classes[index];
                final session = controller.sessionForClassOnDate(
                  schoolClass.id,
                  selectedDate,
                );
                final hasSession = session != null;
                final childCount = controller.childCountForClass(schoolClass.id);
                final presentCount = session == null
                    ? 0
                    : session.records
                        .where((record) =>
                            record.status == AttendanceStatus.present)
                        .length;
                final statusColor = hasSession ? Colors.green : Colors.orange;
                final statusLabel = hasSession
                    ? '$presentCount/${session!.records.length} present'
                    : 'Awaiting submission';
                return ModuleCard(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
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
                                  schoolClass.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$childCount student${childCount == 1 ? '' : 's'}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _StatusPill(label: statusLabel, color: statusColor),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        hasSession
                            ? 'Submitted on ${dateFormat.format(session!.date)}.'
                            : 'No submission recorded for ${dateFormat.format(selectedDate)}.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton.icon(
                            onPressed: () => controller.selectClass(schoolClass),
                            icon: Icon(
                              hasSession
                                  ? Icons.visibility_outlined
                                  : Icons.fact_check_outlined,
                              size: 18,
                            ),
                            label: Text(
                              hasSession
                                  ? 'Review attendance'
                                  : 'Take attendance',
                            ),
                          ),
                          if (hasSession)
                            Obx(() {
                              final isExporting = controller.isExporting.value;
                              return OutlinedButton.icon(
                                onPressed: isExporting
                                    ? null
                                    : () => controller.exportAttendanceAsPdf(
                                          session: session,
                                        ),
                                icon: isExporting
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.picture_as_pdf_outlined,
                                        size: 18,
                                      ),
                                label: Text(
                                  isExporting
                                      ? 'Preparing...'
                                      : 'Export PDF',
                                ),
                              );
                            }),
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
    );
  }
}

class _TeacherClassDetail extends StatelessWidget {
  const _TeacherClassDetail({
    required this.classModel,
    required this.dateFormat,
  });

  final SchoolClassModel classModel;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TeacherAttendanceController>();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(() {
          final selectedDate = controller.selectedDate.value;
          final entries = controller.currentEntries;
          final presentCount = entries
              .where((entry) => entry.status == AttendanceStatus.present)
              .length;
          final total = entries.length;
          return ModuleCard(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        classModel.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(selectedDate.year - 1),
                          lastDate: DateTime(selectedDate.year + 1),
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
                const SizedBox(height: 6),
                Text(
                  dateFormat.format(selectedDate),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  total == 0
                      ? 'No students registered for this class.'
                      : '$presentCount of $total student${total == 1 ? '' : 's'} marked present.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Use the switches below to mark each student present or absent before saving.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 12),
        Expanded(
          child: Obx(() {
            final entries = controller.currentEntries;
            if (entries.isEmpty) {
              final hasChildren =
                  controller.childrenForClass(classModel.id).isNotEmpty;
              return ModuleCard(
                child: SizedBox.expand(
                  child: Center(
                    child: hasChildren
                        ? const ModuleEmptyState(
                            icon: Icons.event_busy_outlined,
                            title: 'No attendance records',
                            message:
                                'There are no attendance records for the selected day.',
                          )
                        : const ModuleEmptyState(
                            icon: Icons.people_outline,
                            title: 'No students registered',
                            message:
                                'There are no students assigned to this class yet.',
                          ),
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final entry = entries[index];
                return _AttendanceEntryTile(
                  entry: entry,
                  onToggle: () => controller.toggleStatus(entry.childId),
                );
              },
            );
          }),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AttendanceEntryTile extends StatelessWidget {
  const _AttendanceEntryTile({required this.entry, required this.onToggle});

  final ChildAttendanceEntry entry;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPresent = entry.status == AttendanceStatus.present;
    final statusColor = isPresent ? Colors.green : theme.colorScheme.error;
    return ModuleCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.childName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      isPresent ? Icons.check_circle : Icons.cancel_outlined,
                      color: statusColor,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isPresent ? 'Present' : 'Absent',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisSize: MainAxisSize.min,
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
    );
  }
}

