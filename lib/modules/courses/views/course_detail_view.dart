import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/widgets/modern_scaffold.dart';
import '../../../data/models/course_model.dart';

class CourseDetailView extends StatelessWidget {
  final CourseModel course;

  const CourseDetailView({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ModernScaffold(
      appBar: AppBar(
        title: Text(course.title),
        centerTitle: true,
      ),
      alignment: Alignment.topCenter,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMetadataCard(context),
                const SizedBox(height: 24),
                _buildSectionTitle(context, 'Description'),
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
                _buildSectionTitle(context, 'Content'),
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
                  child: FilledButton.icon(
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Download as PDF'),
                    onPressed: () => _downloadPdf(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String label) {
    final theme = Theme.of(context);
    return Text(
      label,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildMetadataCard(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.08),
            blurRadius: 32,
            offset: const Offset(0, 20),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.08),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
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
          pw.Paragraph(text: 'Subject: ${course.subjectName}'),
          pw.Paragraph(text: 'Teacher: ${course.teacherName}'),
          pw.Paragraph(text: 'Classes: $classList'),
          pw.SizedBox(height: 20),
          pw.Text('Description', style: pw.TextStyle(fontSize: 18)),
          pw.SizedBox(height: 8),
          pw.Paragraph(
            text: course.description.isNotEmpty
                ? course.description
                : 'No description provided.',
          ),
          pw.SizedBox(height: 20),
          pw.Text('Content', style: pw.TextStyle(fontSize: 18)),
          pw.SizedBox(height: 8),
          pw.Paragraph(
            text: course.content.isNotEmpty
                ? course.content
                : 'No additional content provided.',
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: '${course.title}.pdf',
    );
  }
}
