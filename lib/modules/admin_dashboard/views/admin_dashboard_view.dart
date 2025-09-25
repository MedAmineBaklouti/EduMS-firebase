// modules/admin/views/admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/widgets/dashboard_card.dart';
import '../../../core/widgets/role_dashboard.dart';
import '../controllers/admin_controller.dart';
import '../../../app/routes/app_pages.dart';

class AdminDashboard extends StatelessWidget {
  final AdminController _controller = Get.find();

  @override
  Widget build(BuildContext context) {
    return RoleDashboard(
      roleName: 'Admin',
      onLogout: _controller.logout,
      cards: [
        DashboardCard(
          icon: Icons.announcement,
          title: 'Announcements',
          subtitle: 'School notices',
          color: Colors.purple,
          onTap: () => Get.toNamed(AppPages.ADMIN_ANNOUNCEMENTS),
        ),
        DashboardCard(
          icon: Icons.school,
          title: 'Courses',
          subtitle: 'Manage curriculum',
          color: Colors.blue,
          onTap: () => Get.toNamed(AppPages.ADMIN_COURSES),
        ),
        DashboardCard(
          icon: Icons.assignment,
          title: 'Homework',
          subtitle: 'Assignments & tasks',
          color: Colors.green,
          onTap: () => Get.toNamed(AppPages.ADMIN_HOMEWORK),
        ),
        DashboardCard(
          icon: Icons.calendar_today,
          title: 'Student Attendance',
          subtitle: 'Track classroom presence',
          color: Colors.orange,
          onTap: () => Get.toNamed(AppPages.ADMIN_ATTENDANCE),
        ),
        DashboardCard(
          icon: Icons.fact_check_outlined,
          title: 'Teacher Attendance',
          subtitle: 'Monitor staff check-ins',
          color: Colors.deepOrange,
          onTap: () => Get.toNamed(AppPages.ADMIN_TEACHER_ATTENDANCE),
        ),
        DashboardCard(
          icon: Icons.emoji_people,
          title: 'Behavior',
          subtitle: 'Student conduct',
          color: Colors.red,
          onTap: () => Get.toNamed(AppPages.ADMIN_BEHAVIOR),
        ),
        DashboardCard(
          icon: Icons.directions_bus,
          title: 'Pickup',
          subtitle: 'Transportation logistics',
          color: Colors.indigo,
          onTap: () => Get.toNamed(AppPages.ADMIN_PICKUP),
        ),
        DashboardCard(
          icon: Icons.archive_outlined,
          title: 'Archived Pickups',
          subtitle: 'Review completed releases',
          color: Colors.teal,
          onTap: () => Get.toNamed(AppPages.ADMIN_PICKUP_ARCHIVE),
        ),
        DashboardCard(
          icon: Icons.settings,
          title: 'Control',
          subtitle: 'Manage data',
          color: Colors.grey,
          onTap: () => Get.toNamed(AppPages.ADMIN_CONTROL),
        ),
      ],
    );
  }
}