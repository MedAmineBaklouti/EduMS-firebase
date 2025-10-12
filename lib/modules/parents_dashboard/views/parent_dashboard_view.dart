// modules/parent/views/parent_dashboard.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/widgets/dashboard_card.dart';
import '../../../core/widgets/role_dashboard.dart';
import '../../../app/routes/app_pages.dart';
import '../controllers/parent_controller.dart';

class ParentDashboard extends StatelessWidget {
  final ParentController _controller = Get.find();

  @override
  Widget build(BuildContext context) {
    return RoleDashboard(
      roleName: 'Parent',
      onLogout: _controller.logout,
      onMessagesTap: () => Get.toNamed(AppPages.MESSAGING),
      announcementAudience: 'parents',
      onShowAllAnnouncements: () => Get.toNamed(AppPages.PARENT_ANNOUNCEMENTS),
      cards: [
        DashboardCard(
          icon: Icons.menu_book,
          title: 'Courses',
          subtitle: 'View class materials',
          color: Colors.teal,
          onTap: () => Get.toNamed(AppPages.PARENT_COURSES),
        ),
        DashboardCard(
          icon: Icons.assignment,
          title: 'Homework',
          subtitle: 'View assignments',
          color: Colors.green,
          onTap: () => Get.toNamed(AppPages.PARENT_HOMEWORK),
        ),
        DashboardCard(
          icon: Icons.calendar_today,
          title: 'Attendance',
          subtitle: 'View records',
          color: Colors.orange,
          onTap: () => Get.toNamed(AppPages.PARENT_ATTENDANCE),
        ),
        DashboardCard(
          icon: Icons.emoji_people,
          title: 'Behavior',
          subtitle: 'View reports',
          color: Colors.red,
          onTap: () => Get.toNamed(AppPages.PARENT_BEHAVIOR),
        ),
        DashboardCard(
          icon: Icons.directions_bus,
          title: 'Pickup',
          subtitle: 'Transportation updates',
          color: Colors.indigo,
          onTap: () => Get.toNamed(AppPages.PARENT_PICKUP),
        ),
      ],
    );
  }
}