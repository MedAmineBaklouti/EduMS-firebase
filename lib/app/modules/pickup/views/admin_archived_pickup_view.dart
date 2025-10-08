import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../data/models/pickup_model.dart';
import '../../common/widgets/module_empty_state.dart';
import '../../common/widgets/module_page_container.dart';
import '../../attendance/views/widgets/attendance_date_card.dart';
import '../controllers/admin_archived_pickup_controller.dart';
import 'pickup_ticket_detail_view.dart';

class AdminArchivedPickupView extends GetView<AdminArchivedPickupController> {
  const AdminArchivedPickupView({super.key});

  @override
  Widget build(BuildContext context) {
    final archivedFormat = DateFormat.yMMMMd().add_jm();
    final dateFormat = DateFormat.yMMMMd();
    final timeFormat = DateFormat.jm();
    final headerFormat = DateFormat.yMMMMEEEEd();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Archived Pickups'),
        centerTitle: true,
      ),
      body: ModulePageContainer(
        child: Column(
          children: [
            const _AdminArchivedPickupFilters(),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                final tickets = controller.tickets;
                final grouped = groupBy<PickupTicketModel, DateTime>(
                  tickets,
                  (ticket) {
                    final archivedAt =
                        ticket.archivedAt ?? ticket.adminValidatedAt ?? ticket.createdAt;
                    return DateTime(archivedAt.year, archivedAt.month, archivedAt.day);
                  },
                ).entries.toList()
                  ..sort((a, b) => b.key.compareTo(a.key));
                return RefreshIndicator(
                  onRefresh: controller.refreshTickets,
                  child: tickets.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 120, 16, 160),
                          children: const [
                            ModuleEmptyState(
                              icon: Icons.archive_outlined,
                              title: 'No archived pickups',
                              message:
                                  'Completed pickups will be stored here once they are validated.',
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          itemCount: grouped.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return _ArchiveListSummary(
                                total: tickets.length,
                                range: controller.dateFilter.value,
                              );
                            }
                            final entry = grouped[index - 1];
                            final dayTickets = List<PickupTicketModel>.from(entry.value)
                              ..sort((a, b) {
                                final aDate =
                                    a.archivedAt ?? a.adminValidatedAt ?? a.createdAt;
                                final bDate =
                                    b.archivedAt ?? b.adminValidatedAt ?? b.createdAt;
                                return bDate.compareTo(aDate);
                              });
                            final theme = Theme.of(context);
                            final colors = theme.colorScheme;
                            return Padding(
                              padding: EdgeInsets.only(top: index == 1 ? 20 : 32),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        headerFormat.format(entry.key),
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        '${dayTickets.length} pickup${dayTickets.length == 1 ? '' : 's'}',
                                        style: theme.textTheme.labelLarge?.copyWith(
                                          color: colors.onSurfaceVariant,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  ...List.generate(dayTickets.length, (itemIndex) {
                                    final ticket = dayTickets[itemIndex];
                                    return Padding(
                                      padding: EdgeInsets.only(top: itemIndex == 0 ? 0 : 16),
                                      child: _ArchiveTicketCard(
                                        ticket: ticket,
                                        controller: controller,
                                        archivedFormat: archivedFormat,
                                        dateFormat: dateFormat,
                                        timeFormat: timeFormat,
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            );
                          },
                        ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminArchivedPickupFilters extends StatelessWidget {
  const _AdminArchivedPickupFilters();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminArchivedPickupController>();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() {
            final hasFilters =
                (controller.classFilter.value ?? '').isNotEmpty ||
                    controller.dateFilter.value != null;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter archive',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton.icon(
                  onPressed: hasFilters ? controller.clearFilters : null,
                  icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                  label: const Text('Clear'),
                ),
              ],
            );
          }),
          const SizedBox(height: 12),
          Obx(() {
            final chips = <Widget>[];
            final classId = controller.classFilter.value;
            if (classId != null && classId.isNotEmpty) {
              chips.add(
                _FilterChip(
                  label: 'Class: ${controller.className(classId)}',
                  onRemoved: () => controller.setClassFilter(null),
                ),
              );
            }
            final range = controller.dateFilter.value;
            if (range != null) {
              final format = DateFormat.yMMMd();
              chips.add(
                _FilterChip(
                  label: 'Dates: ${format.format(range.start)} – ${format.format(range.end)}',
                  onRemoved: () => controller.setDateFilter(null),
                ),
              );
            }
            if (chips.isEmpty) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: chips,
              ),
            );
          }),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 720;
              final classFieldWidth =
                  isWide ? constraints.maxWidth / 3 - 8 : constraints.maxWidth;
              final dateFieldWidth = isWide
                  ? classFieldWidth
                  : (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: classFieldWidth,
                    child: Obx(() {
                      final classes = controller.classes;
                      final value = controller.classFilter.value;
                      return DropdownButtonFormField<String?>(
                        value: value,
                        decoration: const InputDecoration(
                          labelText: 'Class',
                          border: OutlineInputBorder(),
                        ),
                        hint: const Text('All classes'),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All classes'),
                          ),
                          ...classes.map(
                            (item) => DropdownMenuItem<String?>(
                              value: item.id,
                              child: Text(item.name),
                            ),
                          ),
                        ],
                        onChanged: controller.setClassFilter,
                      );
                    }),
                  ),
                  SizedBox(
                    width: dateFieldWidth,
                    child: _DateSelectionField(
                      label: 'From',
                      icon: Icons.calendar_today_outlined,
                      selectedDateBuilder: () {
                        final range = controller.dateFilter.value;
                        return range?.start;
                      },
                      onPressed: () async {
                        final now = DateTime.now();
                        final currentRange = controller.dateFilter.value;
                        final baseFirstDate = DateTime(now.year - 3);
                        final baseLastDate = currentRange?.end ?? DateTime(now.year + 1);
                        final firstDate = baseFirstDate.isBefore(baseLastDate)
                            ? baseFirstDate
                            : baseLastDate;
                        final lastDate = baseFirstDate.isBefore(baseLastDate)
                            ? baseLastDate
                            : baseFirstDate;
                        final initialDate = currentRange?.start ?? currentRange?.end ?? now;
                        final clampedInitial = initialDate.isBefore(firstDate)
                            ? firstDate
                            : (initialDate.isAfter(lastDate) ? lastDate : initialDate);
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: firstDate,
                          lastDate: lastDate,
                          initialDate: clampedInitial,
                          helpText: 'Select start date',
                        );
                        if (picked != null) {
                          final end = currentRange?.end;
                          final adjustedEnd = end != null && end.isBefore(picked) ? picked : end;
                          controller.setDateFilter(
                            DateTimeRange(start: picked, end: adjustedEnd ?? picked),
                          );
                        }
                      },
                    ),
                  ),
                  SizedBox(
                    width: dateFieldWidth,
                    child: _DateSelectionField(
                      label: 'To',
                      icon: Icons.event_available_outlined,
                      selectedDateBuilder: () {
                        final range = controller.dateFilter.value;
                        return range?.end;
                      },
                      onPressed: () async {
                        final now = DateTime.now();
                        final currentRange = controller.dateFilter.value;
                        final baseLastDate = DateTime(now.year + 1);
                        final baseFirstDate = currentRange?.start ?? DateTime(now.year - 3);
                        final firstDate = baseFirstDate.isBefore(baseLastDate)
                            ? baseFirstDate
                            : baseLastDate;
                        final lastDate = baseFirstDate.isBefore(baseLastDate)
                            ? baseLastDate
                            : baseFirstDate;
                        final initialDate = currentRange?.end ?? currentRange?.start ?? now;
                        final clampedInitial = initialDate.isBefore(firstDate)
                            ? firstDate
                            : (initialDate.isAfter(lastDate) ? lastDate : initialDate);
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: firstDate,
                          lastDate: lastDate,
                          initialDate: clampedInitial,
                          helpText: 'Select end date',
                        );
                        if (picked != null) {
                          final start = currentRange?.start;
                          final adjustedStart = start != null && start.isAfter(picked) ? picked : start;
                          controller.setDateFilter(
                            DateTimeRange(start: adjustedStart ?? picked, end: picked),
                          );
                        }
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DateSelectionField extends StatelessWidget {
  const _DateSelectionField({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.selectedDateBuilder,
  });

  final String label;
  final IconData icon;
  final Future<void> Function() onPressed;
  final DateTime? Function() selectedDateBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final selectedDate = selectedDateBuilder();
    final format = DateFormat.yMMMd();
    final hasSelection = selectedDate != null;
    final borderRadius = BorderRadius.circular(12);
    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onPressed,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: Border.all(color: colors.outline),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 18, color: colors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasSelection
                          ? format.format(selectedDate!)
                          : 'Select a date',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: hasSelection
                            ? colors.onSurface
                            : colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArchiveListSummary extends StatelessWidget {
  const _ArchiveListSummary({required this.total, required this.range});

  final int total;
  final DateTimeRange? range;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final format = DateFormat.yMMMd();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$total archived pickup${total == 1 ? '' : 's'} found',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (range != null) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colors.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Showing archives from ${format.format(range!.start)} to ${format.format(range!.end)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.onRemoved});

  final String label;
  final VoidCallback onRemoved;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      label: Text(label),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onRemoved,
      backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      labelStyle: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ArchiveTicketCard extends StatelessWidget {
  const _ArchiveTicketCard({
    required this.ticket,
    required this.controller,
    required this.archivedFormat,
    required this.dateFormat,
    required this.timeFormat,
  });

  final PickupTicketModel ticket;
  final AdminArchivedPickupController controller;
  final DateFormat archivedFormat;
  final DateFormat dateFormat;
  final DateFormat timeFormat;

  @override
  Widget build(BuildContext context) {
    final archivedAt = ticket.archivedAt ?? ticket.adminValidatedAt ?? ticket.createdAt;
    final parentTime = ticket.parentConfirmedAt;
    final teacherTime = ticket.teacherValidatedAt;
    final adminTime = ticket.adminValidatedAt;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return AttendanceDateCard(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => Get.to(() => PickupTicketDetailView(ticket: ticket)),
          child: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
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
                            '${controller.className(ticket.classId)} • ${ticket.parentName}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: Text(
                              dateFormat.format(archivedAt),
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colors.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          timeFormat.format(archivedAt),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _ArchiveTimelineStep(
                      icon: Icons.access_time,
                      title: 'Ticket created',
                      subtitle: archivedFormat.format(ticket.createdAt),
                      color: colors.secondary,
                    ),
                    if (parentTime != null)
                      _ArchiveTimelineStep(
                        icon: Icons.check_circle_outline,
                        title: 'Parent confirmed',
                        subtitle: archivedFormat.format(parentTime),
                        color: colors.primary,
                      ),
                    if (teacherTime != null)
                      _ArchiveTimelineStep(
                        icon: Icons.verified_outlined,
                        title: ticket.teacherValidatorName.isNotEmpty
                            ? 'Released by ${ticket.teacherValidatorName}'
                            : 'Teacher released',
                        subtitle: archivedFormat.format(teacherTime),
                        color: colors.tertiary,
                      ),
                    if (adminTime != null)
                      _ArchiveTimelineStep(
                        icon: Icons.admin_panel_settings_outlined,
                        title: ticket.adminValidatorName.isNotEmpty
                            ? 'Validated by ${ticket.adminValidatorName}'
                            : 'Admin validated',
                        subtitle: archivedFormat.format(adminTime),
                        color: colors.primary,
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => Get.to(() => PickupTicketDetailView(ticket: ticket)),
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('View details'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ArchiveTimelineStep extends StatelessWidget {
  const _ArchiveTimelineStep({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 240,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
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
