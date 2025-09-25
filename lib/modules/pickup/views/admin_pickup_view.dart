import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../data/models/pickup_model.dart';
import '../../common/widgets/module_empty_state.dart';
import '../../common/widgets/module_page_container.dart';
import '../controllers/admin_pickup_controller.dart';
import 'widgets/pickup_queue_card.dart';

class AdminPickupView extends GetView<AdminPickupController> {
  const AdminPickupView({super.key});

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('MMM d • h:mm a');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pickup Queue'),
        centerTitle: true,
      ),
      body: ModulePageContainer(
        child: Column(
          children: [
            const _AdminPickupFilters(),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                final tickets = controller.tickets;
                final items = tickets.toList();
                return RefreshIndicator(
                  onRefresh: controller.refreshTickets,
                  child: items.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 120, 16, 160),
                          children: const [
                            ModuleEmptyState(
                              icon: Icons.security_outlined,
                              title: 'No pickups waiting',
                              message:
                                  'Parents will appear here after they arrive at the school gate.',
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final ticket = items[index];
                            final showAction =
                                ticket.stage == PickupStage.awaitingAdmin && !ticket.isArchived;
                            return PickupQueueCard(
                              ticket: ticket,
                              timeFormat: timeFormat,
                              onValidate:
                                  showAction ? () => controller.finalizeTicket(ticket) : null,
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

class _AdminPickupFilters extends StatelessWidget {
  const _AdminPickupFilters();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminPickupController>();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() {
            final stageValue = controller.stageFilter.value;
            final hasStageFilter =
                stageValue != null && stageValue != PickupStage.awaitingAdmin;
            final hasFilters =
                (controller.classFilter.value ?? '').isNotEmpty || hasStageFilter;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter pickup tickets',
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
            final stage = controller.stageFilter.value;
            if (classId != null && classId.isNotEmpty) {
              chips.add(
                _ActiveFilterChip(
                  label: 'Class: ${controller.className(classId)}',
                  onRemoved: () => controller.setClassFilter(null),
                ),
              );
            }
            if (stage != null && stage != PickupStage.awaitingAdmin) {
              chips.add(
                _ActiveFilterChip(
                  label: 'Status: ${_stageFilterLabel(stage)}',
                  onRemoved: () => controller.setStageFilter(null),
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
              final fieldWidth = isWide
                  ? constraints.maxWidth / 2 - 8
                  : double.infinity;
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
                    child: Obx(() {
                      final value = controller.stageFilter.value;
                      return DropdownButtonFormField<PickupStage?>(
                        value: value,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem<PickupStage?>(
                            value: null,
                            child: Text('All statuses'),
                          ),
                          DropdownMenuItem<PickupStage?>(
                            value: PickupStage.awaitingParent,
                            child: Text('Awaiting parent'),
                          ),
                          DropdownMenuItem<PickupStage?>(
                            value: PickupStage.awaitingTeacher,
                            child: Text('Awaiting release'),
                          ),
                          DropdownMenuItem<PickupStage?>(
                            value: PickupStage.awaitingAdmin,
                            child: Text('Awaiting admin'),
                          ),
                          DropdownMenuItem<PickupStage?>(
                            value: PickupStage.completed,
                            child: Text('Completed'),
                          ),
                        ],
                        onChanged: controller.setStageFilter,
                      );
                    }),
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

String _stageFilterLabel(PickupStage stage) {
  switch (stage) {
    case PickupStage.awaitingParent:
      return 'Awaiting parent';
    case PickupStage.awaitingTeacher:
      return 'Awaiting release';
    case PickupStage.awaitingAdmin:
      return 'Awaiting admin';
    case PickupStage.completed:
      return 'Completed';
  }
}

class _ActiveFilterChip extends StatelessWidget {
  const _ActiveFilterChip({required this.label, required this.onRemoved});

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
