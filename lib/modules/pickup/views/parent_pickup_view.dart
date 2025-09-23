import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../data/models/pickup_model.dart';
import '../../common/widgets/module_card.dart';
import '../../common/widgets/module_empty_state.dart';
import '../../common/widgets/module_page_container.dart';
import '../controllers/parent_pickup_controller.dart';

class ParentPickupView extends GetView<ParentPickupController> {
  const ParentPickupView({super.key});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.jm();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pickup Confirmation'),
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
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 120, 16, 160),
                    children: const [
                      ModuleEmptyState(
                        icon: Icons.local_taxi_outlined,
                        title: 'No pickup tickets available',
                        message:
                            'When the school opens pickup for your children, the tickets will appear here.',
                      ),
                    ],
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  physics: const BouncingScrollPhysics(),
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
                                'Created ${dateFormat.format(ticket.createdAt)}',
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
                                child: const Text('Confirm pickup'),
                              ),
                            ),
                          ] else if (ticket.parentConfirmedAt != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Confirmed at ${dateFormat.format(ticket.parentConfirmedAt!)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.green,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: GetBuilder<ParentPickupController>(
        builder: (controller) {
          return ModuleCard(
            padding: const EdgeInsets.all(20),
            child: Obx(() {
              final childFilter = controller.childFilter.value;
              final children = controller.children;
              return DropdownButtonFormField<String?>(
                value: childFilter,
                decoration: const InputDecoration(
                  labelText: 'Child',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All children'),
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
          );
        },
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
        label = 'Awaiting parent';
        break;
      case PickupStage.awaitingTeacher:
        color = Colors.blue;
        label = 'Teacher validation';
        break;
      case PickupStage.awaitingAdmin:
        color = Colors.purple;
        label = 'Admin validation';
        break;
      case PickupStage.completed:
        color = Colors.green;
        label = 'Completed';
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
