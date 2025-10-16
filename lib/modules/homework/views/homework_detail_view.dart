import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/services/database_service.dart';
import '../../../core/services/pdf_downloader/pdf_downloader.dart';
import '../../common/models/child_model.dart';
import '../models/homework_model.dart';
import '../../common/models/school_class_model.dart';

class HomeworkDetailView extends StatefulWidget {
  const HomeworkDetailView({
    super.key,
    required this.homework,
    this.showParentControls = false,
    this.parentChildren = const [],
    this.isParentLocked = false,
    this.onEdit,
    this.onParentToggle,
    this.initialChildCount,
    this.showTeacherInsights = false,
  });

  final HomeworkModel homework;
  final bool showParentControls;
  final List<ChildModel> parentChildren;
  final bool isParentLocked;
  final Future<void> Function()? onEdit;
  final Future<bool> Function(String childId, bool completed)? onParentToggle;
  final int? initialChildCount;
  final bool showTeacherInsights;

  @override
  State<HomeworkDetailView> createState() => _HomeworkDetailViewState();
}

class _HomeworkDetailViewState extends State<HomeworkDetailView> {
  final DatabaseService _db = Get.find();

  late HomeworkModel _homework;
  List<_ParentChildEntry> _parentEntries = <_ParentChildEntry>[];
  Map<String, _TeacherClassGroup> _teacherChildrenByClass =
      <String, _TeacherClassGroup>{};
  String? _selectedTeacherClassId;
  bool _isTeacherChildrenLoading = false;
  int? _assignedChildrenCount;

  final DateFormat _dateTimeFormat = DateFormat('MMM d, yyyy • h:mm a');

  @override
  void initState() {
    super.initState();
    _homework = widget.homework;
    _assignedChildrenCount = widget.initialChildCount;
    _initializeParentEntries();
    if (widget.showTeacherInsights) {
      _loadTeacherChildren();
    }
  }

  void _initializeParentEntries() {
    if (!widget.showParentControls) {
      return;
    }
    _parentEntries = widget.parentChildren
        .map(
          (child) => _ParentChildEntry(
            child: child,
            completed: widget.homework.isCompletedForChild(child.id),
          ),
        )
        .toList()
      ..sort((a, b) => a.child.name.compareTo(b.child.name));
    if (_parentEntries.isNotEmpty &&
        (_assignedChildrenCount == null || _assignedChildrenCount == 0)) {
      _assignedChildrenCount = _parentEntries.length;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completionStats = _completionStats();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        title: Text(
          _homework.title.isNotEmpty
              ? _homework.title
              : 'homework_detail_title'.tr,
        ),
        centerTitle: true,
        actions: [
          if (widget.onEdit != null)
            IconButton(
              tooltip: 'homework_detail_edit_tooltip'.tr,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                await widget.onEdit?.call();
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
            _buildOverviewCard(context, completionStats),
            const SizedBox(height: 24),
            _buildSectionCard(
              context,
              title: 'homework_detail_title'.tr,
              child: Text(
                _homework.description.isNotEmpty
                    ? _homework.description
                    : 'homework_detail_no_description'.tr,
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
            if (widget.showTeacherInsights) ...[
              const SizedBox(height: 24),
              _buildTeacherChildrenCard(context),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(
                  Icons.picture_as_pdf_outlined,
                  color: Colors.white,
                ),
                label: Text('homework_detail_download_pdf'.tr),
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
        label: 'homework_due_date'.trParams({
          'date': DateFormat('MMM d, yyyy').format(_homework.dueDate),
        }),
      ),
      _buildHeroChip(
        context,
        icon: Icons.calendar_today_outlined,
        label: 'homework_assigned_date'.trParams({
          'date': DateFormat('MMM d, yyyy').format(_homework.assignedDate),
        }),
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
            _homework.title.isNotEmpty
                ? _homework.title
                : 'homework_hero_title_fallback'.tr,
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
    String? childStatusSummary;
    if (widget.showParentControls) {
      if (_parentEntries.isEmpty) {
        childStatusSummary = 'homework_parent_no_children'.tr;
      } else {
        final completed =
            _parentEntries.where((entry) => entry.completed).length;
        final total = _parentEntries.length;
        childStatusSummary = 'homework_parent_completion_summary'.trParams({
          'completed': '$completed',
          'total': '$total',
        });
      }
    } else if (widget.showTeacherInsights) {
      final total = _assignedChildrenCount ?? 0;
      if (total > 0) {
        final completed =
            _homework.completionByChildId.values.where((value) => value).length;
        childStatusSummary = 'homework_teacher_completion_summary'.trParams({
          'completed': '$completed',
          'total': '$total',
        });
      }
    }

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
              'homework_overview_title'.tr,
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
                  label: 'homework_assigned_date'.trParams({
                    'date':
                        DateFormat('MMM d, yyyy').format(_homework.assignedDate),
                  }),
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
    final isLocked = widget.isParentLocked;

    if (_parentEntries.isEmpty) {
      return _buildSectionCard(
        context,
        title: 'homework_manage_completion_title'.tr,
        child: Text(
          'homework_parent_no_children'.tr,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      );
    }

    return _buildSectionCard(
      context,
      title: 'homework_manage_completion_title'.tr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isLocked
                ? 'homework_manage_completion_locked'.tr
                : 'homework_manage_completion_hint'.tr,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isLocked
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: isLocked ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _parentEntries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final entry = _parentEntries[index];
              final statusColor =
                  entry.completed ? Colors.green : theme.colorScheme.secondary;
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: statusColor.withOpacity(0.08),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      entry.completed
                          ? Icons.check_circle_outline
                          : Icons.hourglass_bottom_outlined,
                      color: statusColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.child.name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            entry.completed
                                ? 'homework_status_completed'.tr
                                : 'homework_status_pending'.tr,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Checkbox(
                      value: entry.completed,
                      onChanged: isLocked
                          ? null
                          : (value) {
                              if (value == null) {
                                return;
                              }
                              _toggleParentChild(entry.child.id, value);
                            },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherChildrenCard(BuildContext context) {
    final theme = Theme.of(context);

    if (_isTeacherChildrenLoading) {
      return _buildSectionCard(
        context,
        title: 'homework_teacher_progress_title'.tr,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_teacherChildrenByClass.isEmpty) {
      return _buildSectionCard(
        context,
        title: 'homework_teacher_progress_title'.tr,
        child: Text(
          'homework_teacher_progress_empty'.tr,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      );
    }

    final classIds = _teacherChildrenByClass.keys.toList();
    final selectedId =
        _selectedTeacherClassId ?? (classIds.isNotEmpty ? classIds.first : null);
    final selectedGroup =
        selectedId != null ? _teacherChildrenByClass[selectedId] : null;

    return _buildSectionCard(
      context,
      title: 'homework_teacher_progress_title'.tr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (classIds.length > 1)
            DropdownButtonFormField<String>(
              value: selectedId,
              decoration: InputDecoration(
                labelText: 'homework_filter_label_class'.tr,
                border: const OutlineInputBorder(),
              ),
              items: classIds
                  .map(
                    (id) => DropdownMenuItem<String>(
                      value: id,
                      child: Text(
                        _teacherChildrenByClass[id]?.className.isNotEmpty == true
                            ? _teacherChildrenByClass[id]!.className
                            : 'homework_filter_label_class'.tr,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _selectedTeacherClassId = value;
                });
              },
            )
          else if (selectedGroup != null)
            Text(
              selectedGroup.className.isNotEmpty
                  ? selectedGroup.className
                  : 'homework_teacher_progress_overview'.tr,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (selectedGroup != null) ...[
            const SizedBox(height: 12),
            Text(
              'homework_teacher_progress_summary'.trParams({
                'completed':
                    '${selectedGroup.children.where((child) => child.completed).length}',
                'total': '${selectedGroup.children.length}',
              }),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (selectedGroup.children.isEmpty)
              Text(
                'homework_teacher_progress_none'.tr,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: selectedGroup.children.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final entry = selectedGroup.children[index];
                  final statusColor = entry.completed
                      ? Colors.green
                      : theme.colorScheme.secondary;
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: statusColor.withOpacity(0.08),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          entry.completed
                              ? Icons.check_circle_outline
                              : Icons.hourglass_bottom_outlined,
                          color: statusColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.child.name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                       Text(
                          entry.completed
                              ? 'homework_status_completed'.tr
                              : 'homework_status_pending'.tr,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
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
    if (widget.showParentControls && _parentEntries.isNotEmpty) {
      final completed =
          _parentEntries.where((entry) => entry.completed).length;
      final total = _parentEntries.length;
      return 'homework_parent_summary_partial'
          .trParams({'completed': '$completed', 'total': '$total'});
    }

    final total = _assignedChildrenCount ?? _homework.completionByChildId.length;
    if (total <= 0) {
      return 'homework_completion_none'.tr;
    }
    final completed =
        _homework.completionByChildId.values.where((value) => value).length;
    return 'homework_parent_summary_partial'
        .trParams({'completed': '$completed', 'total': '$total'});
  }

  String _dueStatusLabel() {
    final now = DateTime.now();
    if (_homework.dueDate.isBefore(now)) {
      return 'homework_due_status_past'.tr;
    }
    final difference = _homework.dueDate.difference(now);
    if (difference.inDays >= 1) {
      final count = difference.inDays;
      return count == 1
          ? 'homework_due_status_day'.trParams({'count': '$count'})
          : 'homework_due_status_days'.trParams({'count': '$count'});
    }
    if (difference.inHours >= 1) {
      final count = difference.inHours;
      return count == 1
          ? 'homework_due_status_hour'.trParams({'count': '$count'})
          : 'homework_due_status_hours'.trParams({'count': '$count'});
    }
    final minutes = difference.inMinutes;
    if (minutes <= 0) {
      return 'homework_due_status_soon'.tr;
    }
    return minutes == 1
        ? 'homework_due_status_minute'.trParams({'count': '$minutes'})
        : 'homework_due_status_minutes'.trParams({'count': '$minutes'});
  }

  Future<void> _toggleParentChild(String childId, bool value) async {
    if (widget.onParentToggle == null) {
      return;
    }
    final index =
        _parentEntries.indexWhere((entry) => entry.child.id == childId);
    if (index == -1) {
      return;
    }

    final previousEntry = _parentEntries[index];
    final previousMap = Map<String, bool>.from(_homework.completionByChildId);

    setState(() {
      _parentEntries[index] = previousEntry.copyWith(completed: value);
      final updatedMap = Map<String, bool>.from(_homework.completionByChildId)
        ..[childId] = value;
      _homework = _homework.copyWith(completionByChildId: updatedMap);
    });

    var success = false;
    try {
      success = await widget.onParentToggle!(childId, value);
    } catch (_) {
      success = false;
    }

    if (!success && mounted) {
      setState(() {
        _parentEntries[index] = previousEntry;
        _homework =
            _homework.copyWith(completionByChildId: previousMap);
      });
    }
  }

  Future<void> _loadTeacherChildren() async {
    setState(() {
      _isTeacherChildrenLoading = true;
    });

    final classGroups = <String, _TeacherClassGroup>{};
    final classIds = <String>{};
    if (widget.homework.classId.isNotEmpty) {
      classIds.add(widget.homework.classId);
    }

    try {
      for (final classId in classIds) {
        final classDoc =
            await _db.firestore.collection('classes').doc(classId).get();
        if (!classDoc.exists) {
          continue;
        }
        final classModel = SchoolClassModel.fromDoc(classDoc);
        final children = await _fetchChildrenByIds(classModel.childIds);
        final statuses = children
            .map(
              (child) => _TeacherChildStatus(
                child: child,
                completed: widget.homework.isCompletedForChild(child.id),
              ),
            )
            .toList()
          ..sort((a, b) => a.child.name.compareTo(b.child.name));
        classGroups[classId] = _TeacherClassGroup(
          classId: classId,
          className: classModel.name,
          children: statuses,
        );
      }

      final knownChildIds = classGroups.values
          .expand((group) => group.children.map((entry) => entry.child.id))
          .toSet();
      final completionIds = widget.homework.completionByChildId.keys
          .where((id) => id.isNotEmpty)
          .toSet();
      final missingIds =
          completionIds.difference(knownChildIds).toList(growable: false);

      if (missingIds.isNotEmpty) {
        final extraChildren = await _fetchChildrenByIds(missingIds);
        for (final child in extraChildren) {
          final classId = child.classId;
          final group = classGroups.putIfAbsent(
            classId,
            () => _TeacherClassGroup(
              classId: classId,
              className: '',
              children: <_TeacherChildStatus>[],
            ),
          );
          group.children.add(
            _TeacherChildStatus(
              child: child,
              completed: widget.homework.isCompletedForChild(child.id),
            ),
          );
        }
      }

      final unresolvedClassIds = classGroups.entries
          .where((entry) => entry.value.className.isEmpty)
          .map((entry) => entry.key)
          .toList();
      for (final classId in unresolvedClassIds) {
        final doc =
            await _db.firestore.collection('classes').doc(classId).get();
        if (doc.exists) {
          final classModel = SchoolClassModel.fromDoc(doc);
          final group = classGroups[classId];
          if (group != null) {
            classGroups[classId] = group.copyWith(className: classModel.name);
          }
        }
      }

      for (final group in classGroups.values) {
        group.children.sort((a, b) => a.child.name.compareTo(b.child.name));
      }

      final totalAssigned = classGroups.values
          .fold<int>(0, (sum, group) => sum + group.children.length);
      final selectedId = _selectedTeacherClassId ??
          (classGroups.isNotEmpty ? classGroups.keys.first : null);

      if (!mounted) {
        return;
      }
      setState(() {
        _teacherChildrenByClass = classGroups;
        _selectedTeacherClassId = selectedId;
        if (totalAssigned > 0) {
          _assignedChildrenCount = totalAssigned;
        }
        _isTeacherChildrenLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isTeacherChildrenLoading = false;
      });
      Get.snackbar(
        'homework_pdf_load_failed_title'.tr,
        'homework_pdf_load_failed_message'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<List<ChildModel>> _fetchChildrenByIds(List<String> ids) async {
    if (ids.isEmpty) {
      return <ChildModel>[];
    }
    final uniqueIds = ids.where((id) => id.isNotEmpty).toSet().toList();
    final results = <ChildModel>[];
    for (var i = 0; i < uniqueIds.length; i += 10) {
      final end = (i + 10) > uniqueIds.length ? uniqueIds.length : i + 10;
      final chunk = uniqueIds.sublist(i, end);
      final snapshot = await _db.firestore
          .collection('children')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      results.addAll(snapshot.docs.map(ChildModel.fromDoc));
    }
    return results;
  }

  Future<void> _downloadPdf(BuildContext context) async {
    final doc = pw.Document();
    final completionStats = _completionStats();
    final parentStatusLines = widget.showParentControls &&
            _parentEntries.isNotEmpty
        ? _parentEntries
            .map(
              (entry) =>
                  '${entry.child.name}: ${entry.completed ? 'homework_status_completed'.tr : 'homework_status_pending'.tr}',
            )
            .toList()
        : const <String>[];
    final teacherStatusLines = widget.showTeacherInsights &&
            _teacherChildrenByClass.isNotEmpty
        ? _teacherChildrenByClass.values
            .map(
              (group) {
                final completed =
                    group.children.where((child) => child.completed).length;
                final label = group.className.isNotEmpty
                    ? group.className
                    : 'homework_filter_label_class'.tr;
                final summary = 'homework_parent_summary_partial'.trParams({
                  'completed': '$completed',
                  'total': '${group.children.length}',
                });
                return '$label: $summary';
              },
            )
            .toList()
        : const <String>[];

    doc.addPage(
      pw.MultiPage(
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              _homework.title.isNotEmpty
                  ? _homework.title
                  : 'homework_hero_title_fallback'.tr,
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'homework_filter_chip_class'.trParams({
              'class': _homework.className.isNotEmpty
                  ? _homework.className
                  : 'common_not_specified'.tr,
            }),
            style: const pw.TextStyle(fontSize: 14),
          ),
          pw.Text(
            'homework_pdf_teacher_label'.trParams({
              'name': _homework.teacherName.isNotEmpty
                  ? _homework.teacherName
                  : 'common_not_specified'.tr,
            }),
            style: const pw.TextStyle(fontSize: 14),
          ),
          pw.Text(
            'homework_pdf_assigned_label'
                .trParams({'date': _dateTimeFormat.format(_homework.assignedDate)}),
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.Text(
            'homework_pdf_due_label'
                .trParams({'date': _dateTimeFormat.format(_homework.dueDate)}),
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'homework_pdf_completion_summary'.tr,
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
          if (parentStatusLines.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Text(
              'homework_pdf_per_child'.tr,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            ...parentStatusLines.map(
              (line) => pw.Text(
                line,
                style: const pw.TextStyle(fontSize: 12),
              ),
            ),
          ],
          if (teacherStatusLines.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Text(
              'homework_pdf_class_summaries'.tr,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            ...teacherStatusLines.map(
              (line) => pw.Text(
                line,
                style: const pw.TextStyle(fontSize: 12),
              ),
            ),
          ],
          pw.SizedBox(height: 20),
          pw.Text(
            'homework_pdf_section_details'.tr,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            _homework.description.isNotEmpty
                ? _homework.description
                : 'homework_pdf_no_details'.tr,
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
        'common_download_complete'.tr,
        savedPath != null
            ? 'homework_pdf_saved_to'.trParams({'path': savedPath})
            : 'homework_pdf_not_saved'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.closeCurrentSnackbar();
      Get.snackbar(
        'common_error'.tr,
        'homework_pdf_error_message'.trParams({'error': e.toString()}),
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

class _ParentChildEntry {
  const _ParentChildEntry({required this.child, required this.completed});

  final ChildModel child;
  final bool completed;

  _ParentChildEntry copyWith({bool? completed}) {
    return _ParentChildEntry(
      child: child,
      completed: completed ?? this.completed,
    );
  }
}

class _TeacherChildStatus {
  _TeacherChildStatus({required this.child, required this.completed});

  final ChildModel child;
  final bool completed;
}

class _TeacherClassGroup {
  _TeacherClassGroup({
    required this.classId,
    required this.className,
    required this.children,
  });

  final String classId;
  final String className;
  final List<_TeacherChildStatus> children;

  _TeacherClassGroup copyWith({String? className, List<_TeacherChildStatus>? children}) {
    return _TeacherClassGroup(
      classId: classId,
      className: className ?? this.className,
      children: children ?? this.children,
    );
  }
}
