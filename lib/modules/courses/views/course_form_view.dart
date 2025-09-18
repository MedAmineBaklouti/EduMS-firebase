import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/modern_scaffold.dart';
import '../controllers/teacher_courses_controller.dart';

class CourseFormView extends StatelessWidget {
  final TeacherCoursesController controller;

  const CourseFormView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subjectName = controller.subject.value?.name ?? 'Subject not set';
    final isEditing = controller.editing != null;

    return ModernScaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Course' : 'Add Course'),
        centerTitle: true,
      ),
      alignment: Alignment.topCenter,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Form(
          key: controller.formKey,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.menu_book_outlined,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
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
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: controller.titleController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Course title',
                          hintText: 'E.g. Algebra Basics',
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
                          hintText: 'Summarise what learners will gain',
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
                          hintText:
                              'Add detailed lesson content. This appears in the PDF download.',
                          alignLabelWithHint: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Course content is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),
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
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
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
                          spacing: 12,
                          runSpacing: 12,
                          children: controller.availableClasses
                              .map(
                                (schoolClass) => FilterChip(
                                  label: Text(schoolClass.name),
                                  selected: controller.selectedClassIds
                                      .contains(schoolClass.id),
                                  onSelected: (_) => controller
                                      .toggleClassSelection(schoolClass.id),
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
                          child: FilledButton.icon(
                            icon: saving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: Text(saving
                                ? 'Saving...'
                                : isEditing
                                    ? 'Update Course'
                                    : 'Save Course'),
                            onPressed: saving ? null : controller.saveCourse,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
