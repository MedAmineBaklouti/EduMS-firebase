import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../data/models/attendance_record_model.dart';
import '../controllers/parent_attendance_controller.dart';

class ParentAttendanceView extends GetView<ParentAttendanceController> {
  const ParentAttendanceView({super.key});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMMd();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance History'),
      ),
      body: Column(
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
                return const Center(
                  child: Text('No attendance records available.'),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: sessions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
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
                  return Card(
                    child: ListTile(
                      title: Text(dateFormat.format(session.date)),
                      subtitle: Text(
                        childId == null
                            ? '${session.className} • ${session.teacherName}'
                            : session.className,
                      ),
                      trailing: Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusLabel == 'Present'
                              ? Colors.green
                              : statusLabel == 'Absent'
                                  ? Colors.red
                                  : Colors.blueGrey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: GetBuilder<ParentAttendanceController>(
        builder: (controller) {
          return DropdownButtonFormField<String?>(
            value: controller.childFilter.value,
            decoration: const InputDecoration(
              labelText: 'Child',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('All children'),
              ),
              ...controller.children.map(
                (child) => DropdownMenuItem<String?>(
                  value: child.id,
                  child: Text(child.name),
                ),
              ),
            ],
            onChanged: controller.setChildFilter,
          );
        },
      ),
    );
  }
}
