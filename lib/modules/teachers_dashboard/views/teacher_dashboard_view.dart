// modules/teacher/views/teacher_dashboard.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:edums/modules/common/widgets/dashboard_card.dart';
import 'package:edums/modules/common/widgets/role_dashboard.dart';
import '../../../app/routes/app_pages.dart';
import '../controllers/teacher_controller.dart';

class TeacherDashboard extends StatelessWidget {
  final TeacherController _controller = Get.find();

  @override
  Widget build(BuildContext context) {
    return RoleDashboard(
      roleNameKey: 'role_teacher',
      onLogout: _controller.logout,
      onMessagesTap: () => Get.toNamed(AppPages.MESSAGING),
      announcementAudience: 'teachers',
      onShowAllAnnouncements: () => Get.toNamed(AppPages.TEACHER_ANNOUNCEMENTS),
      cards: [
        DashboardCard(
          icon: Icons.menu_book,
          title: 'dashboard_card_courses_title'.tr,
          subtitle: 'dashboard_card_courses_teacher_subtitle'.tr,
          color: Colors.teal,
          onTap: () => Get.toNamed(AppPages.TEACHER_COURSES),
        ),
        DashboardCard(
          icon: Icons.assignment,
          title: 'dashboard_card_homework_title'.tr,
          subtitle: 'dashboard_card_homework_teacher_subtitle'.tr,
          color: Colors.green,
          onTap: () => Get.toNamed(AppPages.TEACHER_HOMEWORK),
        ),
        DashboardCard(
          icon: Icons.calendar_today,
          title: 'dashboard_card_attendance_title'.tr,
          subtitle: 'dashboard_card_attendance_teacher_subtitle'.tr,
          color: Colors.orange,
          onTap: () => Get.toNamed(AppPages.TEACHER_ATTENDANCE),
        ),
        DashboardCard(
          icon: Icons.emoji_people,
          title: 'dashboard_card_behavior_title'.tr,
          subtitle: 'dashboard_card_behavior_teacher_subtitle'.tr,
          color: Colors.red,
          onTap: () => Get.toNamed(AppPages.TEACHER_BEHAVIOR),
        ),
        DashboardCard(
          icon: Icons.directions_bus,
          title: 'dashboard_card_pickup_title'.tr,
          subtitle: 'dashboard_card_pickup_teacher_subtitle'.tr,
          color: Colors.indigo,
          onTap: () => Get.toNamed(AppPages.TEACHER_PICKUP),
        ),
      ],
    );
  }
}