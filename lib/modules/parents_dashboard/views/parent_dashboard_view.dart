// modules/parent/views/parent_dashboard.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:edums/common/widgets/dashboard_card.dart';
import 'package:edums/common/widgets/role_dashboard.dart';
import '../../../app/routes/app_pages.dart';
import '../controllers/parent_controller.dart';

class ParentDashboard extends StatelessWidget {
  final ParentController _controller = Get.find();

  @override
  Widget build(BuildContext context) {
    return RoleDashboard(
      roleNameKey: 'role_parent',
      onLogout: _controller.logout,
      onMessagesTap: () => Get.toNamed(AppPages.MESSAGING),
      announcementAudience: 'parents',
      onShowAllAnnouncements: () => Get.toNamed(AppPages.PARENT_ANNOUNCEMENTS),
      cards: [
        DashboardCard(
          icon: Icons.menu_book,
          title: 'dashboard_card_courses_title'.tr,
          subtitle: 'dashboard_card_courses_parent_subtitle'.tr,
          color: Colors.teal,
          onTap: () => Get.toNamed(AppPages.PARENT_COURSES),
        ),
        DashboardCard(
          icon: Icons.assignment,
          title: 'dashboard_card_homework_title'.tr,
          subtitle: 'dashboard_card_homework_parent_subtitle'.tr,
          color: Colors.green,
          onTap: () => Get.toNamed(AppPages.PARENT_HOMEWORK),
        ),
        DashboardCard(
          icon: Icons.calendar_today,
          title: 'dashboard_card_attendance_title'.tr,
          subtitle: 'dashboard_card_attendance_parent_subtitle'.tr,
          color: Colors.orange,
          onTap: () => Get.toNamed(AppPages.PARENT_ATTENDANCE),
        ),
        DashboardCard(
          icon: Icons.emoji_people,
          title: 'dashboard_card_behavior_title'.tr,
          subtitle: 'dashboard_card_behavior_parent_subtitle'.tr,
          color: Colors.red,
          onTap: () => Get.toNamed(AppPages.PARENT_BEHAVIOR),
        ),
        DashboardCard(
          icon: Icons.directions_bus,
          title: 'dashboard_card_pickup_title'.tr,
          subtitle: 'dashboard_card_pickup_parent_subtitle'.tr,
          color: Colors.indigo,
          onTap: () => Get.toNamed(AppPages.PARENT_PICKUP),
        ),
      ],
    );
  }
}