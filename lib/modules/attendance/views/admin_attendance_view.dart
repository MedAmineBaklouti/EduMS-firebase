import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../data/models/attendance_record_model.dart';
import '../controllers/admin_attendance_controller.dart';

class AdminAttendanceView extends GetView<AdminAttendanceController> {
  const AdminAttendanceView({super.key});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMMd();
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Attendance Monitoring'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Children'),
              Tab(text: 'Teachers'),
            ],
          ),
        ),
        body: Column(
          children: [
            const _AdminAttendanceFilters(),
            Expanded(
              child: TabBarView(
                children: [
                  Obx(() {
                    final sessions = controller.classSessions;
                    if (sessions.isEmpty) {
                      return const Center(
                        child:
                            Text('No child attendance records match the filters.'),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: sessions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final session = sessions[index];
                        final presentCount = session.records
                            .where((record) =>
                                record.status == AttendanceStatus.present)
                            .length;
                        return Card(
                          child: ListTile(
                            title: Text(
                              '${session.className} • ${session.teacherName}',
                            ),
                            subtitle: Text(dateFormat.format(session.date)),
                            trailing: Text(
                              '$presentCount/${session.records.length} present',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      },
                    );
                  }),
                  Obx(() {
                    final records = controller.teacherRecords;
                    if (records.isEmpty) {
                      return const Center(
                        child: Text('No teacher attendance records to display.'),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: records.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final record = records[index];
                        return Card(
                          child: ListTile(
                            title: Text(record.teacherName),
                            subtitle: Text(dateFormat.format(record.date)),
                            trailing: Text(
                              record.status == AttendanceStatus.present
                                  ? 'Present'
                                  : 'Absent',
                              style: TextStyle(
                                color: record.status == AttendanceStatus.present
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ],
              ),
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
    final controller = Get.find<AdminAttendanceController>();
    final dateFormat = DateFormat.yMMMMd();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Obx(() {
        final classes = controller.classes;
        final teachers = controller.teachers;
        final classFilter = controller.classFilter.value;
        final teacherFilter = controller.teacherFilter.value;
        final dateFilter = controller.dateFilter.value;
        return Wrap(
          runSpacing: 12,
          spacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<String?>(
                value: classFilter,
                decoration: const InputDecoration(
                  labelText: 'Class',
                  border: OutlineInputBorder(),
                ),
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
              ),
            ),
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<String?>(
                value: teacherFilter,
                decoration: const InputDecoration(
                  labelText: 'Teacher',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All teachers'),
                  ),
                  ...teachers.map(
                    (item) => DropdownMenuItem<String?>(
                      value: item.id,
                      child: Text(item.name),
                    ),
                  ),
                ],
                onChanged: controller.setTeacherFilter,
              ),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: dateFilter ?? now,
                  firstDate: DateTime(now.year - 1),
                  lastDate: DateTime(now.year + 1),
                );
                controller.setDateFilter(picked);
              },
              icon: const Icon(Icons.calendar_today),
              label: Text(
                dateFilter == null
                    ? 'Any date'
                    : dateFormat.format(dateFilter),
              ),
            ),
            if (dateFilter != null)
              IconButton(
                onPressed: () => controller.setDateFilter(null),
                tooltip: 'Clear date filter',
                icon: const Icon(Icons.clear),
              ),
          ],
        );
      }),
    );
  }
}
