import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../data/models/attendance_record_model.dart';
import '../../../data/models/school_class_model.dart';
import '../controllers/teacher_attendance_controller.dart';

class TeacherAttendanceView extends GetView<TeacherAttendanceController> {
  const TeacherAttendanceView({super.key});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMMd();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
      ),
      body: Obx(() {
        final classes = controller.classes;
        final selectedClass = controller.selectedClass.value;
        final selectedDate = controller.selectedDate.value;
        final entries = controller.currentEntries;
        final isSaving = controller.isSaving.value;
        final isExporting = controller.isExporting.value;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<SchoolClassModel?>(
                    value: selectedClass,
                    decoration: const InputDecoration(
                      labelText: 'Class',
                      border: OutlineInputBorder(),
                    ),
                    items: classes
                        .map(
                          (item) => DropdownMenuItem<SchoolClassModel?>(
                            value: item,
                            child: Text(item.name),
                          ),
                        )
                        .toList(),
                    onChanged: controller.selectClass,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
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
                          icon: const Icon(Icons.calendar_today),
                          label: Text(dateFormat.format(selectedDate)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                final success =
                                    await controller.submitAttendance();
                                if (success) {
                                  Get.snackbar(
                                    'Attendance saved',
                                    'The attendance list has been stored.',
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                }
                              },
                        child: Text(isSaving ? 'Saving...' : 'Save'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: isExporting
                            ? null
                            : () async {
                                await controller.exportAttendanceAsPdf();
                              },
                        child: Text(isExporting ? 'Exporting...' : 'Export PDF'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: entries.isEmpty
                  ? Center(
                      child: Text(
                        selectedClass == null
                            ? 'Select a class to begin.'
                            : 'No students registered for this class.',
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: entries.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return ListTile(
                          title: Text(entry.childName),
                          trailing: _AttendanceStatusChip(entry: entry),
                          onTap: () => controller.toggleStatus(entry.childId),
                        );
                      },
                    ),
            ),
            const Divider(),
            SizedBox(
              height: 200,
              child: Obx(() {
                final sessions = controller.sessions;
                if (sessions.isEmpty) {
                  return const Center(
                    child: Text('No previous attendance submissions.'),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: sessions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    return ListTile(
                      title: Text(DateFormat.yMMMMd().format(session.date)),
                      subtitle: Text(
                        '${session.records.where((r) => r.status == AttendanceStatus.present).length} present / '
                        '${session.records.length} total',
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        );
      }),
    );
  }
}

class _AttendanceStatusChip extends StatelessWidget {
  const _AttendanceStatusChip({required this.entry});

  final ChildAttendanceEntry entry;

  @override
  Widget build(BuildContext context) {
    final isPresent = entry.status == AttendanceStatus.present;
    return Chip(
      label: Text(isPresent ? 'Present' : 'Absent'),
      backgroundColor: isPresent ? Colors.green.shade100 : Colors.red.shade100,
    );
  }
}
