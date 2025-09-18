import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/modern_scaffold.dart';
import '../../../data/models/announcement_model.dart';

class AnnouncementDetailView extends StatelessWidget {
  final AnnouncementModel announcement;

  AnnouncementDetailView({super.key, required this.announcement});

  final DateFormat _dateFormat = DateFormat('EEEE, MMM d, yyyy • h:mm a');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateText = _dateFormat.format(announcement.createdAt);
    final audienceLabels = _audienceLabels();

    return ModernScaffold(
      appBar: AppBar(
        title: const Text('Announcement'),
        centerTitle: true,
      ),
      alignment: Alignment.topCenter,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      body: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.12),
                    blurRadius: 42,
                    offset: const Offset(0, 32),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.campaign_rounded,
                            size: 28,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                announcement.title,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                dateText,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (audienceLabels.isNotEmpty) ...[
                      Text(
                        'Audience',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: audienceLabels
                            .map(
                              (label) => _buildTagChip(
                                context,
                                icon: Icons.people_outline,
                                label: label,
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 24),
                    ],
                    Divider(color: theme.colorScheme.surfaceVariant),
                    const SizedBox(height: 24),
                    Text(
                      announcement.description,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<String> _audienceLabels() {
    if (announcement.audience.isEmpty) {
      return ['All audiences'];
    }
    final seen = <String>{};
    final labels = <String>[];
    for (final item in announcement.audience) {
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

  Widget _buildTagChip(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
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
}
