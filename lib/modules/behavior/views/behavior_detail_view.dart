import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/behavior_model.dart';
import '../widgets/behavior_type_chip.dart';

class BehaviorDetailView extends StatelessWidget {
  BehaviorDetailView({
    super.key,
    required this.behavior,
    this.onEdit,
  });

  final BehaviorModel behavior;
  final Future<void> Function()? onEdit;

  final DateFormat _dateFormat = DateFormat('MMM d, yyyy • h:mm a');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Behavior details'),
        centerTitle: true,
        actions: [
          if (onEdit != null)
            IconButton(
              tooltip: 'Edit behavior',
              onPressed: () async {
                await onEdit?.call();
              },
              icon: const Icon(Icons.edit_outlined),
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
                behavior.description.trim().isEmpty
                    ? 'No description was provided for this behavior update.'
                    : behavior.description.trim(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final gradientStart = Color.lerp(primary, Colors.white, 0.1)!;
    final gradientEnd = Color.lerp(primary, Colors.black, 0.15)!;
    final recordedLabel = _dateFormat.format(behavior.createdAt);
    final classLabel = behavior.className.trim().isEmpty
        ? null
        : behavior.className.trim();
    final teacherLabel = behavior.teacherName.trim().isEmpty
        ? null
        : behavior.teacherName.trim();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            gradientStart,
            gradientEnd,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.3),
            blurRadius: 18,
            offset: const Offset(0, 12),
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
                radius: 32,
                backgroundColor: Colors.white.withOpacity(0.18),
                child: Text(
                  _initialsFor(behavior.childName),
                  style: theme.textTheme.titleLarge?.copyWith(
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
                      behavior.childName.trim().isEmpty
                          ? 'Student'
                          : behavior.childName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (classLabel != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        classLabel,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                    ],
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
              _buildHeroChip(
                context,
                icon: _behaviorTypeIcon(behavior.type),
                label: _behaviorTypeHeadline(behavior.type),
              ),
              _buildHeroChip(
                context,
                icon: Icons.schedule,
                label: 'Recorded $recordedLabel',
              ),
              if (teacherLabel != null)
                _buildHeroChip(
                  context,
                  icon: Icons.person_outline,
                  label: 'Teacher: $teacherLabel',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(BuildContext context) {
    final theme = Theme.of(context);
    final badges = <Widget>[
      _buildOverviewBadge(
        context,
        icon: Icons.schedule,
        label: _dateFormat.format(behavior.createdAt),
      ),
    ];

    if (behavior.className.trim().isNotEmpty) {
      badges.add(
        _buildOverviewBadge(
          context,
          icon: Icons.class_outlined,
          label: behavior.className.trim(),
        ),
      );
    }

    if (behavior.teacherName.trim().isNotEmpty) {
      badges.add(
        _buildOverviewBadge(
          context,
          icon: Icons.person_outline,
          label: behavior.teacherName.trim(),
        ),
      );
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
              'Behavior overview',
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
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final summaryText = Text(
                  _behaviorTypeSummary(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                );

                if (constraints.maxWidth < 360) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BehaviorTypeChip(type: behavior.type),
                      const SizedBox(height: 12),
                      summaryText,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BehaviorTypeChip(type: behavior.type),
                    const SizedBox(width: 12),
                    Expanded(child: summaryText),
                  ],
                );
              },
            ),
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

  Widget _buildHeroChip(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white,
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

  IconData _behaviorTypeIcon(BehaviorType type) {
    switch (type) {
      case BehaviorType.positive:
        return Icons.thumb_up_alt_outlined;
      case BehaviorType.negative:
        return Icons.report_outlined;
    }
  }

  String _behaviorTypeHeadline(BehaviorType type) {
    switch (type) {
      case BehaviorType.positive:
        return 'Positive behavior';
      case BehaviorType.negative:
        return 'Needs attention';
    }
  }

  String _behaviorTypeSummary() {
    switch (behavior.type) {
      case BehaviorType.positive:
        return 'This positive note highlights progress, achievements, or conduct worth celebrating.';
      case BehaviorType.negative:
        return 'This entry flags a concern that may require follow-up, guidance, or additional support.';
    }
  }

  String _initialsFor(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '?';
    }
    final parts = trimmed.split(' ');
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    final first = parts.first.substring(0, 1).toUpperCase();
    final last = parts.last.substring(0, 1).toUpperCase();
    return '$first$last';
  }
}
