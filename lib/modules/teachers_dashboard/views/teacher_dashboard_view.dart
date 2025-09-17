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
          icon: Icons.menu_book,
          title: 'Courses',
          subtitle: 'Create and share lessons',
          color: Colors.teal,
          onTap: () => Get.toNamed(AppPages.TEACHER_COURSES),
        ),
        DashboardCard(
          icon: Icons.school,
          title: 'My Classes',
          subtitle: 'Class management',
          color: Colors.blue,
          onTap: () => Get.toNamed('/teacher/classes'),
        ),
        DashboardCard(
          icon: Icons.assignment,
          title: 'Homework',
          subtitle: 'Assign tasks',
          color: Colors.green,
          onTap: () => Get.toNamed('/teacher/homework'),
        ),
        DashboardCard(
          icon: Icons.calendar_today,
          title: 'Attendance',
          subtitle: 'Record presence',
          color: Colors.orange,
          onTap: () => Get.toNamed('/teacher/attendance'),
        ),
        DashboardCard(
          icon: Icons.emoji_people,
          title: 'Behavior',
          subtitle: 'Student reports',
          color: Colors.red,
          onTap: () => Get.toNamed('/teacher/behavior'),
        ),
        DashboardCard(
          icon: Icons.announcement,
          title: 'Announcements',
          subtitle: 'Class notices',
          color: Colors.purple,
          onTap: () => Get.toNamed('/teacher/announcements'),
        ),
        DashboardCard(
          icon: Icons.message,
          title: 'Messaging',
          subtitle: 'Contact parents',
          color: Colors.pink,
          onTap: () => Get.toNamed('/teacher/messaging'),
        ),
      ],
    );
  }
}