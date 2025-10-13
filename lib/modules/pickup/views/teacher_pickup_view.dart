import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:edums/core/widgets/module_empty_state.dart';
import 'package:edums/core/widgets/module_page_container.dart';
import '../../../data/models/pickup_model.dart';
import '../controllers/teacher_pickup_controller.dart';
import 'widgets/pickup_queue_card.dart';

class TeacherPickupView extends GetView<TeacherPickupController> {
  const TeacherPickupView({super.key});

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('MMM d • h:mm a');
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        title: Text('pickup_teacher_title'.tr),
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
              const _TeacherPickupFilters(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: controller.refreshTickets,
                  child: tickets.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding:
                              const EdgeInsets.fromLTRB(16, 120, 16, 160),
                          children: [
                            ModuleEmptyState(
                              icon: Icons.directions_car_outlined,
                              title: 'pickup_teacher_empty_title'.tr,
                              message: 'pickup_teacher_empty_message'.tr,
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(16, 16, 16, 32),
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          itemCount: tickets.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final ticket = tickets[index];
                            return PickupQueueCard(
                              ticket: ticket,
                              timeFormat: timeFormat,
                              onValidate: () =>
                                  controller.validatePickup(ticket),
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
                'pickup_teacher_filters_title'.tr,
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
                  label: Text('common_clear'.tr),
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
                    label: 'pickup_filter_chip_class'.trParams({
                      'name': controller.className(classFilter),
                    }),
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
              decoration: InputDecoration(
                labelText: 'pickup_filter_class_label'.tr,
                border: const OutlineInputBorder(),
              ),
              hint: Text(
                isDisabled
                    ? 'pickup_filter_class_empty'.tr
                    : 'pickup_filter_class_all'.tr,
              ),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text('pickup_filter_class_all'.tr),
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
