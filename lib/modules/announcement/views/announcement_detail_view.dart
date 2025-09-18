import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../data/models/announcement_model.dart';

class AnnouncementDetailView extends StatelessWidget {
  final AnnouncementModel announcement;
  final bool isAdmin;

  AnnouncementDetailView({
    super.key,
    required this.announcement,
    this.isAdmin = false,
  });

  final DateFormat _dateFormat = DateFormat('EEEE, MMM d, yyyy • h:mm a');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateText = _dateFormat.format(announcement.createdAt);
    final audienceLabels = _audienceLabels();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcement'),
        centerTitle: true,
        actions: [
          if (isAdmin)
            IconButton(
              tooltip: 'Download PDF',
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onPressed: () => _downloadPdf(context),
            ),
        ],
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Card(
                elevation: 12,
                shadowColor: theme.colorScheme.primary.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color:
                                  theme.colorScheme.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(18),
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
                                  style:
                                      theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  dateText,
                                  style:
                                      theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (isAdmin) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.hourglass_bottom,
                                        size: 18,
                                        color: theme.colorScheme.secondary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _expiryDescription(),
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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
                      if (isAdmin) ...[
                        const SizedBox(height: 32),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant
                                .withOpacity(0.4),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Admin tools',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Download a formatted PDF copy for records or offline sharing.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme
                                      .colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: const Icon(
                                      Icons.picture_as_pdf_outlined),
                                  label: const Text('Download announcement PDF'),
                                  onPressed: () => _downloadPdf(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
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
      await Printing.sharePdf(bytes: bytes, filename: fileName);
      Get.closeCurrentSnackbar();
      Get.snackbar(
        'Download ready',
        'The announcement PDF was generated successfully.',
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
