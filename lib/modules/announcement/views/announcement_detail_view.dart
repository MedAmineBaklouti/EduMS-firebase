import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:edums/core/services/pdf_downloader/pdf_downloader.dart';

import '../../../data/models/announcement_model.dart';

class AnnouncementDetailView extends StatelessWidget {
  final AnnouncementModel announcement;
  final bool isAdmin;
  final Future<void> Function()? onEdit;
  final Future<void> Function()? onDelete;

  AnnouncementDetailView({
    super.key,
    required this.announcement,
    this.isAdmin = false,
    this.onEdit,
    this.onDelete,
  });

  final DateFormat _dateFormat = DateFormat('EEEE, MMM d, yyyy • h:mm a');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final audienceLabels = isAdmin ? _audienceLabels() : const <String>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          announcement.title.isNotEmpty
              ? announcement.title
              : 'Announcement',
        ),
        centerTitle: true,
        actions: [
          if (isAdmin && onEdit != null)
            IconButton(
              tooltip: 'Edit announcement',
              icon: const Icon(
                  Icons.edit_outlined,
              ),
              onPressed: () async {
                await onEdit?.call();
              },
            ),
          if (isAdmin)
            IconButton(
              tooltip: 'Download PDF',
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onPressed: () => _downloadPdf(context),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroHeader(context, audienceLabels),
            const SizedBox(height: 24),
            _buildOverviewCard(context, audienceLabels),
            const SizedBox(height: 24),
            _buildSectionCard(
              context,
              title: 'Announcement',
              child: Text(
                announcement.description.isNotEmpty
                    ? announcement.description
                    : 'No additional details were provided for this announcement.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (isAdmin && (onEdit != null || onDelete != null)) ...[
              const SizedBox(height: 32),
              Text(
                'Actions',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  if (onEdit != null)
                    ElevatedButton.icon(
                      onPressed: () async {
                        await onEdit?.call();
                      },
                      icon: const Icon(
                          Icons.edit_outlined,
                        color: Colors.white,
                      ),
                      label: const Text('Edit announcement'),
                    ),
                  if (onDelete != null)
                    OutlinedButton.icon(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('Delete announcement'),
                              content: const Text(
                                'Are you sure you want to delete this announcement?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            );
                          },
                        );
                        if (confirmed == true) {
                          await onDelete?.call();
                        }
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete announcement'),
                    ),
                ],
              ),
            ],
            if (isAdmin) ...[
              const SizedBox(height: 32),
              _buildAdminToolsCard(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context, List<String> audienceLabels) {
    final theme = Theme.of(context);
    final publishedLabel = DateFormat('MMM d, yyyy').format(announcement.createdAt);
    final chips = <Widget>[
      _buildHeroChip(
        context,
        icon: Icons.calendar_today_outlined,
        label: 'Published $publishedLabel',
      ),
    ];

    if (isAdmin) {
      chips.add(
        _buildHeroChip(
          context,
          icon: Icons.hourglass_bottom_outlined,
          label: _expiryDescription(),
        ),
      );
    }

    if (isAdmin) {
      final audienceSummary = audienceLabels.isEmpty ||
              audienceLabels.contains('All audiences')
          ? 'All audiences'
          : audienceLabels.length == 1
              ? audienceLabels.first
              : '${audienceLabels.length} audiences';
      chips.add(
        _buildHeroChip(
          context,
          icon: Icons.people_outline,
          label: 'Audience: $audienceSummary',
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.85),
            theme.colorScheme.primary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            announcement.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: chips,
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(
    BuildContext context,
    List<String> audienceLabels,
  ) {
    final theme = Theme.of(context);
    final detailedFormat = DateFormat('MMM d, yyyy • h:mm a');
    final published = detailedFormat.format(announcement.createdAt);
    final badges = <Widget>[
      _buildOverviewBadge(
        context,
        icon: Icons.event_available_outlined,
        label: 'Published $published',
      ),
    ];

    if (isAdmin) {
      final expiry = announcement.createdAt.add(const Duration(days: 7));
      final expiryLabel = detailedFormat.format(expiry);
      badges
        ..add(
          _buildOverviewBadge(
            context,
            icon: Icons.timer_outlined,
            label: _expiryDescription(),
          ),
        )
        ..add(
          _buildOverviewBadge(
            context,
            icon: Icons.calendar_month_outlined,
            label: 'Expires $expiryLabel',
          ),
        );
    }

    if (isAdmin) {
      final audienceBadgeLabel = audienceLabels.isEmpty ||
              audienceLabels.contains('All audiences')
          ? 'All audiences'
          : '${audienceLabels.length} audience${audienceLabels.length == 1 ? '' : 's'}';
      badges.add(
        _buildOverviewBadge(
          context,
          icon: Icons.people_outline,
          label: audienceBadgeLabel,
        ),
      );
    }

    final specificAudienceLabels = audienceLabels
        .where((label) => label.toLowerCase() != 'all audiences')
        .toList();

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Announcement overview',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: badges,
            ),
            if (isAdmin && specificAudienceLabels.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Target audiences',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: specificAudienceLabels
                    .map((label) => _buildAudienceChip(context, label))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildAdminToolsCard(BuildContext context) {
    final theme = Theme.of(context);
    return _buildSectionCard(
      context,
      title: 'Admin tools',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Download a formatted PDF copy for records or offline sharing. Announcements remain visible for seven days by default.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(
                  Icons.picture_as_pdf_outlined,
                color: Colors.white,
              ),
              label: const Text('Download announcement PDF'),
              onPressed: () => _downloadPdf(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroChip(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.onPrimary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onPrimary),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewBadge(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.primary.withOpacity(0.08),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudienceChip(BuildContext context, String label) {
    final theme = Theme.of(context);
    return Chip(
      label: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: theme.colorScheme.primary.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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

  String _expiryDescription() {
    final expiry = announcement.createdAt.add(const Duration(days: 7));
    final remaining = expiry.difference(DateTime.now());
    if (remaining.isNegative) {
      return 'Expired on ${DateFormat('MMM d, yyyy').format(expiry)}';
    }
    if (remaining.inDays > 0) {
      return 'Expires in ${remaining.inDays} day${remaining.inDays == 1 ? '' : 's'}';
    }
    if (remaining.inHours > 0) {
      return 'Expires in ${remaining.inHours} hour${remaining.inHours == 1 ? '' : 's'}';
    }
    return 'Expires soon';
  }

  Future<void> _downloadPdf(BuildContext context) async {
    final doc = pw.Document();
    final audience = _audienceLabels();
    final dateText = _dateFormat.format(announcement.createdAt);
    final expiry = announcement.createdAt.add(const Duration(days: 7));

    doc.addPage(
      pw.MultiPage(
        build: (_) => [
          pw.Header(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  announcement.title,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Published: $dateText',
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Audience',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            audience.isEmpty
                ? 'All audiences'
                : audience.join(', '),
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Announcement',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            announcement.description,
            style: const pw.TextStyle(fontSize: 13, height: 1.5),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Expires on ${DateFormat('MMM d, yyyy • h:mm a').format(expiry)}',
            style: const pw.TextStyle(fontSize: 11),
          ),
        ],
      ),
    );

    try {
      final bytes = await doc.save();
      final sanitized = _sanitizeFileName(announcement.title);
      final fileName =
          sanitized.isEmpty ? 'announcement.pdf' : '$sanitized.pdf';
      final savedPath = await savePdf(bytes, fileName);
      Get.closeCurrentSnackbar();
      Get.snackbar(
        'Download ready',
        savedPath != null
            ? 'Saved to $savedPath'
            : 'The PDF was not saved. Please check storage permissions or try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.closeCurrentSnackbar();
      Get.snackbar(
        'Download failed',
        'Unable to generate the PDF. ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  String _sanitizeFileName(String value) {
    final trimmed = value.trim().isEmpty ? 'announcement' : value.trim();
    final sanitized = trimmed
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(' ', '_');
    return sanitized.toLowerCase();
  }
}
