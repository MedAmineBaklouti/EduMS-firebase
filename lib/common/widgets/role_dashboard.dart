import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:edums/modules/auth/service/auth_service.dart';
import 'package:edums/common/services/database_service.dart';
import 'package:edums/app/routes/app_pages.dart';
import 'package:edums/modules/messaging/models/conversation_model.dart';
import 'package:edums/common/models/parent_model.dart';
import 'package:edums/common/models/teacher_model.dart';
import 'package:edums/modules/messaging/services/messaging_service.dart';
import 'dashboard_card.dart';
import 'dashboard_announcements.dart';

class RoleDashboard extends StatefulWidget {
  const RoleDashboard({
    super.key,
    required this.cards,
    required this.roleNameKey,
    required this.onLogout,
    this.onMessagesTap,
    this.announcementAudience,
    this.onShowAllAnnouncements,
    this.userName,
  });

  final List<DashboardCard> cards;
  final String roleNameKey;
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
    final roleName = widget.roleNameKey.tr;
    final primary = theme.colorScheme.primary;
    final onPrimary = theme.colorScheme.onPrimary;
    final dashboardBackgroundAsset = theme.brightness == Brightness.dark
        ? 'assets/splash/background_dark.png'
        : 'assets/splash/background.png';

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
                  : 'role_dashboard_user_placeholder'.trParams({'role': roleName});
            } else {
              resolvedUserName =
                  'role_dashboard_user_placeholder'.trParams({'role': roleName});
            }
          }
        }

        return Scaffold(
          drawer: _DashboardDrawer(
            roleName: roleName,
            onLogout: widget.onLogout,
            userName: resolvedUserName,
          ),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: primary,
            foregroundColor: onPrimary,
            title: Text(
              'role_dashboard_title'.trParams({'role': roleName}),
              style: theme.textTheme.titleLarge
                  ?.copyWith(color: onPrimary, fontWeight: FontWeight.bold),
            ),
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
                tooltip: 'common_menu'.tr,
              ),
            ),
            actions: [
              if (widget.onMessagesTap != null)
                _buildMessagesAction(context),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(dashboardBackgroundAsset),
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
                                'role_dashboard_menu'.tr,
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
                              'role_dashboard_menu'.tr,
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

  Widget _buildMessagesAction(BuildContext context) {
    final messagingService = Get.isRegistered<MessagingService>()
        ? Get.find<MessagingService>()
        : null;

    IconButton buildBaseButton() {
      return IconButton(
        icon: const Icon(Icons.message_outlined),
        onPressed: widget.onMessagesTap,
        tooltip: 'common_messages'.tr,
      );
    }

    if (messagingService == null) {
      return buildBaseButton();
    }

    return StreamBuilder<List<ConversationModel>>(
      stream: messagingService.watchConversations(),
      builder: (context, snapshot) {
        final conversations = snapshot.data ?? <ConversationModel>[];
        final unreadTotal = conversations.fold<int>(
          0,
          (total, conversation) => total + conversation.unreadCount,
        );

        if (unreadTotal <= 0) {
          return buildBaseButton();
        }

        final theme = Theme.of(context);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            buildBaseButton(),
            Positioned(
              right: 8,
              top: 10,
              child: _UnreadBadge(
                count: unreadTotal,
                backgroundColor: theme.colorScheme.error,
                textColor: theme.colorScheme.onError,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({
    required this.count,
    required this.backgroundColor,
    required this.textColor,
  });

  final int count;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final displayText = count > 99 ? '99+' : count.toString();
    final textStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
        );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.45),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      constraints: const BoxConstraints(minWidth: 22),
      child: Text(
        displayText,
        textAlign: TextAlign.center,
        style: textStyle,
      ),
    );
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
      backgroundColor: primary,
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
                    'drawer_quick_access'.tr,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: onPrimary.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  children: [
                    _DashboardDrawerItem(
                      icon: Icons.settings_outlined,
                      labelKey: 'drawer_settings',
                      onTap: () => _openSettings(context),
                    ),
                    _DashboardDrawerItem(
                      icon: Icons.person_outline,
                      labelKey: 'drawer_edit_profile',
                      onTap: () => _openEditProfile(context),
                    ),
                    _DashboardDrawerItem(
                      icon: Icons.smart_toy_outlined,
                      labelKey: 'drawer_ask_something',
                      onTap: () {
                        Navigator.of(context).pop();
                        Get.toNamed(AppPages.EDU_CHAT);
                      },
                    ),
                    _DashboardDrawerItem(
                      icon: Icons.contact_support_outlined,
                      labelKey: 'drawer_contact_us',
                      onTap: () => _openContactUs(context),
                    ),
                    _DashboardDrawerItem(
                      icon: Icons.logout,
                      labelKey: 'drawer_logout',
                      onTap: () {
                        Navigator.of(context).pop();
                        onLogout();
                      },
                      isDestructive: true,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'drawer_more_tools'.tr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String featureKey) {
    final featureName = featureKey.tr;
    Get.snackbar(
      'drawer_coming_soon_title'.tr,
      'drawer_coming_soon_message'.trParams({'feature': featureName}),
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
  }

  void _openEditProfile(BuildContext context) {
    Navigator.of(context).pop();
    Get.toNamed(AppPages.EDIT_PROFILE);
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).pop();
    Get.toNamed(AppPages.SETTINGS);
  }

  void _openContactUs(BuildContext context) {
    Navigator.of(context).pop();
    Get.toNamed(AppPages.CONTACT_US);
  }
}

class _DashboardDrawerItem extends StatelessWidget {
  const _DashboardDrawerItem({
    required this.icon,
    required this.labelKey,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String labelKey;
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
                    labelKey.tr,
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