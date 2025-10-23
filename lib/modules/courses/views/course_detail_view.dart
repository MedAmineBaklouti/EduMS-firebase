import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:edums/common/services/pdf_downloader/pdf_downloader.dart';
import 'package:edums/common/services/settings_service.dart';

import '../models/course_model.dart';

class CourseDetailView extends StatelessWidget {
  final CourseModel course;
  final Future<void> Function()? onEdit;

  CourseDetailView({
    super.key,
    required this.course,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        title: Text(course.title),
        centerTitle: true,
        actions: [
          if (onEdit != null)
            IconButton(
              tooltip: 'courses_action_edit'.tr,
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
              title: 'courses_section_description'.tr,
              child: Text(
                course.description.isNotEmpty
                    ? course.description
                    : 'courses_description_missing'.tr,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionCard(
              context,
              title: 'courses_section_learning_content'.tr,
              child: _buildContentBody(context),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(
                    Icons.picture_as_pdf_outlined,
                  color: Colors.white,
                ),
                label: Text('courses_download_pdf'.tr),
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
        : 'courses_subject_not_specified'.tr;
    final teacher = course.teacherName.isNotEmpty
        ? course.teacherName
        : 'courses_teacher_unknown'.tr;

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
                label:
                    'courses_created_on'.trParams({'date': createdLabel}),
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
              'courses_overview_title'.tr,
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
                      ? 'courses_classes_none'.tr
                      : classes.length == 1
                          ? 'courses_classes_single'.tr
                          : 'courses_classes_plural'.trParams({
                              'count': classes.length.toString(),
                            }),
                ),
                if (wordCount > 0)
                  _buildOverviewBadge(
                    context,
                    icon: Icons.menu_book,
                    label: wordCount == 1
                        ? 'courses_overview_word_count_single'.tr
                        : 'courses_overview_word_count_plural'
                            .trParams({'count': wordCount.toString()}),
                  ),
              ],
            ),
            if (classes.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'courses_overview_assigned_classes'.tr,
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
        'courses_content_missing'.tr,
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
        ? 'courses_class_not_assigned'.tr
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
            'courses_pdf_subject'.trParams({
              'subject': course.subjectName.isNotEmpty
                  ? course.subjectName
                  : 'courses_subject_not_specified'.tr,
            }),
            style: const pw.TextStyle(fontSize: 14),
          ),
          pw.Text(
            'courses_pdf_teacher'.trParams({
              'teacher': course.teacherName.isNotEmpty
                  ? course.teacherName
                  : 'courses_teacher_unknown'.tr,
            }),
            style: const pw.TextStyle(fontSize: 14),
          ),
          pw.Text(
            'courses_pdf_classes'.trParams({'classes': classList}),
            style: const pw.TextStyle(fontSize: 14),
          ),
          pw.Text(
            'courses_pdf_created'.trParams({
              'date': DateFormat('MMM d, yyyy • h:mm a').format(course.createdAt),
            }),
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 24),
          pw.Text(
            'courses_pdf_description'.tr,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          ..._buildPdfTextBlocks(
            value: course.description,
            fallback: 'courses_description_missing'.tr,
            style: const pw.TextStyle(fontSize: 13, height: 1.5),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'courses_pdf_content'.tr,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          ..._buildPdfTextBlocks(
            value: course.content,
            fallback: 'courses_content_missing'.tr,
            style: const pw.TextStyle(fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );

    try {
      final bytes = await doc.save();
      final fileName = _pdfFileName();
      final settings = Get.find<SettingsService>();
      final shouldSave = await settings.confirmPdfSave();
      if (!shouldSave) {
        Get.closeCurrentSnackbar();
        Get.snackbar(
          'common_cancel'.tr,
          'settings_pdf_save_cancelled'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      final savedPath = await savePdf(bytes, fileName);
      Get.closeCurrentSnackbar();
      Get.snackbar(
        'common_download_complete'.tr,
        savedPath != null
            ? 'courses_download_saved_to'
                .trParams({'path': savedPath})
            : 'courses_download_not_saved'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.closeCurrentSnackbar();
      Get.snackbar(
        'common_error'.tr,
        'courses_download_error'.trParams({'error': e.toString()}),
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

  List<pw.Widget> _buildPdfTextBlocks({
    required String value,
    required String fallback,
    required pw.TextStyle style,
    double spacing = 6,
  }) {
    final trimmed = value.trim();
    final paragraphs = trimmed.isEmpty
        ? <String>[fallback]
        : trimmed
            .split(RegExp(r'\n{2,}'))
            .map((paragraph) => paragraph.trim())
            .where((paragraph) => paragraph.isNotEmpty)
            .toList();
    final effectiveParagraphs =
        paragraphs.isEmpty ? <String>[fallback] : paragraphs;

    final widgets = <pw.Widget>[];
    for (var i = 0; i < effectiveParagraphs.length; i++) {
      final paragraph = effectiveParagraphs[i];
      final chunks = _chunkTextForPdf(paragraph);
      for (var j = 0; j < chunks.length; j++) {
        widgets.add(pw.Text(chunks[j], style: style));
        final isLastChunk =
            i == effectiveParagraphs.length - 1 && j == chunks.length - 1;
        if (!isLastChunk) {
          widgets.add(pw.SizedBox(height: spacing));
        }
      }
    }

    return widgets;
  }

  List<String> _chunkTextForPdf(String text, {int maxLength = 900}) {
    final sanitized = text.trim();
    if (sanitized.isEmpty) {
      return const [];
    }

    if (sanitized.length <= maxLength) {
      return [sanitized];
    }

    final words = sanitized.split(RegExp(r'\s+'));
    final chunks = <String>[];
    var buffer = StringBuffer();
    var bufferLength = 0;

    void flushBuffer() {
      if (bufferLength == 0) {
        return;
      }
      chunks.add(buffer.toString());
      buffer = StringBuffer();
      bufferLength = 0;
    }

    for (final word in words) {
      if (word.isEmpty) {
        continue;
      }
      final requiredLength = bufferLength == 0 ? word.length : word.length + 1;
      if (bufferLength > 0 && bufferLength + requiredLength > maxLength) {
        flushBuffer();
      }
      if (bufferLength > 0) {
        buffer.write(' ');
        bufferLength += 1;
      }
      buffer.write(word);
      bufferLength += word.length;
    }

    flushBuffer();
    return chunks.isEmpty ? [sanitized] : chunks;
  }

  String _pdfFileName() {
    final trimmed = course.title.trim();
    if (trimmed.isEmpty) {
      return 'courses_pdf_default_filename'.tr;
    }
    final sanitized = trimmed
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return '$sanitized.pdf';
  }
}
