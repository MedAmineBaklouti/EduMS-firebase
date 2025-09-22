import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../data/models/pickup_model.dart';
import '../controllers/teacher_pickup_controller.dart';

class TeacherPickupView extends GetView<TeacherPickupController> {
  const TeacherPickupView({super.key});

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat.jm();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pickup Queue'),
      ),
      body: Column(
        children: [
          const _TeacherPickupFilters(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              final tickets = controller.tickets;
              if (tickets.isEmpty) {
                return const Center(
                  child: Text('No pickup tickets require attention.'),
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
                        ],
                      ),
                      trailing: ticket.stage == PickupStage.awaitingTeacher
                          ? ElevatedButton(
                              onPressed: () => controller.validatePickup(ticket),
                              child: const Text('Validate'),
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

class _TeacherPickupFilters extends StatelessWidget {
  const _TeacherPickupFilters();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: GetBuilder<TeacherPickupController>(
        builder: (controller) {
          return DropdownButtonFormField<String?>(
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
                (schoolClass) => DropdownMenuItem<String?>(
                  value: schoolClass.id,
                  child: Text(schoolClass.name),
                ),
              ),
            ],
            onChanged: controller.setClassFilter,
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
      return 'Ready for teacher validation';
    case PickupStage.awaitingAdmin:
      return 'Awaiting admin release';
    case PickupStage.completed:
      return 'Completed';
  }
}
