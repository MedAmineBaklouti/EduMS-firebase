import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:edums/core/services/pdf_downloader/pdf_downloader.dart';

import '../models/announcement_model.dart';

class AnnouncementDetailView extends StatelessWidget {
  final AnnouncementModel announcement;
  final bool isAdmin;
  final Future<void> Function()? onEdit;

  AnnouncementDetailView({
    super.key,
    required this.announcement,
    this.isAdmin = false,
    this.onEdit,
  });

  final DateFormat _dateFormat = DateFormat('EEEE, MMM d, yyyy • h:mm a');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final audienceLabels = isAdmin ? _audienceLabels() : const <String>[];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        title: Text(
          announcement.title.isNotEmpty
              ? announcement.title
              : 'announcement_detail_fallback_title'.tr,
        ),
        centerTitle: true,
        actions: [
          if (isAdmin && onEdit != null)
            IconButton(
              tooltip: 'announcement_detail_edit_tooltip'.tr,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                await onEdit?.call();
              },
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
              title: 'announcement_detail_section_announcement'.tr,
              child: Text(
                announcement.description.isNotEmpty
                    ? announcement.description
                    : 'announcement_detail_no_description'.tr,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            // Admin actions are now handled from the app bar, so the body remains
            // focused on the announcement content and context.
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
        label: 'announcement_detail_chip_published'
            .trParams({'date': publishedLabel}),
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
      final allAudienceLabel = 'announcement_audience_all'.tr;
      final audienceSummary = audienceLabels.isEmpty ||
              audienceLabels.contains(allAudienceLabel)
          ? allAudienceLabel
          : audienceLabels.length == 1
              ? audienceLabels.first
              : 'announcement_detail_audience_summary_multiple'
                  .trParams({'count': '${audienceLabels.length}'});
      chips.add(
        _buildHeroChip(
          context,
          icon: Icons.people_outline,
          label: 'announcement_detail_chip_audience'
              .trParams({'audience': audienceSummary}),
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
        label: 'announcement_detail_badge_published'
            .trParams({'date': published}),
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
            label: 'announcement_detail_badge_expires_on'
                .trParams({'date': expiryLabel}),
          ),
        );
    }

    if (isAdmin) {
      final allAudienceLabel = 'announcement_audience_all'.tr;
      final audienceBadgeLabel = audienceLabels.isEmpty ||
              audienceLabels.contains(allAudienceLabel)
          ? allAudienceLabel
          : 'announcement_detail_audience_summary_multiple'
              .trParams({'count': '${audienceLabels.length}'});
      badges.add(
        _buildOverviewBadge(
          context,
          icon: Icons.people_outline,
          label: audienceBadgeLabel,
        ),
      );
    }

    final allAudienceLabel = 'announcement_audience_all'.tr;
    final specificAudienceLabels = audienceLabels
        .where((label) => label != allAudienceLabel)
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
              'announcement_detail_overview_title'.tr,
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
                'announcement_detail_target_audiences'.tr,
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
      title: 'announcement_detail_admin_tools_title'.tr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'announcement_detail_admin_tools_message'.tr,
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
              label: Text('announcement_detail_admin_tools_download'.tr),
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
      return ['announcement_audience_all'.tr];
    }
    final seen = <String>{};
    final labels = <String>[];
    for (final item in announcement.audience) {
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

  String _expiryDescription() {
    final expiry = announcement.createdAt.add(const Duration(days: 7));
    final remaining = expiry.difference(DateTime.now());
    if (remaining.isNegative) {
      return 'announcement_detail_expired_on'
          .trParams({'date': DateFormat('MMM d, yyyy').format(expiry)});
    }
    if (remaining.inDays > 0) {
      return 'announcement_detail_expires_in_days'
          .trParams({'count': '${remaining.inDays}'});
    }
    if (remaining.inHours > 0) {
      return 'announcement_detail_expires_in_hours'
          .trParams({'count': '${remaining.inHours}'});
    }
    return 'announcement_detail_expires_soon'.tr;
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
                  'announcement_pdf_published'.trParams({'date': dateText}),
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'announcement_pdf_audience_label'.tr,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            audience.isEmpty
                ? 'announcement_audience_all'.tr
                : audience.join(', '),
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'announcement_pdf_announcement_label'.tr,
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
            'announcement_pdf_expires_on'
                .trParams({'date': DateFormat('MMM d, yyyy • h:mm a').format(expiry)}),
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
        'announcement_pdf_download_ready'.tr,
        savedPath != null
            ? 'announcement_pdf_saved_to'.trParams({'path': savedPath})
            : 'announcement_pdf_not_saved'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.closeCurrentSnackbar();
      Get.snackbar(
        'announcement_pdf_download_failed'.tr,
        'announcement_pdf_download_error'.trParams({'error': e.toString()}),
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
