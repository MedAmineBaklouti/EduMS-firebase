import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../../data/models/parent_model.dart';
import '../../data/models/teacher_model.dart';
import '../../core/widgets/dashboard_card.dart';
import 'dashboard_announcements.dart';

class RoleDashboard extends StatefulWidget {
  const RoleDashboard({
    super.key,
    required this.cards,
    required this.roleName,
    required this.onLogout,
    this.onMessagesTap,
    this.announcementAudience,
    this.onShowAllAnnouncements,
    this.userName,
  });

  final List<DashboardCard> cards;
  final String roleName;
  final VoidCallback onLogout;
  final VoidCallback? onMessagesTap;
  final String? announcementAudience;
  final VoidCallback? onShowAllAnnouncements;
  final String? userName;

  @override
  State<RoleDashboard> createState() => _RoleDashboardState();
}

class _RoleDashboardState extends State<RoleDashboard> {
  late final Future<String?> _userModelNameFuture;

  @override
  void initState() {
    super.initState();
    _userModelNameFuture = _fetchUserModelName();
  }

  Future<String?> _fetchUserModelName() async {
    final authService =
        Get.isRegistered<AuthService>() ? Get.find<AuthService>() : null;
    final databaseService =
        Get.isRegistered<DatabaseService>() ? Get.find<DatabaseService>() : null;

    if (authService == null || databaseService == null) {
      return null;
    }

    final user = authService.currentUser;
    final role = authService.currentRole?.toLowerCase();
    if (user == null || role == null) {
      return null;
    }

    try {
      switch (role) {
        case 'teacher':
          final snapshot =
              await databaseService.firestore.collection('teachers').doc(user.uid).get();
          if (!snapshot.exists) {
            return null;
          }
          return TeacherModel.fromDoc(snapshot).name.trim();
        case 'parent':
          final snapshot =
              await databaseService.firestore.collection('parents').doc(user.uid).get();
          if (!snapshot.exists) {
            return null;
          }
          return ParentModel.fromDoc(snapshot).name.trim();
        default:
          return null;
      }
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final onPrimary = theme.colorScheme.onPrimary;

    final authService =
        Get.isRegistered<AuthService>() ? Get.find<AuthService>() : null;

    return FutureBuilder<String?>(
      future: _userModelNameFuture,
      builder: (context, snapshot) {
        final modelName = snapshot.data?.trim();

        String resolvedUserName = widget.userName?.trim() ?? '';
        if (modelName != null && modelName.isNotEmpty) {
          resolvedUserName = modelName;
        }

        if (resolvedUserName.isEmpty) {
          final displayName = authService?.currentUser?.displayName?.trim();
          if (displayName != null && displayName.isNotEmpty) {
            resolvedUserName = displayName;
          } else {
            final email = authService?.currentUser?.email?.trim();
            if (email != null && email.isNotEmpty) {
              final formattedFromEmail = _formatNameFromEmail(email);
              resolvedUserName = formattedFromEmail.isNotEmpty
                  ? formattedFromEmail
                  : '${widget.roleName} user';
            } else {
              resolvedUserName = '${widget.roleName} user';
            }
          }
        }

        final announcementDisplayName = widget.roleName.toLowerCase() == 'admin'
            ? 'Admin'
            : resolvedUserName;

        return Scaffold(
          drawer: _DashboardDrawer(
            roleName: widget.roleName,
            onLogout: widget.onLogout,
            userName: resolvedUserName,
          ),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: primary,
            foregroundColor: onPrimary,
            title: Text(
              '${widget.roleName} Dashboard',
              style: theme.textTheme.titleLarge
                  ?.copyWith(color: onPrimary, fontWeight: FontWeight.bold),
            ),
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
                tooltip: 'Menu',
              ),
            ),
            actions: [
              if (widget.onMessagesTap != null)
                IconButton(
                  icon: const Icon(Icons.message_outlined),
                  onPressed: widget.onMessagesTap,
                  tooltip: 'Messages',
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 960;

                Widget buildMenuGrid(int crossAxisCount) {
                  return GridView.builder(
                    itemCount: widget.cards.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: isWide ? 1.05 : 1.1,
                    ),
                    itemBuilder: (context, index) => widget.cards[index],
                  );
                }

                final announcementsWidget = widget.announcementAudience != null
                    ? DashboardAnnouncements(
                        audience: widget.announcementAudience,
                        onShowAll: widget.onShowAllAnnouncements,
                        userName: announcementDisplayName,
                      )
                    : const SizedBox.shrink();

                if (isWide) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Menu',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              Expanded(child: buildMenuGrid(3)),
                            ],
                          ),
                        ),
                        if (widget.announcementAudience != null) ...[
                          const SizedBox(width: 24),
                          SizedBox(width: 360, child: announcementsWidget),
                        ],
                      ],
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.announcementAudience != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                        child: announcementsWidget,
                      ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Menu',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            Expanded(child: buildMenuGrid(2)),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  String _formatNameFromEmail(String email) {
    final localPart = email.split('@').first.trim();
    if (localPart.isEmpty) {
      return '';
    }

    final cleaned = localPart
        .replaceAll(RegExp(r'[._-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (cleaned.isEmpty) {
      return '';
    }

    final words = cleaned.split(' ');
    final capitalizedWords = words.map((word) {
      if (word.isEmpty) {
        return word;
      }
      if (word.length == 1) {
        return word.toUpperCase();
      }
      return '${word[0].toUpperCase()}${word.substring(1)}';
    }).toList();

    return capitalizedWords.join(' ');
  }
}

class _DashboardDrawer extends StatelessWidget {
  const _DashboardDrawer({
    required this.roleName,
    required this.onLogout,
    required this.userName,
  });

  final String roleName;
  final VoidCallback onLogout;
  final String userName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final onPrimary = theme.colorScheme.onPrimary;

    return Drawer(
      elevation: 8,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primary, primary.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(24),
                  bottomLeft: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: onPrimary.withOpacity(0.2),
                    radius: 28,
                    child: Icon(Icons.dashboard_customize, color: onPrimary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Quick access to upcoming features',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: onPrimary.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
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
                    icon: Icons.smart_toy_outlined,
                    label: 'Ask something',
                    onTap: () => _showComingSoon(context, 'Ask something'),
                  ),
                  _DashboardDrawerItem(
                    icon: Icons.contact_support_outlined,
                    label: 'Contact us',
                    onTap: () => _showComingSoon(context, 'Contact us'),
                  ),
                  _DashboardDrawerItem(
                    icon: Icons.logout,
                    label: 'Logout',
                    onTap: () {
                      Navigator.of(context).pop();
                      onLogout();
                    },
                    isDestructive: true,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Text(
                'More tools coming soon',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
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
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isDestructive
        ? theme.colorScheme.error
        : theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right,
                    color: theme.colorScheme.onSurface.withOpacity(0.6)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}