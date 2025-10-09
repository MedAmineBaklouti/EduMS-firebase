import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/widgets/dashboard_card.dart';
import 'dashboard_announcements.dart';

class RoleDashboard extends StatelessWidget {
  final List<DashboardCard> cards;
  final String roleName;
  final VoidCallback onLogout;
  final VoidCallback? onMessagesTap;
  final String? announcementAudience;

  const RoleDashboard({
    super.key,
    required this.cards,
    required this.roleName,
    required this.onLogout,
    this.onMessagesTap,
    this.announcementAudience,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _DashboardDrawer(
        roleName: roleName,
        onLogout: onLogout,
      ),
      appBar: AppBar(
        title: Text('$roleName Dashboard'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: 'Menu',
          ),
        ),
        actions: [
          if (onMessagesTap != null)
            IconButton(
              icon: const Icon(Icons.message_outlined),
              onPressed: onMessagesTap,
              tooltip: 'Messages',
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: onLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/splash/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            if (announcementAudience != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: DashboardAnnouncements(
                  audience: announcementAudience,
                ),
              ),
            Expanded(
              child: GridView.count(
                padding: const EdgeInsets.all(16),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: cards,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardDrawer extends StatelessWidget {
  const _DashboardDrawer({
    required this.roleName,
    required this.onLogout,
  });

  final String roleName;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '$roleName shortcuts',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Quick access to upcoming features',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            _DashboardDrawerItem(
              icon: Icons.settings_outlined,
              label: 'Settings',
              onTap: () => _showComingSoon(context, 'Settings'),
            ),
            _DashboardDrawerItem(
              icon: Icons.person_outline,
              label: 'Edit profile',
              onTap: () => _showComingSoon(context, 'Edit profile'),
            ),
            _DashboardDrawerItem(
              icon: Icons.help_outline,
              label: 'Ask something',
              onTap: () => _showComingSoon(context, 'Ask something'),
            ),
            _DashboardDrawerItem(
              icon: Icons.logout,
              label: 'Logout',
              onTap: () {
                Navigator.of(context).pop();
                onLogout();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String featureName) {
    Get.snackbar(
      'Coming soon',
      '$featureName will be available soon!',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
  }
}

class _DashboardDrawerItem extends StatelessWidget {
  const _DashboardDrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap,
    );
  }
}