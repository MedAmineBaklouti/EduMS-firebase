import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/services/pdf_downloader/pdf_downloader.dart';
import '../../../data/models/homework_model.dart';

class HomeworkDetailView extends StatefulWidget {
  const HomeworkDetailView({
    super.key,
    required this.homework,
    this.showParentControls = false,
    this.parentChildId,
    this.parentChildName,
    this.isParentLocked = false,
    this.initialParentCompletion,
    this.onEdit,
    this.onDelete,
    this.onParentToggle,
  });

  final HomeworkModel homework;
  final bool showParentControls;
  final String? parentChildId;
  final String? parentChildName;
  final bool isParentLocked;
  final bool? initialParentCompletion;
  final Future<void> Function()? onEdit;
  final Future<void> Function()? onDelete;
  final Future<bool> Function(bool completed)? onParentToggle;

  @override
  State<HomeworkDetailView> createState() => _HomeworkDetailViewState();
}

class _HomeworkDetailViewState extends State<HomeworkDetailView> {
  late HomeworkModel _homework;
  bool? _parentCompletion;

  final DateFormat _dateTimeFormat = DateFormat('MMM d, yyyy • h:mm a');

  @override
  void initState() {
    super.initState();
    _homework = widget.homework;
    _parentCompletion = widget.initialParentCompletion;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completionStats = _completionStats();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _homework.title.isNotEmpty ? _homework.title : 'Homework details',
        ),
        centerTitle: true,
        actions: [
          if (widget.onEdit != null)
            IconButton(
              tooltip: 'Edit homework',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                await widget.onEdit?.call();
              },
            ),
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
            _buildHeroHeader(context),
            const SizedBox(height: 24),
            _buildOverviewCard(context, completionStats),
            const SizedBox(height: 24),
            _buildSectionCard(
              context,
              title: 'Homework details',
              child: Text(
                _homework.description.isNotEmpty
                    ? _homework.description
                    : 'No additional details were provided for this homework assignment.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (widget.showParentControls) ...[
              const SizedBox(height: 24),
              _buildParentStatusCard(context),
            ],
            if (widget.onEdit != null || widget.onDelete != null) ...[
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
                  if (widget.onEdit != null)
                    ElevatedButton.icon(
                      onPressed: () async {
                        await widget.onEdit?.call();
                      },
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: Colors.white,
                      ),
                      label: const Text('Edit homework'),
                    ),
                  if (widget.onDelete != null)
                    OutlinedButton.icon(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('Delete homework'),
                              content: const Text(
                                'Are you sure you want to delete this homework assignment?',
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
                          await widget.onDelete?.call();
                        }
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete homework'),
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
    final chips = <Widget>[
      _buildHeroChip(
        context,
        icon: Icons.event_available_outlined,
        label: 'Due ${DateFormat('MMM d, yyyy').format(_homework.dueDate)}',
      ),
      _buildHeroChip(
        context,
        icon: Icons.calendar_today_outlined,
        label: 'Assigned ${DateFormat('MMM d, yyyy').format(_homework.assignedDate)}',
      ),
    ];

    if (_homework.className.isNotEmpty) {
      chips.add(
        _buildHeroChip(
          context,
          icon: Icons.group_outlined,
          label: _homework.className,
        ),
      );
    }

    if (_homework.teacherName.isNotEmpty) {
      chips.add(
        _buildHeroChip(
          context,
          icon: Icons.person_outline,
          label: _homework.teacherName,
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
            _homework.title.isNotEmpty ? _homework.title : 'Homework',
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

  Widget _buildOverviewCard(BuildContext context, String completionStats) {
    final theme = Theme.of(context);
    final dueStatus = _dueStatusLabel();
    final childStatusSummary = widget.showParentControls &&
            widget.parentChildId != null &&
            widget.parentChildName != null
        ? '${widget.parentChildName}: ${(_parentCompletion ?? false) ? 'Completed' : 'Pending'}'
        : null;

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
              'Homework overview',
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
                  icon: Icons.access_time,
                  label: dueStatus,
                ),
                _buildOverviewBadge(
                  context,
                  icon: Icons.assignment_turned_in_outlined,
                  label: completionStats,
                ),
                _buildOverviewBadge(
                  context,
                  icon: Icons.school_outlined,
                  label:
                      'Assigned ${DateFormat('MMM d, yyyy').format(_homework.assignedDate)}',
                ),
              ],
            ),
            if (childStatusSummary != null) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(
                    Icons.child_care_outlined,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      childStatusSummary,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
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

  Widget _buildParentStatusCard(BuildContext context) {
    final theme = Theme.of(context);
    final hasChild = widget.parentChildId != null;
    final isLocked = widget.isParentLocked;

    if (!hasChild) {
      return _buildSectionCard(
        context,
        title: 'Completion status',
        child: Text(
          'Select a child from the homework list to update the completion status for this assignment.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      );
    }

    final currentStatus = (_parentCompletion ?? false) ? 'Completed' : 'Pending';
    final statusColor = (_parentCompletion ?? false)
        ? Colors.green
        : theme.colorScheme.secondary;

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
              'Manage completion',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: statusColor.withOpacity(0.08),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Icon(
                  (_parentCompletion ?? false)
                      ? Icons.check_circle_outline
                      : Icons.hourglass_bottom_outlined,
                  color: statusColor,
                ),
                title: Text(
                  'Status for ${widget.parentChildName ?? 'Selected child'}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(currentStatus),
                trailing: Switch.adaptive(
                  value: _parentCompletion ?? false,
                  onChanged: isLocked
                      ? null
                      : (value) {
                          _handleParentToggle(value);
                        },
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (isLocked)
              Text(
                'The due date has passed. This homework can no longer be updated.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              Text(
                'Toggle the switch to mark this homework as completed for ${widget.parentChildName ?? 'the selected child'}.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _completionStats() {
    final total = _homework.completionByChildId.length;
    if (total == 0) {
      return 'No completion updates yet';
    }
    final completed =
        _homework.completionByChildId.values.where((value) => value).length;
    return '$completed of $total completed';
  }

  String _dueStatusLabel() {
    final now = DateTime.now();
    if (_homework.dueDate.isBefore(now)) {
      return 'Past due';
    }
    final difference = _homework.dueDate.difference(now);
    if (difference.inDays >= 1) {
      return 'Due in ${difference.inDays} day${difference.inDays == 1 ? '' : 's'}';
    }
    if (difference.inHours >= 1) {
      return 'Due in ${difference.inHours} hour${difference.inHours == 1 ? '' : 's'}';
    }
    final minutes = difference.inMinutes;
    if (minutes <= 0) {
      return 'Due soon';
    }
    return 'Due in $minutes minute${minutes == 1 ? '' : 's'}';
  }

  Future<void> _handleParentToggle(bool value) async {
    final childId = widget.parentChildId;
    if (childId == null || widget.onParentToggle == null) {
      return;
    }
    final previous = _parentCompletion ?? false;
    final previousHomework = _homework;
    setState(() {
      _parentCompletion = value;
      final updatedMap = Map<String, bool>.from(_homework.completionByChildId)
        ..[childId] = value;
      _homework = _homework.copyWith(completionByChildId: updatedMap);
    });
    var success = false;
    try {
      success = await widget.onParentToggle!(value);
    } catch (_) {
      success = false;
    }
    if (!success) {
      setState(() {
        _parentCompletion = previous;
        _homework = previousHomework;
      });
    }
  }

  Future<void> _downloadPdf(BuildContext context) async {
    final doc = pw.Document();
    final completionStats = _completionStats();
    final childStatus = widget.parentChildName != null &&
            widget.parentChildId != null &&
            _parentCompletion != null
        ? '${widget.parentChildName}: ${(_parentCompletion ?? false) ? 'Completed' : 'Pending'}'
        : null;

    doc.addPage(
      pw.MultiPage(
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              _homework.title.isNotEmpty ? _homework.title : 'Homework',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Class: ${_homework.className.isNotEmpty ? _homework.className : 'Not specified'}',
            style: const pw.TextStyle(fontSize: 14),
          ),
          pw.Text(
            'Teacher: ${_homework.teacherName.isNotEmpty ? _homework.teacherName : 'Not specified'}',
            style: const pw.TextStyle(fontSize: 14),
          ),
          pw.Text(
            'Assigned: ${_dateTimeFormat.format(_homework.assignedDate)}',
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.Text(
            'Due: ${_dateTimeFormat.format(_homework.dueDate)}',
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Completion summary',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            completionStats,
            style: const pw.TextStyle(fontSize: 13),
          ),
          if (childStatus != null) ...[
            pw.SizedBox(height: 6),
            pw.Text(
              childStatus,
              style: const pw.TextStyle(fontSize: 12),
            ),
          ],
          pw.SizedBox(height: 20),
          pw.Text(
            'Homework details',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            _homework.description.isNotEmpty
                ? _homework.description
                : 'No additional details were provided for this homework assignment.',
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

  String _pdfFileName() {
    var sanitizedTitle = (_homework.title.isNotEmpty
            ? _homework.title
            : 'homework_${_homework.id}')
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    sanitizedTitle = sanitizedTitle
        .replaceAll(RegExp(r'^_'), '')
        .replaceAll(RegExp(r'_$'), '');
    final dueDateLabel = DateFormat('yyyyMMdd').format(_homework.dueDate);
    return '${sanitizedTitle.isEmpty ? 'homework' : sanitizedTitle}_$dueDateLabel.pdf';
  }
}
