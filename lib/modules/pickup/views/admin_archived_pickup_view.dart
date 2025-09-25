import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../data/models/pickup_model.dart';
import '../../common/widgets/module_card.dart';
import '../../common/widgets/module_empty_state.dart';
import '../../common/widgets/module_page_container.dart';
import '../controllers/admin_archived_pickup_controller.dart';

class AdminArchivedPickupView extends GetView<AdminArchivedPickupController> {
  const AdminArchivedPickupView({super.key});

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat.yMMMMd().add_jm();
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
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                          physics: AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          itemCount: tickets.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final ticket = tickets[index];
                            final archivedAt =
                                ticket.archivedAt ?? ticket.adminValidatedAt;
                            final teacherTime = ticket.teacherValidatedAt;
                            return ModuleCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ticket.childName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    controller.className(ticket.classId),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Parent: ${ticket.parentName}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  if (teacherTime != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Teacher validated: ${timeFormat.format(teacherTime)}',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                  if (archivedAt != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Archived: ${timeFormat.format(archivedAt)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: Colors.green),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      Chip(
                                        avatar: const Icon(
                                          Icons.access_time,
                                          size: 18,
                                        ),
                                        label: Text(
                                          'Created: ${DateFormat.yMMMMd().add_jm().format(ticket.createdAt)}',
                                        ),
                                      ),
                                      if (ticket.parentConfirmedAt != null)
                                        Chip(
                                          avatar: const Icon(
                                            Icons.verified_user,
                                            size: 18,
                                          ),
                                          label: Text(
                                            'Parent confirmed: ${timeFormat.format(ticket.parentConfirmedAt!)}',
                                          ),
                                        ),
                                    ],
                                  ),
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
                    controller.dateFilter.value != null ||
                    controller.searchQuery.value.isNotEmpty;
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
            final query = controller.searchQuery.value;
            if (query.isNotEmpty) {
              chips.add(
                _FilterChip(
                  label: 'Search: $query',
                  onRemoved: controller.clearSearchQuery,
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
              final fieldWidth =
                  isWide ? constraints.maxWidth / 3 - 8 : double.infinity;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: fieldWidth,
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
                    width: fieldWidth,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final now = DateTime.now();
                        final range = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(now.year - 3),
                          lastDate: DateTime(now.year + 1),
                          currentDate: now,
                          initialDateRange: controller.dateFilter.value,
                        );
                        if (range != null) {
                          controller.setDateFilter(range);
                        }
                      },
                      icon: const Icon(Icons.date_range_outlined),
                      label: const Text('Select dates'),
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: TextField(
                      controller: controller.searchController,
                      decoration: const InputDecoration(
                        labelText: 'Search by child or parent',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.search),
                      ),
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
