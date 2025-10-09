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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        title: const Text('Pickup Queue'),
        centerTitle: true,
      ),
      body: ModulePageContainer(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final tickets = controller.tickets;

          return Column(
            children: [
              const _AdminPickupFilters(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: controller.refreshTickets,
                  child: tickets.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 120, 16, 160),
                          children: const [
                            ModuleEmptyState(
                              icon: Icons.security_outlined,
                              title: 'No pickups ready',
                              message:
                                  'Once parents confirm their arrival, the pickup will appear here for your validation.',
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          itemCount: tickets.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final ticket = tickets[index];
                            return PickupQueueCard(
                              ticket: ticket,
                              timeFormat: timeFormat,
                              onValidate: () => controller.finalizeTicket(ticket),
                            );
                          },
                        ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _AdminPickupFilters extends StatelessWidget {
  const _AdminPickupFilters();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.find<AdminPickupController>();
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
                final hasFilter = (controller.classFilter.value ?? '').isNotEmpty;
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
