// modules/admin/views/admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:edums/modules/common/widgets/dashboard_card.dart';
import 'package:edums/modules/common/widgets/role_dashboard.dart';
import '../controllers/admin_controller.dart';
import '../../../app/routes/app_pages.dart';

class AdminDashboard extends StatelessWidget {
  final AdminController _controller = Get.find();

  @override
  Widget build(BuildContext context) {
    return RoleDashboard(
      roleNameKey: 'role_admin',
      onLogout: _controller.logout,
      onMessagesTap: () => Get.toNamed(AppPages.MESSAGING),
      cards: [
        DashboardCard(
          icon: Icons.announcement,
          title: 'dashboard_card_announcements_title'.tr,
          subtitle: 'dashboard_card_announcements_admin_subtitle'.tr,
          color: Colors.purple,
          onTap: () => Get.toNamed(AppPages.ADMIN_ANNOUNCEMENTS),
        ),
        DashboardCard(
          icon: Icons.settings,
          title: 'dashboard_card_control_title'.tr,
          subtitle: 'dashboard_card_control_subtitle'.tr,
          color: Colors.grey,
          onTap: () => Get.toNamed(AppPages.ADMIN_CONTROL),
        ),
        DashboardCard(
          icon: Icons.school,
          title: 'dashboard_card_courses_title'.tr,
          subtitle: 'dashboard_card_courses_admin_subtitle'.tr,
          color: Colors.blue,
          onTap: () => Get.toNamed(AppPages.ADMIN_COURSES),
        ),
        DashboardCard(
          icon: Icons.assignment,
          title: 'dashboard_card_homework_title'.tr,
          subtitle: 'dashboard_card_homework_admin_subtitle'.tr,
          color: Colors.green,
          onTap: () => Get.toNamed(AppPages.ADMIN_HOMEWORK),
        ),
        DashboardCard(
          icon: Icons.calendar_today,
          title: 'dashboard_card_student_attendance_title'.tr,
          subtitle: 'dashboard_card_student_attendance_subtitle'.tr,
          color: Colors.orange,
          onTap: () => Get.toNamed(AppPages.ADMIN_ATTENDANCE),
        ),
        DashboardCard(
          icon: Icons.fact_check_outlined,
          title: 'dashboard_card_teacher_attendance_title'.tr,
          subtitle: 'dashboard_card_teacher_attendance_subtitle'.tr,
          color: Colors.deepOrange,
          onTap: () => Get.toNamed(AppPages.ADMIN_TEACHER_ATTENDANCE),
        ),
        DashboardCard(
          icon: Icons.emoji_people,
          title: 'dashboard_card_behavior_title'.tr,
          subtitle: 'dashboard_card_behavior_admin_subtitle'.tr,
          color: Colors.red,
          onTap: () => Get.toNamed(AppPages.ADMIN_BEHAVIOR),
        ),
        DashboardCard(
          icon: Icons.directions_bus,
          title: 'dashboard_card_pickup_title'.tr,
          subtitle: 'dashboard_card_pickup_admin_subtitle'.tr,
          color: Colors.indigo,
          onTap: () => Get.toNamed(AppPages.ADMIN_PICKUP),
        ),
        DashboardCard(
          icon: Icons.archive_outlined,
          title: 'dashboard_card_pickup_archived_title'.tr,
          subtitle: 'dashboard_card_pickup_archived_subtitle'.tr,
          color: Colors.teal,
          onTap: () => Get.toNamed(AppPages.ADMIN_PICKUP_ARCHIVE),
        ),
      ],
    );
  }
}