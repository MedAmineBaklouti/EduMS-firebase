// modules/parent/views/parent_dashboard.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_pages.dart';
import '../controllers/parent_controller.dart';

class ParentDashboard extends StatelessWidget {
  final ParentController _controller = Get.find();

  @override
  Widget build(BuildContext context) {
    final List<_ParentDashboardAction> actions = [
      _ParentDashboardAction(
        icon: Icons.announcement,
        title: 'Announcements',
        subtitle: 'School notices',
        color: Colors.purple,
        onTap: () => Get.toNamed(AppPages.PARENT_ANNOUNCEMENTS),
      ),
      _ParentDashboardAction(
        icon: Icons.menu_book,
        title: 'Courses',
        subtitle: 'View class materials',
        color: Colors.teal,
        onTap: () => Get.toNamed(AppPages.PARENT_COURSES),
      ),
      _ParentDashboardAction(
        icon: Icons.calendar_today,
        title: 'Attendance',
        subtitle: 'View records',
        color: Colors.orange,
        onTap: () => Get.toNamed(AppPages.PARENT_ATTENDANCE),
      ),
      _ParentDashboardAction(
        icon: Icons.emoji_people,
        title: 'Behavior',
        subtitle: 'View reports',
        color: Colors.red,
        onTap: () => Get.toNamed(AppPages.PARENT_BEHAVIOR),
      ),
      _ParentDashboardAction(
        icon: Icons.directions_bus,
        title: 'Pickup',
        subtitle: 'Transportation updates',
        color: Colors.indigo,
        onTap: () => Get.toNamed(AppPages.PARENT_PICKUP),
      ),
      _ParentDashboardAction(
        icon: Icons.assignment,
        title: 'Homework',
        subtitle: 'View assignments',
        color: Colors.green,
        onTap: () => Get.toNamed(AppPages.PARENT_HOMEWORK),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parent Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _controller.logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return _ParentDashboardTile(action: actions[index]);
        },
      ),
    );
  }
}

class _ParentDashboardAction {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ParentDashboardAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}

class _ParentDashboardTile extends StatelessWidget {
  final _ParentDashboardAction action;

  const _ParentDashboardTile({required this.action});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: action.color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: action.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(action.icon, color: action.color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    action.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    action.subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }
}
