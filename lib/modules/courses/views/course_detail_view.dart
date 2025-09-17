import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../data/models/course_model.dart';

class CourseDetailView extends StatelessWidget {
  final CourseModel course;

  const CourseDetailView({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(course.title),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMetadataCard(context),
            const SizedBox(height: 24),
            Text(
              'Description',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              course.description.isNotEmpty
                  ? course.description
                  : 'No description provided for this course.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Content',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              course.content.isNotEmpty
                  ? course.content
                  : 'This course does not include additional content yet.',
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Download as PDF'),
                onPressed: () => _downloadPdf(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMetadataRow(
              context,
              icon: Icons.menu_book_outlined,
              label: 'Subject',
              value: course.subjectName.isNotEmpty
                  ? course.subjectName
                  : 'Subject not specified',
            ),
            const SizedBox(height: 12),
            _buildMetadataRow(
              context,
              icon: Icons.person_outline,
              label: 'Teacher',
              value: course.teacherName.isNotEmpty
                  ? course.teacherName
                  : 'Teacher unknown',
            ),
            const SizedBox(height: 16),
            Text(
              'Assigned Classes',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            if (course.classNames.isEmpty)
              Text(
                'This course is not linked to any class.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: course.classNames
                    .map(
                      (name) => Chip(
                        label: Text(name),
                        backgroundColor:
                            theme.colorScheme.primary.withOpacity(0.08),
                        labelStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataRow(BuildContext context,
      {required IconData icon, required String label, required String value}) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
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
      final sanitizedTitle = course.title
          .toLowerCase()
          .replaceAll(RegExp('[^a-z0-9]+'), '_')
          .replaceAll(RegExp('_+'), '_')
          .trim();
      final fileName = sanitizedTitle.isNotEmpty
          ? '${sanitizedTitle}_course.pdf'
          : 'course.pdf';
      await Printing.sharePdf(
        bytes: bytes,
        filename: fileName,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to generate the PDF. ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
