import 'package:characters/characters.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/services/database_service.dart';
import '../../../data/models/admin_model.dart';
import '../../../data/models/pickup_model.dart';
import '../../../data/models/subject_model.dart';
import '../../../data/models/teacher_model.dart';
import '../../common/widgets/module_card.dart';

class PickupTicketDetailView extends StatelessWidget {
  PickupTicketDetailView({
    super.key,
    required this.ticket,
  });

  final PickupTicketModel ticket;

  final DateFormat _dateFormat = DateFormat('MMM d, yyyy • h:mm a');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pickup detail'),
        centerTitle: true,
      ),
      body: FutureBuilder<_PickupDetailData>(
        future: _loadDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'We were unable to load the pickup detail.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            );
          }
          final detail = snapshot.data ?? const _PickupDetailData();
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroHeader(context, detail),
                const SizedBox(height: 24),
                _buildTimelineCard(context),
                if (detail.teacher != null || detail.admin != null) ...[
                  const SizedBox(height: 24),
                  _buildValidatorCard(context, detail),
                ],
                const SizedBox(height: 24),
                _buildMetadataCard(context, detail),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<_PickupDetailData> _loadDetails() async {
    final db = Get.find<DatabaseService>();
    TeacherModel? teacher;
    SubjectModel? subject;
    AdminModel? admin;

    try {
      if (ticket.teacherValidatorId.isNotEmpty) {
        final teacherSnap = await db.firestore
            .collection('teachers')
            .doc(ticket.teacherValidatorId)
            .get();
        if (teacherSnap.exists) {
          teacher = TeacherModel.fromDoc(teacherSnap);
          if (teacher!.subjectId.isNotEmpty) {
            final subjectSnap = await db.firestore
                .collection('subjects')
                .doc(teacher!.subjectId)
                .get();
            if (subjectSnap.exists) {
              subject = SubjectModel.fromDoc(subjectSnap);
            }
          }
        }
      }

      if (ticket.adminValidatorId.isNotEmpty) {
        final adminSnap = await db.firestore
            .collection('admins')
            .doc(ticket.adminValidatorId)
            .get();
        if (adminSnap.exists) {
          admin = AdminModel.fromFirestore(adminSnap);
        }
      }
    } catch (error) {
      return Future.error(error);
    }

    return _PickupDetailData(
      teacher: teacher,
      subject: subject,
      admin: admin,
    );
  }

  Widget _buildHeroHeader(BuildContext context, _PickupDetailData detail) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final gradientStart = Color.lerp(primary, Colors.white, 0.08)!;
    final gradientEnd = Color.lerp(primary, Colors.black, 0.18)!;
    final stageLabel = _stageHeadline();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [gradientStart, gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.28),
            blurRadius: 22,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: Colors.white.withOpacity(0.18),
                child: Text(
                  _initialsFor(ticket.childName),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.childName.trim().isEmpty
                          ? 'Student'
                          : ticket.childName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      stageLabel,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white.withOpacity(0.85),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _heroChip(
                context,
                icon: Icons.class_outlined,
                label: ticket.className.trim().isEmpty
                    ? 'Class not set'
                    : ticket.className,
              ),
              _heroChip(
                context,
                icon: Icons.family_restroom_outlined,
                label: ticket.parentName.trim().isEmpty
                    ? 'Parent not recorded'
                    : 'Parent: ${ticket.parentName}',
              ),
              _heroChip(
                context,
                icon: Icons.schedule,
                label: 'Created ${_dateFormat.format(ticket.createdAt)}',
              ),
              if (detail.teacher != null)
                _heroChip(
                  context,
                  icon: Icons.school_outlined,
                  label: 'Teacher: ${detail.teacher!.name}',
                ),
              if (detail.admin != null)
                _heroChip(
                  context,
                  icon: Icons.admin_panel_settings_outlined,
                  label: 'Admin: ${detail.admin!.name}',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(BuildContext context) {
    final theme = Theme.of(context);
    final events = <_TimelineEvent>[
      _TimelineEvent(
        icon: Icons.schedule,
        label: 'Ticket created',
        timestamp: ticket.createdAt,
      ),
    ];

    if (ticket.parentConfirmedAt != null) {
      events.add(
        _TimelineEvent(
          icon: Icons.directions_walk,
          label: 'Parent arrived at school',
          timestamp: ticket.parentConfirmedAt!,
        ),
      );
    }

    if (ticket.teacherValidatedAt != null) {
      events.add(
        _TimelineEvent(
          icon: Icons.verified_outlined,
          label: 'Teacher released student',
          timestamp: ticket.teacherValidatedAt!,
        ),
      );
    }

    if (ticket.adminValidatedAt != null) {
      events.add(
        _TimelineEvent(
          icon: Icons.task_alt_outlined,
          label: 'Admin released student',
          timestamp: ticket.adminValidatedAt!,
        ),
      );
    }

    if (ticket.archivedAt != null) {
      events.add(
        _TimelineEvent(
          icon: Icons.archive_outlined,
          label: 'Ticket archived',
          timestamp: ticket.archivedAt!,
        ),
      );
    }

    return ModuleCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Timeline',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          ...events.map((event) => _TimelineTile(
                event: event,
                dateFormat: _dateFormat,
              )),
        ],
      ),
    );
  }

  Widget _buildValidatorCard(
    BuildContext context,
    _PickupDetailData detail,
  ) {
    final theme = Theme.of(context);
    final entries = <Widget>[];

    if (detail.teacher != null) {
      entries.add(
        _validatorTile(
          context,
          title: 'Teacher validation',
          icon: Icons.verified_outlined,
          name: detail.teacher!.name,
          email: detail.teacher!.email,
          subtitle: detail.subject == null
              ? 'Subject not assigned'
              : 'Subject: ${detail.subject!.name}',
          timestamp: ticket.teacherValidatedAt,
        ),
      );
    }

    if (detail.admin != null) {
      if (entries.isNotEmpty) {
        entries.add(const Divider(height: 24));
      }
      entries.add(
        _validatorTile(
          context,
          title: 'Admin validation',
          icon: Icons.admin_panel_settings_outlined,
          name: detail.admin!.name,
          email: detail.admin!.email,
          subtitle: 'Administrator',
          timestamp: ticket.adminValidatedAt,
        ),
      );
    }

    return ModuleCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Validation overview',
            style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          ...entries,
        ],
      ),
    );
  }

  Widget _validatorTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String name,
    required String email,
    required String subtitle,
    required DateTime? timestamp,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                name.isEmpty ? 'Name unavailable' : name,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                email.isEmpty ? 'Email unavailable' : email,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall,
              ),
              if (timestamp != null) ...[
                const SizedBox(height: 4),
                Text(
                  _dateFormat.format(timestamp),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataCard(
    BuildContext context,
    _PickupDetailData detail,
  ) {
    final theme = Theme.of(context);
    final statusLabel = ticket.isArchived ? 'Archived' : _stageHeadline();

    return ModuleCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pickup summary',
            style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _metadataChip(
                context,
                icon: Icons.badge_outlined,
                label: 'Ticket ID: ${ticket.id}',
              ),
              _metadataChip(
                context,
                icon: Icons.people_outline,
                label: 'Parent: ${ticket.parentName}',
              ),
              _metadataChip(
                context,
                icon: Icons.child_care_outlined,
                label: 'Child ID: ${ticket.childId}',
              ),
              _metadataChip(
                context,
                icon: Icons.info_outline,
                label: statusLabel,
              ),
              if (ticket.archivedAt != null)
                _metadataChip(
                  context,
                  icon: Icons.archive_outlined,
                  label: 'Archived ${_dateFormat.format(ticket.archivedAt!)}',
                ),
              if (detail.teacher != null && detail.subject != null)
                _metadataChip(
                  context,
                  icon: Icons.menu_book_outlined,
                  label: 'Subject: ${detail.subject!.name}',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroChip(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    final theme = Theme.of(context);
    return Chip(
      avatar: Icon(icon, size: 18, color: Colors.white),
      label: Text(label),
      backgroundColor: Colors.white.withOpacity(0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      labelStyle: theme.textTheme.bodyMedium?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _metadataChip(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    final theme = Theme.of(context);
    return Chip(
      avatar: Icon(icon, size: 18, color: theme.colorScheme.primary),
      label: Text(label),
      backgroundColor: theme.colorScheme.primary.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      labelStyle: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  String _stageHeadline() {
    if (ticket.releasedByTeacher) {
      return 'Released by ${ticket.teacherValidatorName.isEmpty ? 'teacher' : ticket.teacherValidatorName}';
    }
    if (ticket.releasedByAdmin) {
      return 'Released by ${ticket.adminValidatorName.isEmpty ? 'admin' : ticket.adminValidatorName}';
    }
    if (ticket.isAwaitingTeacher) {
      return 'Waiting for release';
    }
    if (ticket.isAwaitingParent) {
      return 'Waiting for parent';
    }
    return 'Pickup in progress';
  }

  String _initialsFor(String input) {
    final normalized = input.trim();
    if (normalized.isEmpty) {
      return 'ST';
    }
    final parts = normalized.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.length == 1) {
      return parts.first.characters.take(2).toString().toUpperCase();
    }
    final first = parts.first.characters.first;
    final last = parts.last.characters.first;
    return (first + last).toUpperCase();
  }
}

class _PickupDetailData {
  const _PickupDetailData({
    this.teacher,
    this.subject,
    this.admin,
  });

  final TeacherModel? teacher;
  final SubjectModel? subject;
  final AdminModel? admin;
}

class _TimelineEvent {
  const _TimelineEvent({
    required this.icon,
    required this.label,
    required this.timestamp,
  });

  final IconData icon;
  final String label;
  final DateTime timestamp;
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({
    required this.event,
    required this.dateFormat,
  });

  final _TimelineEvent event;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(12),
            child: Icon(event.icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateFormat.format(event.timestamp),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
