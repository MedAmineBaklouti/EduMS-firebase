import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../data/models/pickup_model.dart';
import '../controllers/parent_pickup_controller.dart';

class ParentPickupView extends GetView<ParentPickupController> {
  const ParentPickupView({super.key});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.jm();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pickup Confirmation'),
      ),
      body: Column(
        children: [
          const _ParentPickupFilters(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              final tickets = controller.tickets;
              if (tickets.isEmpty) {
                return const Center(
                  child: Text('No pickup tickets available at the moment.'),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: tickets.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final ticket = tickets[index];
                  final stage = ticket.stage;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ticket.childName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ticket.className,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _PickupStageChip(stage: stage),
                              Text(
                                'Created ${dateFormat.format(ticket.createdAt)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          if (stage == PickupStage.awaitingParent) ...[
                            const SizedBox(height: 12),
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
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.green[700]),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _ParentPickupFilters extends StatelessWidget {
  const _ParentPickupFilters();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: GetBuilder<ParentPickupController>(
        builder: (controller) {
          return DropdownButtonFormField<String?>(
            value: controller.childFilter.value,
            decoration: const InputDecoration(
              labelText: 'Child',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('All children'),
              ),
              ...controller.children.map(
                (child) => DropdownMenuItem<String?>(
                  value: child.id,
                  child: Text(child.name),
                ),
              ),
            ],
            onChanged: controller.setChildFilter,
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
        label = 'Waiting for teacher';
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
    return Chip(
      label: Text(label),
      backgroundColor: color.withOpacity(0.15),
      labelStyle: TextStyle(color: color),
    );
  }
}
