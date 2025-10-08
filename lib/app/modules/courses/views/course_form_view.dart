import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/teacher_courses_controller.dart';

class CourseFormView extends StatelessWidget {
  final TeacherCoursesController controller;

  const CourseFormView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subjectName = controller.subject.value?.name ?? 'Subject not set';
    return Scaffold(
      appBar: AppBar(
        title: Text(controller.editing == null ? 'Add Course' : 'Edit Course'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 0,
                color: theme.colorScheme.primary.withOpacity(0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.menu_book_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Subject',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subjectName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: controller.titleController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Course title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: controller.descriptionController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a brief description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: controller.contentController,
                minLines: 5,
                maxLines: 10,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                  hintText: 'Add the detailed course content here...'
                      ' This will be available in the PDF download.',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Course content is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Assign to classes',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Obx(() {
                if (controller.availableClasses.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: theme.colorScheme.error.withOpacity(0.08),
                    ),
                    child: Text(
                      'No classes are linked to your subject yet. Contact the administrator.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  );
                }
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: controller.availableClasses
                      .map(
                        (schoolClass) => FilterChip(
                          label: Text(schoolClass.name),
                          selected: controller.selectedClassIds
                              .contains(schoolClass.id),
                          onSelected: (_) =>
                              controller.toggleClassSelection(schoolClass.id),
                        ),
                      )
                      .toList(),
                );
              }),
              const SizedBox(height: 32),
              Obx(() {
                final saving = controller.isSaving.value;
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                        Icons.save_outlined,
                        color: Colors.white,
                    ),
                    label: Text(saving ? 'Saving...' : 'Save Course'),
                    onPressed: saving ? null : controller.saveCourse,
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
