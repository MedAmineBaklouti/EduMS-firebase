import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/announcement_controller.dart';
import '../../../data/models/announcement_model.dart';
import 'announcement_detail_view.dart';

class AnnouncementListView extends StatelessWidget {
  final bool isAdmin;
  final String? audience;

  AnnouncementListView({super.key, this.isAdmin = false, this.audience});

  static final DateFormat _dateFormat = DateFormat('MMM d, yyyy • h:mm a');
  static final DateFormat _weekdaySectionFormat = DateFormat('EEEE, MMM d');
  static final DateFormat _monthDaySectionFormat = DateFormat('MMMM d');
  static final DateFormat _fullDateSectionFormat = DateFormat('MMM d, yyyy');

  @override
  Widget build(BuildContext context) {
    final controller =
        Get.put(AnnouncementController(audienceFilter: audience));
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        title: Text('announcement_list_title'.tr),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.05),
              theme.colorScheme.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Obx(() {
          final items = controller.announcements;
          return RefreshIndicator(
            onRefresh: controller.refreshAnnouncements,
            child: items.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    padding:
                        EdgeInsets.fromLTRB(16, 24, 16, isAdmin ? 120 : 32),
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final ann = items[index];
                      final showHeader = index == 0 ||
                          !_isSameDay(items[index - 1].createdAt, ann.createdAt);
                      final headerLabel =
                          showHeader ? _sectionLabelForDate(ann.createdAt) : null;
                      final card = isAdmin
                          ? _buildAdminItem(context, controller, ann)
                          : _buildAnnouncementCard(context, ann);

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (headerLabel != null)
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                4,
                                index == 0 ? 0 : 24,
                                4,
                                12,
                              ),
                              child: Text(
                                headerLabel,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurfaceVariant,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          card,
                          if (index != items.length - 1)
                            const SizedBox(height: 18),
                        ],
                      );
                    },
                  ),
          );
        }),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              heroTag: 'announcementFab',
              onPressed: () => controller.openForm(),
              icon: const Icon(Icons.add),
              label: Text('announcement_list_new'.tr),
            )
          : null,
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(32, 160, 32, 200),
      children: [
        Container(
          height: 88,
          width: 88,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.campaign_outlined,
            color: theme.colorScheme.primary,
            size: 40,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'announcement_list_empty_title'.tr,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'announcement_list_empty_message'.tr,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildAnnouncementCard(
    BuildContext context,
    AnnouncementModel ann, {
    bool highlightForAdmin = false,
    Future<void> Function()? onEdit,
  }) {
    final theme = Theme.of(context);
    final dateText = _dateFormat.format(ann.createdAt);
    final showAudience = isAdmin || highlightForAdmin;
    final audienceLabels =
        showAudience ? _audienceLabels(ann) : const <String>[];
    final showExpiryDetails = isAdmin || highlightForAdmin;
    final showAudienceTags = showAudience && audienceLabels.isNotEmpty;

    final cardColor = theme.colorScheme.surface;
    final primaryColor = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;
    final shadowColor = highlightForAdmin
        ? primaryColor.withOpacity(0.16)
        : primaryColor.withOpacity(0.08);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Get.to(
          () => AnnouncementDetailView(
            announcement: ann,
            isAdmin: isAdmin,
            onEdit: onEdit,
          ),
        ),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: cardColor,
            border: highlightForAdmin
                ? Border.all(color: primaryColor.withOpacity(0.25), width: 1.4)
                : null,
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.campaign_outlined,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ann.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 16,
                                color: onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                dateText,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  ann.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                if (showAudienceTags) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: audienceLabels
                        .map((label) => _buildTagChip(
                              context,
                              Icons.people_outline,
                              label,
                            ))
                        .toList(),
                  ),
                ],
                if (showExpiryDetails) ...[
                  const SizedBox(height: 16),
                  _buildExpiryStatus(
                    context,
                    announcement: ann,
                    highlightForAdmin: highlightForAdmin,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _sectionLabelForDate(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final lastWeek = today.subtract(const Duration(days: 7));
    final target = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (_isSameDay(target, today)) {
      return 'announcement_section_today'.tr;
    }
    if (_isSameDay(target, yesterday)) {
      return 'announcement_section_yesterday'.tr;
    }
    if (target.isAfter(lastWeek)) {
      return _weekdaySectionFormat.format(timestamp);
    }
    if (target.year == today.year) {
      return _monthDaySectionFormat.format(timestamp);
    }
    return _fullDateSectionFormat.format(timestamp);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildAdminItem(BuildContext context,
      AnnouncementController controller, AnnouncementModel ann) {
    final theme = Theme.of(context);
    return Dismissible(
      key: Key(ann.id),
      background: _buildSwipeBackground(
        context,
        alignment: Alignment.centerLeft,
        color: theme.colorScheme.primary,
        icon: Icons.edit_outlined,
        label: 'announcement_action_edit'.tr,
      ),
      secondaryBackground: _buildSwipeBackground(
        context,
        alignment: Alignment.centerRight,
        color: theme.colorScheme.error,
        icon: Icons.delete_outline,
        label: 'announcement_action_delete'.tr,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          controller.openForm(announcement: ann);
          return false;
        } else if (direction == DismissDirection.endToStart) {
          final confirmed = await _confirmDelete(context);
          if (confirmed == true) {
            await controller.deleteAnnouncement(ann.id);
            return true;
          }
          return false;
        }
        return false;
      },
      child: _buildAnnouncementCard(
        context,
        ann,
        highlightForAdmin: true,
        onEdit: () async {
          Get.back();
          await Future<void>.delayed(Duration.zero);
          controller.openForm(announcement: ann);
        },
      ),
    );
  }

  Widget _buildExpiryStatus(
    BuildContext context, {
    required AnnouncementModel announcement,
    required bool highlightForAdmin,
  }) {
    final theme = Theme.of(context);
    final expiryDate = announcement.createdAt.add(const Duration(days: 7));
    final totalLifetimeMinutes = const Duration(days: 7).inMinutes;
    final remainingMinutes = expiryDate.difference(DateTime.now()).inMinutes;
    final clampedRemaining = remainingMinutes < 0 ? 0 : remainingMinutes;

    double progress = 1 - (clampedRemaining / totalLifetimeMinutes);
    if (progress < 0) {
      progress = 0;
    } else if (progress > 1) {
      progress = 1;
    }

    final timeLeftLabel = _formatRemainingTime(clampedRemaining);
    final expiryLabel = DateFormat('MMM d').format(expiryDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.hourglass_bottom,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  timeLeftLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Text(
              expiryLabel,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            minHeight: 6,
            value: progress,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation(
              highlightForAdmin
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  String _formatRemainingTime(int remainingMinutes) {
    if (remainingMinutes <= 0) {
      return 'announcement_expiry_expired'.tr;
    }
    if (remainingMinutes >= 1440) {
      final days = remainingMinutes ~/ 1440;
      final hours = (remainingMinutes % 1440) ~/ 60;
      return hours > 0
          ? 'announcement_expiry_days_hours'
              .trParams({'days': '$days', 'hours': '$hours'})
          : 'announcement_expiry_days_only'.trParams({'days': '$days'});
    }
    if (remainingMinutes >= 60) {
      final hours = remainingMinutes ~/ 60;
      final minutes = remainingMinutes % 60;
      return minutes > 0
          ? 'announcement_expiry_hours_minutes'
              .trParams({'hours': '$hours', 'minutes': '$minutes'})
          : 'announcement_expiry_hours_only'.trParams({'hours': '$hours'});
    }
    return 'announcement_expiry_minutes'
        .trParams({'minutes': '$remainingMinutes'});
  }

  Widget _buildSwipeBackground(
    BuildContext context, {
    required Alignment alignment,
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [color.withOpacity(0.85), color],
          begin: alignment == Alignment.centerLeft
              ? Alignment.centerLeft
              : Alignment.centerRight,
          end: alignment == Alignment.centerLeft
              ? Alignment.centerRight
              : Alignment.centerLeft,
        ),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);
    return Chip(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      avatar: Icon(
        icon,
        size: 18,
        color: theme.colorScheme.primary,
      ),
      label: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.primary,
        ),
      ),
      backgroundColor: theme.colorScheme.primary.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  List<String> _audienceLabels(AnnouncementModel ann) {
    if (ann.audience.isEmpty) {
      return ['announcement_audience_all'.tr];
    }
    final seen = <String>{};
    final labels = <String>[];
    for (final item in ann.audience) {
      final normalized = item.trim().toLowerCase();
      if (normalized.isEmpty || !seen.add(normalized)) {
        continue;
      }
      labels.add(_audienceLabelForKey(normalized));
    }
    return labels;
  }

  String _audienceLabelForKey(String key) {
    switch (key) {
      case 'teachers':
        return 'announcement_audience_teachers'.tr;
      case 'parents':
        return 'announcement_audience_parents'.tr;
      default:
        return _capitalize(key);
    }
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    final theme = Theme.of(context);
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('announcement_confirm_delete_title'.tr),
        content: Text('announcement_confirm_delete_message'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'announcement_action_cancel'.tr,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'announcement_action_delete'.tr,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
