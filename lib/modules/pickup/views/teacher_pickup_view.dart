import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../data/models/pickup_model.dart';
import '../../common/widgets/module_card.dart';
import '../../common/widgets/module_empty_state.dart';
import '../../common/widgets/module_page_container.dart';
import '../controllers/teacher_pickup_controller.dart';

class TeacherPickupView extends GetView<TeacherPickupController> {
  const TeacherPickupView({super.key});

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat.jm();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pickup Queue'),
        centerTitle: true,
      ),
      body: ModulePageContainer(
        child: Column(
          children: [
            const _TeacherPickupFilters(),
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
                        icon: Icons.directions_car_outlined,
                        title: 'No pickup tickets',
                        message:
                            'Parents will appear here when they confirm pickups that require your validation.',
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
                    return ModuleCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${ticket.childName} • ${ticket.className}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 8),
                          _PickupStageChip(stage: ticket.stage),
                          const SizedBox(height: 12),
                          if (ticket.parentConfirmedAt != null)
                            Text(
                              'Parent confirmed at ${timeFormat.format(ticket.parentConfirmedAt!)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          if (ticket.teacherValidatedAt != null)
                            Text(
                              'Teacher validated at ${timeFormat.format(ticket.teacherValidatedAt!)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          if (ticket.stage == PickupStage.awaitingTeacher) ...[
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                onPressed: () => controller.validatePickup(ticket),
                                child: const Text('Validate'),
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

class _TeacherPickupFilters extends StatelessWidget {
  const _TeacherPickupFilters();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: GetBuilder<TeacherPickupController>(
        builder: (controller) {
          return ModuleCard(
            padding: const EdgeInsets.all(20),
            child: Obx(() {
              final classFilter = controller.classFilter.value;
              final classes = controller.classes;
              return DropdownButtonFormField<String?>(
                value: classFilter,
                decoration: const InputDecoration(
                  labelText: 'Class',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All classes'),
                  ),
                  ...classes.map(
                    (schoolClass) => DropdownMenuItem<String?>(
                      value: schoolClass.id,
                      child: Text(schoolClass.name),
                    ),
                  ),
                ],
                onChanged: controller.setClassFilter,
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
        label = 'Ready for teacher';
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
