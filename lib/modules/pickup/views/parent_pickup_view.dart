import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../models/pickup_model.dart';
import '../../../common/widgets/module_card.dart';
import '../../../common/widgets/module_empty_state.dart';
import '../../../common/widgets/module_page_container.dart';
import '../controllers/parent_pickup_controller.dart';

class ParentPickupView extends GetView<ParentPickupController> {
  const ParentPickupView({super.key});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.jm();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        title: Text('pickup_parent_title'.tr),
        centerTitle: true,
      ),
      body: ModulePageContainer(
        child: Column(
          children: [
            const _ParentPickupFilters(),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                final tickets = controller.tickets;
                if (tickets.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: controller.refreshTickets,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 120, 16, 160),
                      children: [
                        ModuleEmptyState(
                          icon: Icons.local_taxi_outlined,
                          title: 'pickup_parent_empty_title'.tr,
                          message: 'pickup_parent_empty_message'.tr,
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: controller.refreshTickets,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    physics: AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    itemCount: tickets.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                    final ticket = tickets[index];
                    final stage = ticket.stage;
                    return ModuleCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ticket.childName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ticket.className,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _PickupStageChip(stage: stage),
                              Text(
                                'pickup_metadata_created'
                                    .trParams({'time': dateFormat.format(ticket.createdAt)}),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                          if (stage == PickupStage.awaitingParent) ...[
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                onPressed: () => controller.confirmPickup(ticket),
                                child: Text('pickup_parent_confirm_button'.tr),
                              ),
                            ),
                          ] else if (ticket.parentConfirmedAt != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              'pickup_parent_confirmed'.trParams({
                                'time': dateFormat.format(ticket.parentConfirmedAt!),
                              }),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.green,
                                  ),
                            ),
                          ],
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

class _ParentPickupFilters extends StatelessWidget {
  const _ParentPickupFilters();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ParentPickupController>();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() {
            final hasFilter = (controller.childFilter.value ?? '').isNotEmpty;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'pickup_parent_filters_title'.tr,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton.icon(
                  onPressed: hasFilter ? controller.clearFilters : null,
                  icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                  label: Text('common_clear'.tr),
                ),
              ],
            );
          }),
          const SizedBox(height: 12),
          Obx(() {
            final childId = controller.childFilter.value;
            if (childId == null || childId.isEmpty) {
              return const SizedBox.shrink();
            }
            final child = controller.children
                .firstWhereOrNull((element) => element.id == childId);
            final childName = child?.name ?? 'pickup_filter_child_placeholder'.tr;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ActiveFilterChip(
                label:
                    'pickup_filter_chip_child'.trParams({'name': childName}),
                onRemoved: controller.clearFilters,
              ),
            );
          }),
          Obx(() {
            final children = controller.children;
            final childFilter = controller.childFilter.value;
            return DropdownButtonFormField<String?>(
              value: childFilter,
              decoration: InputDecoration(
                labelText: 'pickup_filter_child_label'.tr,
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text('pickup_filter_child_all'.tr),
                ),
                ...children.map(
                  (child) => DropdownMenuItem<String?>(
                    value: child.id,
                    child: Text(child.name),
                  ),
                ),
              ],
              onChanged: controller.setChildFilter,
            );
          }),
        ],
      ),
    );
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

class _PickupStageChip extends StatelessWidget {
  const _PickupStageChip({required this.stage});

  final PickupStage stage;

  @override
  Widget build(BuildContext context) {
    late final Color color;
    late final String label;
    switch (stage) {
      case PickupStage.awaitingParent:
        color = Colors.orange;
        label = 'pickup_stage_awaiting_parent'.tr;
        break;
      case PickupStage.awaitingTeacher:
        color = Colors.blue;
        label = 'pickup_stage_awaiting_teacher'.tr;
        break;
      case PickupStage.awaitingAdmin:
        color = Colors.purple;
        label = 'pickup_stage_awaiting_admin'.tr;
        break;
      case PickupStage.completed:
        color = Colors.green;
        label = 'pickup_stage_completed'.tr;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
