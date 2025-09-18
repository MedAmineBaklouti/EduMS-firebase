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

  @override
  Widget build(BuildContext context) {
    final controller =
        Get.put(AnnouncementController(audienceFilter: audience));
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Announcements'),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.06),
              theme.colorScheme.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Obx(() {
          if (controller.announcements.isEmpty) {
            return _buildEmptyState(context);
          }
          return ListView.separated(
            padding: EdgeInsets.fromLTRB(16, 24, 16, isAdmin ? 120 : 32),
            physics: const BouncingScrollPhysics(),
            itemCount: controller.announcements.length,
            separatorBuilder: (_, __) => const SizedBox(height: 18),
            itemBuilder: (context, index) {
              final ann = controller.announcements[index];
              return isAdmin
                  ? _buildAdminItem(context, controller, ann)
                  : _buildAnnouncementCard(context, ann);
            },
          );
        }),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              heroTag: 'announcementFab',
              onPressed: () => controller.openForm(),
              icon: const Icon(Icons.add),
              label: const Text('New Announcement'),
            )
          : null,
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
              'No announcements yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Stay tuned! New announcements will appear here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementCard(
    BuildContext context,
    AnnouncementModel ann, {
    bool highlightForAdmin = false,
  }) {
    final theme = Theme.of(context);
    final dateText = _dateFormat.format(ann.createdAt);
    final showAudience = isAdmin || highlightForAdmin;
    final audienceLabels =
        showAudience ? _audienceLabels(ann) : const <String>[];
    final showExpiryDetails = isAdmin || highlightForAdmin;
    final showAudienceTags = showAudience && audienceLabels.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Get.to(
          () => AnnouncementDetailView(
            announcement: ann,
            isAdmin: isAdmin,
          ),
        ),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.08),
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
                        color: theme.colorScheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.campaign_outlined,
                        color: theme.colorScheme.primary,
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
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                dateText,
                                style:
                                    theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
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
                    color: theme.colorScheme.onSurfaceVariant,
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
        label: 'Edit',
      ),
      secondaryBackground: _buildSwipeBackground(
        context,
        alignment: Alignment.centerRight,
        color: theme.colorScheme.error,
        icon: Icons.delete_outline,
        label: 'Delete',
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
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: 6),
                Text(
                  timeLeftLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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
            backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.6),
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
      return 'Expired';
    }
    if (remainingMinutes >= 1440) {
      final days = remainingMinutes ~/ 1440;
      final hours = (remainingMinutes % 1440) ~/ 60;
      return hours > 0 ? '${days}d ${hours}h left' : '${days}d left';
    }
    if (remainingMinutes >= 60) {
      final hours = remainingMinutes ~/ 60;
      final minutes = remainingMinutes % 60;
      return minutes > 0 ? '${hours}h ${minutes}m left' : '${hours}h left';
    }
    return '$remainingMinutes min left';
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
        ),
      ),
      backgroundColor: theme.colorScheme.primary.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  List<String> _audienceLabels(AnnouncementModel ann) {
    if (ann.audience.isEmpty) {
      return ['All audiences'];
    }
    final seen = <String>{};
    final labels = <String>[];
    for (final item in ann.audience) {
      final formatted = _capitalize(item.trim());
      if (formatted.isEmpty) continue;
      final key = formatted.toLowerCase();
      if (seen.add(key)) {
        labels.add(formatted);
      }
    }
    return labels;
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
        title: const Text('Delete announcement'),
        content:
            const Text('Are you sure you want to delete this announcement?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Delete',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
