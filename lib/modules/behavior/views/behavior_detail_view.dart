import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/behavior_model.dart';
import '../../common/widgets/module_card.dart';
import '../../common/widgets/module_page_container.dart';
import '../widgets/behavior_type_chip.dart';

class BehaviorDetailView extends StatelessWidget {
  BehaviorDetailView({
    super.key,
    required this.behavior,
    this.onEdit,
    this.onDelete,
  });

  final BehaviorModel behavior;
  final Future<void> Function()? onEdit;
  final Future<void> Function()? onDelete;

  final DateFormat _dateFormat = DateFormat('MMM d, yyyy • h:mm a');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Behavior Details'),
        actions: [
          if (onEdit != null)
            IconButton(
              tooltip: 'Edit record',
              onPressed: () async {
                await onEdit?.call();
              },
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body: ModulePageContainer(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ModuleCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor:
                              theme.colorScheme.primary.withOpacity(0.12),
                          child: Text(
                            _initialsFor(behavior.childName),
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                behavior.childName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                behavior.className,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.person_outline, size: 16),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Teacher: ${behavior.teacherName}',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        BehaviorTypeChip(type: behavior.type),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          _dateFormat.format(behavior.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Description',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ModuleCard(
                child: Text(
                  behavior.description.isEmpty
                      ? 'No description provided.'
                      : behavior.description,
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                ),
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
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit record'),
                      ),
                    if (onDelete != null)
                      OutlinedButton.icon(
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('Delete behavior'),
                                content: const Text(
                                  'Are you sure you want to delete this behavior record?',
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
                        label: const Text('Delete record'),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
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
