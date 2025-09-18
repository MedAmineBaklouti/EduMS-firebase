import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/modern_scaffold.dart';
import '../controllers/announcement_controller.dart';

class AnnouncementFormView extends StatelessWidget {
  AnnouncementFormView({super.key});

  final AnnouncementController controller = Get.find();

  @override
  Widget build(BuildContext context) {
    final isEditing = controller.editing != null;
    final theme = Theme.of(context);
    return ModernScaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Announcement' : 'Add Announcement'),
        centerTitle: true,
      ),
      alignment: Alignment.topCenter,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      body: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.08),
                    blurRadius: 36,
                    offset: const Offset(0, 24),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Announcement details',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: controller.titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'Short and descriptive headline',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller.descriptionController,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Include the key information to share',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Send to',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Obx(
                      () => Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _AudienceChip(
                            label: 'Teachers',
                            selected: controller.teachersSelected.value,
                            onSelected: (value) =>
                                controller.teachersSelected.value = value,
                          ),
                          _AudienceChip(
                            label: 'Parents',
                            selected: controller.parentsSelected.value,
                            onSelected: (value) =>
                                controller.parentsSelected.value = value,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: Icon(
                          isEditing
                              ? Icons.save_as_outlined
                              : Icons.send_outlined,
                        ),
                        label: Text(isEditing ? 'Save changes' : 'Publish'),
                        onPressed: controller.saveAnnouncement,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AudienceChip extends StatelessWidget {
  const _AudienceChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      labelStyle: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      showCheckmark: false,
      avatar: Icon(
        Icons.people_outline,
        size: 18,
        color: selected
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.primary,
      ),
      selectedColor: theme.colorScheme.primary,
      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.primary.withOpacity(0.25),
        ),
      ),
      labelPadding: const EdgeInsets.symmetric(horizontal: 6),
    );
  }
}
