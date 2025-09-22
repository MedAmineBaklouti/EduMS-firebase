import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../data/models/pickup_model.dart';
import '../controllers/admin_pickup_controller.dart';

class AdminPickupView extends GetView<AdminPickupController> {
  const AdminPickupView({super.key});

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat.jm();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pickup Validation'),
      ),
      body: Column(
        children: [
          const _AdminPickupFilters(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              final tickets = controller.tickets;
              if (tickets.isEmpty) {
                return const Center(
                  child: Text('No pickup tickets match the current filters.'),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: tickets.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final ticket = tickets[index];
                  return Card(
                    child: ListTile(
                      title: Text('${ticket.childName} • ${ticket.className}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Stage: ${_stageLabel(ticket.stage)}'),
                          if (ticket.parentConfirmedAt != null)
                            Text(
                              'Parent confirmed at ${timeFormat.format(ticket.parentConfirmedAt!)}',
                            ),
                          if (ticket.teacherValidatedAt != null)
                            Text(
                              'Teacher validated at ${timeFormat.format(ticket.teacherValidatedAt!)}',
                            ),
                          if (ticket.adminValidatedAt != null)
                            Text(
                              'Admin validated at ${timeFormat.format(ticket.adminValidatedAt!)}',
                            ),
                        ],
                      ),
                      trailing: ticket.stage == PickupStage.awaitingAdmin
                          ? ElevatedButton(
                              onPressed: () => controller.finalizeTicket(ticket),
                              child: const Text('Release'),
                            )
                          : null,
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

class _AdminPickupFilters extends StatelessWidget {
  const _AdminPickupFilters();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: GetBuilder<AdminPickupController>(
        builder: (controller) {
          return Wrap(
            runSpacing: 12,
            spacing: 12,
            children: [
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String?>(
                  value: controller.classFilter.value,
                  decoration: const InputDecoration(
                    labelText: 'Class',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All classes'),
                    ),
                    ...controller.classes.map(
                      (classItem) => DropdownMenuItem<String?>(
                        value: classItem.id,
                        child: Text(classItem.name),
                      ),
                    ),
                  ],
                  onChanged: controller.setClassFilter,
                ),
              ),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<PickupStage?>(
                  value: controller.stageFilter.value,
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
                      child: Text('Awaiting teacher'),
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
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

String _stageLabel(PickupStage stage) {
  switch (stage) {
    case PickupStage.awaitingParent:
      return 'Waiting for parent confirmation';
    case PickupStage.awaitingTeacher:
      return 'Waiting for teacher validation';
    case PickupStage.awaitingAdmin:
      return 'Waiting for admin release';
    case PickupStage.completed:
      return 'Completed';
  }
}
