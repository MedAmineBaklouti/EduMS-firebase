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
          onTap: () => Get.toNamed('/admin/announcements'),
        ),
        DashboardCard(
          icon: Icons.message,
          title: 'Messaging',
          subtitle: 'Communication',
          color: Colors.pink,
          onTap: () => Get.toNamed('/admin/messaging'),
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
          onTap: () => Get.toNamed('/admin/homework'),
        ),
        DashboardCard(
          icon: Icons.calendar_today,
          title: 'Attendance',
          subtitle: 'Student presence',
          color: Colors.orange,
          onTap: () => Get.toNamed('/admin/attendance'),
        ),
        DashboardCard(
          icon: Icons.emoji_people,
          title: 'Behavior',
          subtitle: 'Student conduct',
          color: Colors.red,
          onTap: () => Get.toNamed('/admin/behavior'),
        ),

        DashboardCard(
          icon: Icons.directions_bus,
          title: 'Pickup',
          subtitle: 'Transportation',
          color: Colors.indigo,
          onTap: () => Get.toNamed('/admin/pickup'),
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