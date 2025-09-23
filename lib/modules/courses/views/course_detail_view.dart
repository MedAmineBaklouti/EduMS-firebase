import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:edums/core/services/pdf_downloader/pdf_downloader.dart';

import '../../../data/models/course_model.dart';

class CourseDetailView extends StatelessWidget {
  final CourseModel course;
  final Future<void> Function()? onEdit;
  final Future<void> Function()? onDelete;

  CourseDetailView({
    super.key,
    required this.course,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(course.title),
        centerTitle: true,
        actions: [
          if (onEdit != null)
            IconButton(
              tooltip: 'Edit course',
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
            _buildHeroHeader(context),
            const SizedBox(height: 24),
            _buildOverviewCard(context),
            const SizedBox(height: 24),
            _buildSectionCard(
              context,
              title: 'Description',
              child: Text(
                course.description.isNotEmpty
                    ? course.description
                    : 'No description provided for this course.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionCard(
              context,
              title: 'Learning content',
              child: _buildContentBody(context),
            ),
            if (onEdit != null || onDelete != null) ...[
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
                      label: const Text('Edit course'),
                    ),
                  if (onDelete != null)
                    OutlinedButton.icon(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('Delete course'),
                              content: const Text(
                                'Are you sure you want to delete this course?',
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
                      label: const Text('Delete course'),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(
                    Icons.picture_as_pdf_outlined,
                  color: Colors.white,
                ),
                label: const Text('Download as PDF'),
                onPressed: () => _downloadPdf(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    final theme = Theme.of(context);
    final createdLabel = DateFormat('MMM d, yyyy').format(course.createdAt);
    final subject = course.subjectName.isNotEmpty
        ? course.subjectName
        : 'Subject not specified';
    final teacher = course.teacherName.isNotEmpty
        ? course.teacherName
        : 'Teacher unknown';

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
            course.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildHeroChip(
                context,
                icon: Icons.menu_book_outlined,
                label: subject,
              ),
              _buildHeroChip(
                context,
                icon: Icons.person_outline,
                label: teacher,
              ),
              _buildHeroChip(
                context,
                icon: Icons.calendar_today_outlined,
                label: 'Created $createdLabel',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(BuildContext context) {
    final theme = Theme.of(context);
    final classes = course.classNames.toSet().toList();
    final wordCount = _countWords(course.content);

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
              'Course overview',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildOverviewBadge(
                  context,
                  icon: Icons.groups_outlined,
                  label: classes.isEmpty
                      ? 'No classes linked yet'
                      : '${classes.length} class${classes.length == 1 ? '' : 'es'} linked',
                ),
                if (wordCount > 0)
                  _buildOverviewBadge(
                    context,
                    icon: Icons.menu_book,
                    label: '$wordCount word${wordCount == 1 ? '' : 's'} of content',
                  ),
              ],
            ),
            if (classes.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Assigned classes',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: classes
                    .map((name) => _buildClassChip(context, name))
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

  Widget _buildContentBody(BuildContext context) {
    final theme = Theme.of(context);
    final segments = _contentSegments();
    if (segments.isEmpty) {
      return Text(
        'This course does not include additional content yet.',
        style: theme.textTheme.bodyLarge?.copyWith(
          height: 1.6,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }
    if (segments.length == 1) {
      return Text(
        segments.first,
        style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: segments
          .map(
            (segment) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      segment,
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Future<void> _downloadPdf(BuildContext context) async {
    final doc = pw.Document();
    final classList = course.classNames.isEmpty
        ? 'No classes assigned'
        : course.classNames.join(', ');

    doc.addPage(
      pw.MultiPage(
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              course.title,
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Subject: ${course.subjectName.isNotEmpty ? course.subjectName : 'Subject not specified'}',
            style: const pw.TextStyle(fontSize: 14),
          ),
          pw.Text(
            'Teacher: ${course.teacherName.isNotEmpty ? course.teacherName : 'Teacher unknown'}',
            style: const pw.TextStyle(fontSize: 14),
          ),
          pw.Text(
            'Classes: $classList',
            style: const pw.TextStyle(fontSize: 14),
          ),
          pw.Text(
            'Created: ${DateFormat('MMM d, yyyy • h:mm a').format(course.createdAt)}',
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 24),
          pw.Text(
            'Description',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            course.description.isNotEmpty
                ? course.description
                : 'No description provided for this course.',
            style: const pw.TextStyle(fontSize: 13),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Content',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            course.content.isNotEmpty
                ? course.content
                : 'This course does not include additional content yet.',
            style: const pw.TextStyle(fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );

    try {
      final bytes = await doc.save();
      final fileName = _pdfFileName();
      final savedPath = await savePdf(bytes, fileName);
      Get.closeCurrentSnackbar();
      Get.snackbar(
        'Download complete',
        savedPath != null
            ? 'Saved to $savedPath'
            : 'The PDF download has started.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.closeCurrentSnackbar();
      Get.snackbar(
        'Error',
        'Failed to generate the PDF. ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
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

  Widget _buildClassChip(BuildContext context, String name) {
    final theme = Theme.of(context);
    return Chip(
      label: Text(
        name,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: theme.colorScheme.primary.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  List<String> _contentSegments() {
    final raw = course.content.trim();
    if (raw.isEmpty) {
      return [];
    }
    final parts = raw
        .split(RegExp(r'\n+'))
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty)
        .toList();
    return parts.isEmpty ? [raw] : parts;
  }

  int _countWords(String text) {
    final sanitized = text.trim();
    if (sanitized.isEmpty) {
      return 0;
    }
    return sanitized.split(RegExp(r'\s+')).length;
  }

  String _pdfFileName() {
    final trimmed = course.title.trim();
    if (trimmed.isEmpty) {
      return 'Course.pdf';
    }
    final sanitized = trimmed
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return '$sanitized.pdf';
  }
}
