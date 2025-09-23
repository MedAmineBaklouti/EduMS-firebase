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
      ),
      body: ModulePageContainer(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          final classes = controller.classes;
          final selectedClass = controller.selectedClass.value;
          final selectedDate = controller.selectedDate.value;
          final entries = controller.currentEntries;
          final isSaving = controller.isSaving.value;
          final isExporting = controller.isExporting.value;
          return Column(
            children: [
              _TeacherAttendanceFilters(
                classes: classes,
                selectedClass: selectedClass,
                selectedDate: selectedDate,
                onClassChanged: controller.selectClass,
                onDateChanged: controller.setDate,
                onSave: isSaving
                    ? null
                    : () async {
                        final success = await controller.submitAttendance();
                        if (success) {
                          Get.snackbar(
                            'Attendance saved',
                            'The attendance list has been stored.',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        }
                      },
                onExport: isExporting
                    ? null
                    : () async {
                        await controller.exportAttendanceAsPdf();
                      },
                isSaving: isSaving,
                isExporting: isExporting,
                dateFormat: dateFormat,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: entries.isEmpty
                    ? ModuleCard(
                        child: SizedBox.expand(
                          child: Center(
                            child: selectedClass == null
                                ? const ModuleEmptyState(
                                    icon: Icons.class_outlined,
                                    title: 'Select a class to begin',
                                    message:
                                        'Choose a class to load the roster and take attendance.',
                                  )
                                : const ModuleEmptyState(
                                    icon: Icons.people_outline,
                                    title: 'No students registered',
                                    message:
                                        'There are no students assigned to this class yet.',
                                  ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        itemCount: entries.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          return _AttendanceEntryCard(
                            entry: entry,
                            onTap: () => controller.toggleStatus(entry.childId),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 12),
              _PreviousSessionsCard(sessions: controller.sessions),
            ],
          );
        }),
      ),
    );
  }
}

class _TeacherAttendanceFilters extends StatelessWidget {
  const _TeacherAttendanceFilters({
    required this.classes,
    required this.selectedClass,
    required this.selectedDate,
    required this.onClassChanged,
    required this.onDateChanged,
    required this.onSave,
    required this.onExport,
    required this.isSaving,
    required this.isExporting,
    required this.dateFormat,
  });

  final List<SchoolClassModel> classes;
  final SchoolClassModel? selectedClass;
  final DateTime selectedDate;
  final ValueChanged<SchoolClassModel?> onClassChanged;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback? onSave;
  final VoidCallback? onExport;
  final bool isSaving;
  final bool isExporting;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Attendance tools',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: onExport,
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                    label:
                        Text(isExporting ? 'Exporting...' : 'Export PDF'),
                  ),
                  ElevatedButton.icon(
                    onPressed: onSave,
                    icon: const Icon(Icons.save_outlined, size: 18),
                    label: Text(isSaving ? 'Saving...' : 'Save'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 720;
              final fieldWidth = isWide
                  ? constraints.maxWidth / 2 - 8
                  : double.infinity;
              final dropdownItems = classes.isEmpty
                  ? <DropdownMenuItem<SchoolClassModel?>>[
                      const DropdownMenuItem<SchoolClassModel?>(
                        value: null,
                        enabled: false,
                        child: Text('No classes available'),
                      ),
                    ]
                  : classes
                      .map(
                        (item) => DropdownMenuItem<SchoolClassModel?>(
                          value: item,
                          child: Text(item.name),
                        ),
                      )
                      .toList();
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: fieldWidth,
                    child: DropdownButtonFormField<SchoolClassModel?>(
                      value: classes.isEmpty ? null : selectedClass,
                      decoration: const InputDecoration(
                        labelText: 'Class',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Select a class'),
                      items: dropdownItems,
                      onChanged: classes.isEmpty ? null : onClassChanged,
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: _DateSelector(
                      label: 'Date',
                      value: dateFormat.format(selectedDate),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(selectedDate.year - 1),
                          lastDate: DateTime(selectedDate.year + 1),
                        );
                        if (picked != null) {
                          onDateChanged(picked);
                        }
                      },
                    ),
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

class _AttendanceEntryCard extends StatelessWidget {
  const _AttendanceEntryCard({required this.entry, required this.onTap});

  final ChildAttendanceEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPresent = entry.status == AttendanceStatus.present;
    final statusColor = isPresent ? Colors.green : theme.colorScheme.error;
    return ModuleCard(
      onTap: onTap,
      child: Row(
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
                const SizedBox(height: 4),
                Text(
                  'Tap to toggle status',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isPresent ? 'Present' : 'Absent',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today, size: 18),
        ),
        isEmpty: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            value,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }
}

class _PreviousSessionsCard extends StatelessWidget {
  const _PreviousSessionsCard({required this.sessions});

  final List<AttendanceSessionModel> sessions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: ModuleCard(
        child: sessions.isEmpty
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Recent submissions'),
                  SizedBox(height: 8),
                  Text('No previous attendance submissions.'),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent submissions',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...sessions.take(4).map((session) {
                    final presentCount = session.records
                        .where((record) => record.status == AttendanceStatus.present)
                        .length;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.event_available_outlined,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat.yMMMMd().format(session.date),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${presentCount}/${session.records.length} present',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (sessions.length > 4)
                    Text(
                      '+${sessions.length - 4} more',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
