import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/course_model.dart';
import '../controllers/teacher_courses_controller.dart';
import 'course_detail_view.dart';
import '../../common/widgets/swipe_action_background.dart';

class TeacherCoursesView extends StatelessWidget {
  final TeacherCoursesController controller =
      Get.put(TeacherCoursesController());

  TeacherCoursesView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Courses'),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withOpacity(0.05),
                theme.colorScheme.surface,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              _buildFilters(context),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: controller.refreshData,
                  child: controller.courses.isEmpty
                      ? _buildEmptyState(context)
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          itemCount: controller.courses.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final course = controller.courses[index];
                            return Dismissible(
                              key: ValueKey(course.id),
                              background: SwipeActionBackground(
                                alignment: Alignment.centerLeft,
                                color: theme.colorScheme.primary,
                                icon: Icons.edit_outlined,
                                label: 'Edit',
                              ),
                              secondaryBackground: SwipeActionBackground(
                                alignment: Alignment.centerRight,
                                color: theme.colorScheme.error,
                                icon: Icons.delete_outline,
                                label: 'Delete',
                              ),
                              confirmDismiss: (direction) async {
                                if (direction == DismissDirection.startToEnd) {
                                  controller.openForm(course: course);
                                  return false;
                                }
                                final confirmed = await _confirmDelete(context);
                                if (confirmed == true) {
                                  await controller.deleteCourse(course.id);
                                }
                                return confirmed ?? false;
                              },
                              child: _CourseListTile(
                                course: course,
                                onTap: () {
                                  Get.to(
                                    () => CourseDetailView(
                                      course: course,
                                      onEdit: () async {
                                        Get.back();
                                        await Future<void>.delayed(Duration.zero);
                                        controller.openForm(course: course);
                                      },
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        );
      }),
      floatingActionButton: Obx(() {
        final hasClasses = controller.availableClasses.isNotEmpty;
        return FloatingActionButton.extended(
          heroTag: 'teacherCoursesFab',
          onPressed: hasClasses ? () => controller.openForm() : null,
          icon: const Icon(Icons.add),
          label: Text(hasClasses ? 'New Course' : 'No classes available'),
        );
      }),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 120),
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
          'No courses yet',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap the button below to publish your first course.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 160),
      ],
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
                final hasFilter =
                    controller.selectedFilterClassId.value.isNotEmpty;
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
            final selectedId = controller.selectedFilterClassId.value;
            if (selectedId.isEmpty) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildActiveFilterChip(
                    context,
                    label: 'Class: ${controller.className(selectedId)}',
                    onRemoved: () => controller.updateClassFilter(''),
                  ),
                ],
              ),
            );
          }),
          Obx(() {
            final classes = controller.availableClasses;
            return DropdownButtonFormField<String>(
              value: controller.selectedFilterClassId.value.isEmpty
                  ? null
                  : controller.selectedFilterClassId.value,
              decoration: const InputDecoration(
                labelText: 'Class',
                border: OutlineInputBorder(),
              ),
              hint: Text(
                classes.isNotEmpty ? 'All classes' : 'No classes available',
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: '',
                  child: Text('All classes'),
                ),
                ...classes
                    .map(
                      (schoolClass) => DropdownMenuItem<String>(
                        value: schoolClass.id,
                        child: Text(schoolClass.name),
                      ),
                    )
                    .toList(),
              ],
              onChanged: (value) => controller.updateClassFilter(value ?? ''),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActiveFilterChip(
    BuildContext context, {
    required String label,
    required VoidCallback onRemoved,
  }) {
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

  Future<bool?> _confirmDelete(BuildContext context) {
    final theme = Theme.of(context);
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete course'),
        content: const Text('Are you sure you want to delete this course?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Delete',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseListTile extends StatelessWidget {
  final CourseModel course;
  final VoidCallback onTap;

  const _CourseListTile({required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final classes = course.classNames.isEmpty
        ? 'No class assigned'
        : course.classNames.join(', ');
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
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
