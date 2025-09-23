import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../data/models/pickup_model.dart';
import '../../common/widgets/module_card.dart';
import '../../common/widgets/module_empty_state.dart';
import '../../common/widgets/module_page_container.dart';
import '../controllers/admin_pickup_controller.dart';

class AdminPickupView extends GetView<AdminPickupController> {
  const AdminPickupView({super.key});

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat.jm();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pickup Validation'),
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
                if (tickets.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 120, 16, 160),
                    children: const [
                      ModuleEmptyState(
                        icon: Icons.security_outlined,
                        title: 'No pickup tickets match',
                        message:
                            'Adjust the filters above to review pickups that require administrative validation.',
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
                          Text(
                            'Stage: ${_stageLabel(ticket.stage)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
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
                          if (ticket.adminValidatedAt != null)
                            Text(
                              'Admin validated at ${timeFormat.format(ticket.adminValidatedAt!)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          if (ticket.stage == PickupStage.awaitingAdmin) ...[
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                onPressed: () => controller.finalizeTicket(ticket),
                                child: const Text('Release'),
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

class _AdminPickupFilters extends StatelessWidget {
  const _AdminPickupFilters();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: GetBuilder<AdminPickupController>(
        builder: (controller) {
          return ModuleCard(
            padding: const EdgeInsets.all(20),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 220,
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
                          (classItem) => DropdownMenuItem<String?>(
                            value: classItem.id,
                            child: Text(classItem.name),
                          ),
                        ),
                      ],
                      onChanged: controller.setClassFilter,
                    );
                  }),
                ),
                SizedBox(
                  width: 220,
                  child: Obx(() {
                    final stageFilter = controller.stageFilter.value;
                    return DropdownButtonFormField<PickupStage?>(
                      value: stageFilter,
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
                    );
                  }),
                ),
              ],
            ),
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
