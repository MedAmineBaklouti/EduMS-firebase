import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/course_model.dart';
import '../controllers/teacher_courses_controller.dart';
import 'course_detail_view.dart';

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
        if (controller.courses.isEmpty) {
          return _buildEmptyState(context);
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
          physics: const BouncingScrollPhysics(),
          itemCount: controller.courses.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final course = controller.courses[index];
            return Dismissible(
              key: ValueKey(course.id),
              background: _buildEditBackground(context),
              secondaryBackground: _buildDeleteBackground(context),
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
              child: _CourseListTile(course: course),
            );
          },
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
              'No courses yet',
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
          ],
        ),
      ),
    );
  }

  Widget _buildEditBackground(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(
        Icons.edit_outlined,
        color: theme.colorScheme.primary,
        size: 28,
      ),
    );
  }

  Widget _buildDeleteBackground(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(
        Icons.delete_outline,
        color: theme.colorScheme.error,
        size: 28,
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

  const _CourseListTile({required this.course});

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
