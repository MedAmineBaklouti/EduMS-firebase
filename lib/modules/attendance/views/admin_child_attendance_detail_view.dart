import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/attendance_record_model.dart';
import '../../common/widgets/module_card.dart';
import '../../common/widgets/module_page_container.dart';
import '../controllers/admin_attendance_controller.dart';

class AdminChildAttendanceDetailView extends StatelessWidget {
  const AdminChildAttendanceDetailView({super.key, required this.summary});

  final ChildAttendanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat.yMMMd();
    final pendingCount = summary.pendingCount;
    final absentCount = summary.absentCount;
    final presentCount = summary.presentCount;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Attendance'),
        centerTitle: true,
      ),
      body: ModulePageContainer(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
          children: [
            ModuleCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor:
                            theme.colorScheme.primary.withOpacity(0.12),
                        child: Text(
                          summary.childName.isNotEmpty
                              ? summary.childName[0].toUpperCase()
                              : '?',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              summary.childName,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              summary.className,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${summary.totalSubjects} subject${summary.totalSubjects == 1 ? '' : 's'} tracked',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      if (presentCount > 0)
                        _DetailSummaryChip(
                          icon: Icons.check_circle,
                          label: '$presentCount present',
                          backgroundColor: Colors.green.shade50,
                          foregroundColor: Colors.green.shade600,
                        ),
                      if (absentCount > 0)
                        _DetailSummaryChip(
                          icon: Icons.cancel_outlined,
                          label: '$absentCount absent',
                          backgroundColor:
                              theme.colorScheme.error.withOpacity(0.12),
                          foregroundColor: theme.colorScheme.error,
                        ),
                      if (pendingCount > 0)
                        _DetailSummaryChip(
                          icon: Icons.hourglass_empty,
                          label: '$pendingCount pending',
                          backgroundColor:
                              theme.colorScheme.primary.withOpacity(0.12),
                          foregroundColor: theme.colorScheme.primary,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ModuleCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Subject attendance',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(summary.subjectEntries.length, (index) {
                    final entry = summary.subjectEntries[index];
                    final isPending = !entry.isSubmitted || entry.status == null;
                    final status = entry.status;
                    final Color statusColor;
                    final String statusLabel;
                    final IconData statusIcon;
                    if (isPending) {
                      statusColor =
                          theme.colorScheme.onSurfaceVariant.withOpacity(0.8);
                      statusLabel = 'Not submitted yet';
                      statusIcon = Icons.hourglass_bottom;
                    } else if (status == AttendanceStatus.present) {
                      statusColor = Colors.green.shade600;
                      statusLabel = 'Present';
                      statusIcon = Icons.check_circle;
                    } else {
                      statusColor = theme.colorScheme.error;
                      statusLabel = 'Absent';
                      statusIcon = Icons.cancel_outlined;
                    }

                    return Column(
                      children: [
                        if (index != 0) const Divider(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                Icons.book_outlined,
                                color: theme.colorScheme.primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.subjectLabel,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    entry.teacherName,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    dateFormat.format(entry.date),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color:
                                          theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Icon(statusIcon, color: statusColor, size: 22),
                                const SizedBox(height: 6),
                                Text(
                                  statusLabel,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: statusColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
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

class _DetailSummaryChip extends StatelessWidget {
  const _DetailSummaryChip({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: foregroundColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
