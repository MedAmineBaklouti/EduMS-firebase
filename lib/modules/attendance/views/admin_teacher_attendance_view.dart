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
                        title: 'No teachers available',
                        message:
                            'Teachers will appear here once they are added to the system.',
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
                    return _TeacherAttendanceTile(
                      entry: entry,
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

class _TeacherAttendanceTile extends StatelessWidget {
  const _TeacherAttendanceTile({required this.entry, required this.onToggle});

  final TeacherAttendanceRecord entry;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPresent = entry.status == AttendanceStatus.present;
    final statusColor =
        isPresent ? Colors.green : theme.colorScheme.error.withOpacity(0.9);
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
                  entry.teacherName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
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
          const SizedBox(width: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
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
