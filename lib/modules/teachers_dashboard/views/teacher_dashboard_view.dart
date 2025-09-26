// modules/teacher/views/teacher_dashboard.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/widgets/dashboard_card.dart';
import '../../../core/widgets/role_dashboard.dart';
import '../../../app/routes/app_pages.dart';
import '../controllers/teacher_controller.dart';

class TeacherDashboard extends StatelessWidget {
  final TeacherController _controller = Get.find();

  @override
  Widget build(BuildContext context) {
    return RoleDashboard(
      roleName: 'Teacher',
      onLogout: _controller.logout,
      cards: [
        DashboardCard(
          icon: Icons.message,
          title: 'Messages',
          subtitle: 'Chat with families',
          color: Colors.cyan,
          onTap: () => Get.toNamed(AppPages.MESSAGING),
        ),
        DashboardCard(
          icon: Icons.menu_book,
          title: 'Courses',
          subtitle: 'Create and share lessons',
          color: Colors.teal,
          onTap: () => Get.toNamed(AppPages.TEACHER_COURSES),
        ),
        DashboardCard(
          icon: Icons.assignment,
          title: 'Homework',
          subtitle: 'Assign tasks',
          color: Colors.green,
          onTap: () => Get.toNamed(AppPages.TEACHER_HOMEWORK),
        ),
        DashboardCard(
          icon: Icons.calendar_today,
          title: 'Attendance',
          subtitle: 'Record presence',
          color: Colors.orange,
          onTap: () => Get.toNamed(AppPages.TEACHER_ATTENDANCE),
        ),
        DashboardCard(
          icon: Icons.emoji_people,
          title: 'Behavior',
          subtitle: 'Student reports',
          color: Colors.red,
          onTap: () => Get.toNamed(AppPages.TEACHER_BEHAVIOR),
        ),
        DashboardCard(
          icon: Icons.announcement,
          title: 'Announcements',
          subtitle: 'Class notices',
          color: Colors.purple,
          onTap: () => Get.toNamed(AppPages.TEACHER_ANNOUNCEMENTS),
        ),
        DashboardCard(
          icon: Icons.directions_bus,
          title: 'Pickup',
          subtitle: 'Parent coordination',
          color: Colors.indigo,
          onTap: () => Get.toNamed(AppPages.TEACHER_PICKUP),
        ),
      ],
    );
  }
}