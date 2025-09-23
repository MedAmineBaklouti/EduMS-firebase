import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../data/models/attendance_record_model.dart';
import '../../common/widgets/module_card.dart';
import '../../common/widgets/module_empty_state.dart';
import '../../common/widgets/module_page_container.dart';
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
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Children'),
              Tab(text: 'Teachers'),
            ],
          ),
        ),
        body: ModulePageContainer(
          child: Column(
            children: [
              const _AdminAttendanceFilters(),
              Expanded(
                child: TabBarView(
                  children: [
                    Obx(() {
                      final sessions = controller.classSessions;
                      if (sessions.isEmpty) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 120, 16, 160),
                          children: const [
                            ModuleEmptyState(
                              icon: Icons.school_outlined,
                              title: 'No child attendance records',
                              message:
                                  'Adjust the filters above to review attendance submissions for specific classes.',
                            ),
                          ],
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                        physics: const BouncingScrollPhysics(),
                        itemCount: sessions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final session = sessions[index];
                          final presentCount = session.records
                              .where((record) => record.status == AttendanceStatus.present)
                              .length;
                          return ModuleCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${session.className} • ${session.teacherName}',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  dateFormat.format(session.date),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '$presentCount/${session.records.length} present',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    }),
                    Obx(() {
                      final records = controller.teacherRecords;
                      if (records.isEmpty) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 120, 16, 160),
                          children: const [
                            ModuleEmptyState(
                              icon: Icons.person_outline,
                              title: 'No teacher attendance records',
                              message:
                                  'Use the filters above to explore teacher attendance submissions.',
                            ),
                          ],
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                        physics: const BouncingScrollPhysics(),
                        itemCount: records.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final record = records[index];
                          final isPresent = record.status == AttendanceStatus.present;
                          return ModuleCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  record.teacherName,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  dateFormat.format(record.date),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(
                                      isPresent ? Icons.check_circle : Icons.cancel_outlined,
                                      color: isPresent
                                          ? Colors.green
                                          : Theme.of(context).colorScheme.error,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isPresent ? 'Present' : 'Absent',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
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
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Obx(() {
        final classes = controller.classes;
        final teachers = controller.teachers;
        final classFilter = controller.classFilter.value;
        final teacherFilter = controller.teacherFilter.value;
        final dateFilter = controller.dateFilter.value;
        return ModuleCard(
          padding: const EdgeInsets.all(20),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
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
                  dateFilter == null ? 'Any date' : dateFormat.format(dateFilter),
                ),
              ),
              if (dateFilter != null)
                IconButton(
                  onPressed: () => controller.setDateFilter(null),
                  tooltip: 'Clear date filter',
                  icon: const Icon(Icons.clear),
                ),
            ],
          ),
        );
      }),
    );
  }
}
