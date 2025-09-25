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
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              const _TeacherPickupFilters(),
              Expanded(
                child: Builder(
                  builder: (context) {
                    final tickets = controller.tickets;
                    return RefreshIndicator(
                      onRefresh: controller.refreshTickets,
                      child: tickets.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding:
                                  const EdgeInsets.fromLTRB(16, 120, 16, 160),
                              children: const [
                                ModuleEmptyState(
                                  icon: Icons.directions_car_outlined,
                                  title: 'No pickup tickets',
                                  message:
                                      'Parents will appear here when they confirm pickups that require your validation.',
                                ),
                              ],
                            )
                          : ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 16, 16, 32),
                              physics: AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              itemCount: tickets.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final ticket = tickets[index];
                                return ModuleCard(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${ticket.childName} • ${ticket.className}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Stage: ${_stageLabel(ticket.stage)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                      if (ticket.parentConfirmedAt != null)
                                        Text(
                                          'Parent confirmed at ${timeFormat.format(ticket.parentConfirmedAt!)}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      if (ticket.teacherValidatedAt != null)
                                        Text(
                                          'Teacher validated at ${timeFormat.format(ticket.teacherValidatedAt!)}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      if (ticket.adminValidatedAt != null)
                                        Text(
                                          'Admin validated at ${timeFormat.format(ticket.adminValidatedAt!)}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      if (ticket.stage ==
                                          PickupStage.awaitingTeacher) ...[
                                        const SizedBox(height: 16),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: ElevatedButton(
                                            onPressed: () => controller
                                                .validatePickup(ticket),
                                            child: const Text('Validate'),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                    );
                  },
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _TeacherPickupFilters extends StatelessWidget {
  const _TeacherPickupFilters();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.find<TeacherPickupController>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter queue',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Obx(() {
                final hasFilter =
                    (controller.classFilter.value ?? '').isNotEmpty;
                return TextButton.icon(
                  onPressed: hasFilter ? controller.clearFilters : null,
                  icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                  label: const Text('Clear'),
                );
              }),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() {
            final classFilter = controller.classFilter.value;
            if (classFilter == null || classFilter.isEmpty) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ActiveFilterChip(
                    label: 'Class: ${controller.className(classFilter)}',
                    onRemoved: controller.clearFilters,
                  ),
                ],
              ),
            );
          }),
          Obx(() {
            final classes = controller.classes;
            final classFilter = controller.classFilter.value;
            final isDisabled = classes.isEmpty;
            return DropdownButtonFormField<String?>(
              value: classFilter,
              decoration: const InputDecoration(
                labelText: 'Class',
                border: OutlineInputBorder(),
              ),
              hint: Text(
                isDisabled ? 'No classes available' : 'All classes',
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
              onChanged: isDisabled ? null : controller.setClassFilter,
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
      avatar: Icon(
        Icons.filter_alt_outlined,
        size: 18,
        color: theme.colorScheme.primary,
      ),
      label: Text(label),
      deleteIcon: const Icon(Icons.close, size: 18),
      onDeleted: onRemoved,
      backgroundColor: theme.colorScheme.primary.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      labelStyle: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w600,
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
