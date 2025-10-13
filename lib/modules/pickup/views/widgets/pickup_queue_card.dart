import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/pickup_model.dart';
import '../../../common/widgets/module_card.dart';

class PickupQueueCard extends StatelessWidget {
  const PickupQueueCard({
    super.key,
    required this.ticket,
    required this.timeFormat,
    this.onValidate,
    this.actionLabel,
    this.actionIcon,
    this.trailing,
  });

  final PickupTicketModel ticket;
  final DateFormat timeFormat;
  final VoidCallback? onValidate;
  final String? actionLabel;
  final IconData? actionIcon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metadata = _buildMetadata();
    final stageLabel = _stageLabel(ticket.stage);
    final stageColor = _stageColor(theme, ticket.stage);

    return ModuleCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.childName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${ticket.className} • ${ticket.parentName}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              _StageChip(label: stageLabel, color: stageColor),
            ],
          ),
          const SizedBox(height: 16),
          if (metadata.isNotEmpty)
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: metadata,
            ),
          if (metadata.isNotEmpty) const SizedBox(height: 16),
          Row(
            children: [
              if (onValidate != null)
                FilledButton.icon(
                  onPressed: onValidate,
                  icon: Icon(actionIcon ?? Icons.verified_outlined, size: 18),
                  label: Text(actionLabel ?? 'pickup_action_validate'.tr),
                ),
              if (trailing != null) ...[
                if (onValidate != null) const SizedBox(width: 12),
                trailing!,
              ],
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMetadata() {
    final items = <Widget>[];
    final parentConfirmed = ticket.parentConfirmedAt;
    final teacherValidated = ticket.teacherValidatedAt;
    final adminValidated = ticket.adminValidatedAt;

    items.add(
      _InfoChip(
        icon: Icons.schedule,
        label: 'pickup_metadata_created'.trParams({
          'time': timeFormat.format(ticket.createdAt),
        }),
      ),
    );

    if (parentConfirmed != null) {
      items.add(
        _InfoChip(
          icon: Icons.directions_walk,
          label: 'pickup_metadata_parent_arrived'.trParams({
            'time': timeFormat.format(parentConfirmed),
          }),
        ),
      );
    }

    if (teacherValidated != null) {
      items.add(
        _InfoChip(
          icon: Icons.verified_outlined,
          label: 'pickup_metadata_teacher_released'.trParams({
            'time': timeFormat.format(teacherValidated),
          }),
        ),
      );
    }

    if (adminValidated != null) {
      items.add(
        _InfoChip(
          icon: Icons.admin_panel_settings_outlined,
          label: 'pickup_metadata_admin_released'.trParams({
            'time': timeFormat.format(adminValidated),
          }),
        ),
      );
    }

    return items;
  }
}

class _StageChip extends StatelessWidget {
  const _StageChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
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
}

String _stageLabel(PickupStage stage) {
  switch (stage) {
    case PickupStage.awaitingParent:
      return 'pickup_stage_awaiting_parent'.tr;
    case PickupStage.awaitingTeacher:
      return 'pickup_stage_awaiting_teacher'.tr;
    case PickupStage.awaitingAdmin:
      return 'pickup_stage_awaiting_admin'.tr;
    case PickupStage.completed:
      return 'pickup_stage_completed'.tr;
  }
}

Color _stageColor(ThemeData theme, PickupStage stage) {
  switch (stage) {
    case PickupStage.awaitingParent:
      return theme.colorScheme.secondary;
    case PickupStage.awaitingTeacher:
      return theme.colorScheme.primary;
    case PickupStage.awaitingAdmin:
      return theme.colorScheme.tertiary;
    case PickupStage.completed:
      return theme.colorScheme.onSurfaceVariant;
  }
}
