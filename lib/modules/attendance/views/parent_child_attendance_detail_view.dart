import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:edums/core/widgets/module_page_container.dart';
import '../controllers/parent_attendance_controller.dart';
import '../models/child_attendance_summary.dart';
import 'widgets/child_attendance_detail_content.dart';

class ParentChildAttendanceDetailView extends StatelessWidget {
  const ParentChildAttendanceDetailView({super.key, required this.summary});

  final ChildAttendanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ParentAttendanceController>();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        title: const Text('Attendance Detail'),
        centerTitle: true,
      ),
      body: ModulePageContainer(
        child: Obx(() {
          final isExporting =
              controller.exportingChildId.value == summary.childId;
          return ChildAttendanceDetailContent(
            summary: summary,
            isExporting: isExporting,
            onDownload: () =>
                controller.exportChildAttendanceAsPdf(summary),
          );
        }),
      ),
    );
  }
}
