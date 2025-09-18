import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/modern_scaffold.dart';
import '../../../data/models/course_model.dart';
import '../controllers/parent_courses_controller.dart';
import 'course_detail_view.dart';

class ParentCoursesView extends StatelessWidget {
  final ParentCoursesController controller =
      Get.put(ParentCoursesController());

  ParentCoursesView({super.key});

  @override
  Widget build(BuildContext context) {
    return ModernScaffold(
      appBar: AppBar(
        title: const Text('Courses'),
        centerTitle: true,
      ),
      padding: EdgeInsets.zero,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.children.isEmpty) {
          return _buildNoChildrenState(context);
        }
        return Column(
          children: [
            _buildFilters(context),
            Expanded(
              child: Obx(() {
                if (controller.courses.isEmpty) {
                  return _buildEmptyState(context);
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  itemCount: controller.courses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final course = controller.courses[index];
                    return _ParentCourseTile(course: course);
                  },
                );
              }),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildFilters(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter courses',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Obx(() {
                final hasFilters =
                    controller.selectedChildId.value.isNotEmpty ||
                        controller.selectedSubjectId.value.isNotEmpty;
                return TextButton.icon(
                  onPressed: hasFilters ? controller.clearFilters : null,
                  icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                  label: const Text('Clear'),
                );
              }),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Obx(() {
                  return DropdownButtonFormField<String>(
                    value: controller.selectedChildId.value.isEmpty
                        ? null
                        : controller.selectedChildId.value,
                    decoration: const InputDecoration(
                      labelText: 'Child',
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('All children'),
                    items: [
                      const DropdownMenuItem<String>(
                        value: '',
                        child: Text('All children'),
                      ),
                      ...controller.children
                          .map(
                            (child) => DropdownMenuItem<String>(
                              value: child.id,
                              child: Text(child.name),
                            ),
                          )
                          .toList(),
                    ],
                    onChanged: (value) =>
                        controller.updateChildFilter(value ?? ''),
                  );
                }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(() {
                  final options = controller.subjectOptions;
                  return DropdownButtonFormField<String>(
                    value: controller.selectedSubjectId.value.isEmpty
                        ? null
                        : controller.selectedSubjectId.value,
                    decoration: const InputDecoration(
                      labelText: 'Subject',
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('All subjects'),
                    items: [
                      const DropdownMenuItem<String>(
                        value: '',
                        child: Text('All subjects'),
                      ),
                      ...options
                          .map(
                            (subject) => DropdownMenuItem<String>(
                              value: subject.id,
                              child: Text(subject.name),
                            ),
                          )
                          .toList(),
                    ],
                    onChanged: (value) =>
                        controller.updateSubjectFilter(value ?? ''),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.menu_book_outlined,
                color: theme.colorScheme.primary,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No courses found',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'There are no courses for the selected filters yet.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoChildrenState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.diversity_3_outlined,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'No children linked',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please contact the school administration to link your children.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParentCourseTile extends StatelessWidget {
  final CourseModel course;

  const _ParentCourseTile({required this.course});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subject = course.subjectName.isNotEmpty
        ? course.subjectName
        : 'Subject not specified';
    final classes = course.classNames.isEmpty
        ? 'No class linked'
        : course.classNames.join(', ');
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Get.to(() => CourseDetailView(course: course)),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.08),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.menu_book_outlined,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        subject,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.group_outlined,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        classes,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
