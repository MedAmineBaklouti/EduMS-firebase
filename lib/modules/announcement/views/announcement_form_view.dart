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
        title: Text(isEditing ? 'Edit Announcement' : 'Add Announcement'),
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
                                            ? 'Update the announcement details'
                                            : 'Share a new announcement',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Announcements automatically expire after seven days. Make sure to provide a clear title and concise information.',
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
                          decoration: const InputDecoration(
                            labelText: 'Announcement title',
                            border: OutlineInputBorder(),
                            hintText: 'e.g. Midterm exams schedule',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a title.';
                            }
                            if (value.trim().length < 4) {
                              return 'The title should be at least 4 characters long.';
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
                          decoration: const InputDecoration(
                            labelText: 'Message',
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(),
                            hintText:
                                'Share the announcement details, dates and any important instructions.',
                            counterText: '',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please describe the announcement.';
                            }
                            if (value.trim().length < 10) {
                              return 'Add a bit more context so everyone understands.';
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
                                    ? '$remaining characters left'
                                    : 'Limit exceeded by ${remaining.abs()} characters',
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
                          'Audience',
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
                                label: 'Teachers',
                                icon: Icons.school_outlined,
                                selected: controller.teachersSelected.value,
                                onChanged: (value) =>
                                    controller.teachersSelected.value = value,
                              ),
                              _buildAudienceChip(
                                context,
                                label: 'Parents',
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
                            selectedGroups.add('Teachers');
                          }
                          if (controller.parentsSelected.value) {
                            selectedGroups.add('Parents');
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
                                        ? 'Will notify: ${selectedGroups.join(', ')}'
                                        : 'Select at least one audience to notify.',
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
                                    ),
                              label: Text(
                                saving
                                    ? 'Saving...'
                                    : isEditing
                                        ? 'Update announcement'
                                        : 'Publish announcement',
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
