import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/announcement_controller.dart';

class AnnouncementFormView extends StatelessWidget {
  AnnouncementFormView({super.key});

  final AnnouncementController controller = Get.find();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = controller.editing != null;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        title: Text(
          isEditing
              ? 'announcement_form_appbar_edit'.tr
              : 'announcement_form_appbar_add'.tr,
        ),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Form(
                    key: controller.formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          elevation: 0,
                          color: theme.colorScheme.primary.withOpacity(0.08),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    Icons.campaign_outlined,
                                    color: theme.colorScheme.primary,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isEditing
                                            ? 'announcement_form_card_title_edit'.tr
                                            : 'announcement_form_card_title_add'.tr,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'announcement_form_card_message'.tr,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        TextFormField(
                          controller: controller.titleController,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'announcement_form_title_label'.tr,
                            border: const OutlineInputBorder(),
                            hintText: 'announcement_form_title_hint'.tr,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'announcement_form_title_error_empty'.tr;
                            }
                            if (value.trim().length < 4) {
                              return 'announcement_form_title_error_short'.tr;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: controller.descriptionController,
                          minLines: 5,
                          maxLines: 12,
                          maxLength: 600,
                          decoration: InputDecoration(
                            labelText: 'announcement_form_message_label'.tr,
                            alignLabelWithHint: true,
                            border: const OutlineInputBorder(),
                            hintText:
                                'announcement_form_message_hint'.tr,
                            counterText: '',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'announcement_form_message_error_empty'.tr;
                            }
                            if (value.trim().length < 10) {
                              return 'announcement_form_message_error_short'.tr;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: controller.descriptionController,
                          builder: (context, value, _) {
                            final remaining = 600 - value.text.length;
                            return Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                remaining >= 0
                                    ? 'announcement_form_characters_left'
                                        .trParams({'count': '$remaining'})
                                    : 'announcement_form_characters_over_limit'
                                        .trParams({'count': '${remaining.abs()}'})
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: remaining >= 0
                                      ? theme.colorScheme.onSurfaceVariant
                                      : theme.colorScheme.error,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'announcement_form_audience_label'.tr,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Obx(
                          () => Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _buildAudienceChip(
                                context,
                                label: 'announcement_audience_teachers'.tr,
                                icon: Icons.school_outlined,
                                selected: controller.teachersSelected.value,
                                onChanged: (value) =>
                                    controller.teachersSelected.value = value,
                              ),
                              _buildAudienceChip(
                                context,
                                label: 'announcement_audience_parents'.tr,
                                icon: Icons.family_restroom_outlined,
                                selected: controller.parentsSelected.value,
                                onChanged: (value) =>
                                    controller.parentsSelected.value = value,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Obx(() {
                          final hasSelection = controller.teachersSelected.value ||
                              controller.parentsSelected.value;
                          final selectedGroups = <String>[];
                          if (controller.teachersSelected.value) {
                            selectedGroups.add(
                                'announcement_audience_teachers'.tr);
                          }
                          if (controller.parentsSelected.value) {
                            selectedGroups.add(
                                'announcement_audience_parents'.tr);
                          }
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: hasSelection
                                  ? theme.colorScheme.surfaceVariant
                                      .withOpacity(0.45)
                                  : theme.colorScheme.error.withOpacity(0.1),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  hasSelection
                                      ? Icons.check_circle_outline
                                      : Icons.error_outline,
                                  color: hasSelection
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.error,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    hasSelection
                                        ? 'announcement_form_summary_selected'
                                            .trParams({
                                                'audiences':
                                                    selectedGroups.join(', ')
                                              })
                                        : 'announcement_form_summary_empty'.tr,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: hasSelection
                                          ? theme.colorScheme.onSurfaceVariant
                                          : theme.colorScheme.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 36),
                        Obx(() {
                          final saving = controller.isSaving.value;
                          return SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: saving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      isEditing
                                          ? Icons.save_outlined
                                          : Icons.send_rounded,
                                          color: Colors.white,
                                    ),
                              label: Text(
                                saving
                                    ? 'announcement_form_saving'.tr
                                    : isEditing
                                        ? 'announcement_form_submit_update'.tr
                                        : 'announcement_form_submit_publish'.tr,
                              ),
                              onPressed:
                                  saving ? null : controller.saveAnnouncement,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAudienceChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool selected,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    return FilterChip(
      avatar: Icon(
        icon,
        color: selected
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.primary,
      ),
      label: Text(label),
      selected: selected,
      onSelected: onChanged,
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      selectedColor: theme.colorScheme.primary,
      labelStyle: theme.textTheme.bodyMedium?.copyWith(
        color: selected
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(
        color: selected
            ? theme.colorScheme.primary
            : theme.colorScheme.primary.withOpacity(0.4),
      ),
      backgroundColor: theme.colorScheme.primary.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }
}
