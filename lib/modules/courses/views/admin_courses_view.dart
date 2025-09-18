import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../data/models/course_model.dart';
import '../controllers/admin_courses_controller.dart';
import 'course_detail_view.dart';

class AdminCoursesView extends StatelessWidget {
  final AdminCoursesController controller = Get.put(AdminCoursesController());

  AdminCoursesView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Courses'),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: [
            _buildSearchAndStats(context),
            _buildFilters(context),
            Expanded(
              child: controller.courses.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      itemCount: controller.courses.length,
                      physics: const BouncingScrollPhysics(),
                      separatorBuilder: (_, __) => const SizedBox(height: 18),
                      itemBuilder: (context, index) {
                        final course = controller.courses[index];
                        return _AdminCourseTile(course: course);
                      },
                    ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildSearchAndStats(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller.searchController,
            decoration: InputDecoration(
              hintText: 'Search by course, subject, teacher or class',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: Obx(
                () => controller.searchQuery.value.isEmpty
                    ? const SizedBox.shrink()
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close),
                        onPressed: controller.searchController.clear,
                      ),
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            textInputAction: TextInputAction.search,
          ),
          const SizedBox(height: 16),
          Obx(() {
            final filteredCount = controller.courses.length;
            final totalCount = controller.totalCourseCount;
            final filteredTeachers = controller.filteredTeacherCount;
            final filteredSubjects = controller.filteredSubjectCount;
            final filteredClasses = controller.filteredClassCount;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildSummaryCard(
                  context,
                  icon: Icons.menu_book_outlined,
                  label: 'Visible courses',
                  value: totalCount > 0
                      ? '$filteredCount of $totalCount'
                      : '$filteredCount',
                ),
                _buildSummaryCard(
                  context,
                  icon: Icons.groups_outlined,
                  label: 'Teachers represented',
                  value: filteredTeachers.toString(),
                ),
                _buildSummaryCard(
                  context,
                  icon: Icons.category_outlined,
                  label: 'Subjects',
                  value: filteredSubjects.toString(),
                ),
                _buildSummaryCard(
                  context,
                  icon: Icons.class_outlined,
                  label: 'Classes covered',
                  value: filteredClasses.toString(),
                ),
              ],
            );
          }),
        ],
      ),
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
                final hasFilters = controller.selectedSubjectId.value.isNotEmpty ||
                    controller.selectedTeacherId.value.isNotEmpty ||
                    controller.selectedClassId.value.isNotEmpty ||
                    controller.searchQuery.value.isNotEmpty;
                return TextButton.icon(
                  onPressed: hasFilters ? controller.clearFilters : null,
                  icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                  label: const Text('Clear'),
                );
              }),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() {
            final chips = <Widget>[];
            if (controller.searchQuery.value.isNotEmpty) {
              chips.add(_buildActiveFilterChip(
                context,
                label: 'Search: ${controller.searchQuery.value}',
                onRemoved: controller.searchController.clear,
              ));
            }
            if (controller.selectedSubjectId.value.isNotEmpty) {
              chips.add(_buildActiveFilterChip(
                context,
                label:
                    'Subject: ${controller.subjectName(controller.selectedSubjectId.value)}',
                onRemoved: () => controller.updateSubjectFilter(''),
              ));
            }
            if (controller.selectedTeacherId.value.isNotEmpty) {
              final teacher = controller.teacherName(
                  controller.selectedTeacherId.value);
              chips.add(_buildActiveFilterChip(
                context,
                label: 'Teacher: $teacher',
                onRemoved: () => controller.updateTeacherFilter(''),
              ));
            }
            if (controller.selectedClassId.value.isNotEmpty) {
              chips.add(_buildActiveFilterChip(
                context,
                label:
                    'Class: ${controller.className(controller.selectedClassId.value)}',
                onRemoved: () => controller.updateClassFilter(''),
              ));
            }
            if (chips.isEmpty) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: chips,
              ),
            );
          }),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Obx(() {
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
                      ...controller.subjects
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
              const SizedBox(width: 12),
              Expanded(
                child: Obx(() {
                  return DropdownButtonFormField<String>(
                    value: controller.selectedTeacherId.value.isEmpty
                        ? null
                        : controller.selectedTeacherId.value,
                    decoration: const InputDecoration(
                      labelText: 'Teacher',
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('All teachers'),
                    items: [
                      const DropdownMenuItem<String>(
                        value: '',
                        child: Text('All teachers'),
                      ),
                      ...controller.teachers
                          .map(
                            (teacher) => DropdownMenuItem<String>(
                              value: teacher.id,
                              child: Text(teacher.name),
                            ),
                          )
                          .toList(),
                    ],
                    onChanged: (value) =>
                        controller.updateTeacherFilter(value ?? ''),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Obx(() {
                  return DropdownButtonFormField<String>(
                    value: controller.selectedClassId.value.isEmpty
                        ? null
                        : controller.selectedClassId.value,
                    decoration: const InputDecoration(
                      labelText: 'Class',
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('All classes'),
                    items: [
                      const DropdownMenuItem<String>(
                        value: '',
                        child: Text('All classes'),
                      ),
                      ...controller.classes
                          .map(
                            (schoolClass) => DropdownMenuItem<String>(
                              value: schoolClass.id,
                              child: Text(schoolClass.name),
                            ),
                          )
                          .toList(),
                    ],
                    onChanged: (value) =>
                        controller.updateClassFilter(value ?? ''),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 150),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 12),
            ),
          ],
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: theme.colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
              'Adjust the filters or check back later for new courses.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tip: use the search box above to find a specific class or teacher.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminCourseTile extends StatelessWidget {
  final CourseModel course;
  static final DateFormat _dateFormat = DateFormat('MMM d, yyyy');

  const _AdminCourseTile({required this.course});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subject = course.subjectName.isNotEmpty
        ? course.subjectName
        : 'Subject not specified';
    final teacher = course.teacherName.isNotEmpty
        ? course.teacherName
        : 'Teacher unknown';
    final createdLabel = _dateFormat.format(course.createdAt);
    final uniqueClasses = course.classNames.toSet().toList();
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            subject,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  course.description.isNotEmpty
                      ? course.description
                      : 'No description provided for this course.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                _buildMetaRow(
                  context,
                  icon: Icons.person_outline,
                  value: teacher,
                ),
                const SizedBox(height: 8),
                _buildMetaRow(
                  context,
                  icon: Icons.class_outlined,
                  value: uniqueClasses.isEmpty
                      ? 'No classes linked yet'
                      : '${uniqueClasses.length} class${uniqueClasses.length == 1 ? '' : 'es'} linked',
                ),
                if (uniqueClasses.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: uniqueClasses
                        .map((name) => _buildClassChip(context, name))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildMetaBadge(
                      context,
                      icon: Icons.calendar_today_outlined,
                      label: 'Created $createdLabel',
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: theme.colorScheme.primary,
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

  Widget _buildMetaRow(BuildContext context,
      {required IconData icon, required String value}) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClassChip(BuildContext context, String name) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.secondary.withOpacity(0.12),
      ),
      child: Text(
        name,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.secondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMetaBadge(BuildContext context,
      {required IconData icon, required String label}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: theme.colorScheme.primary.withOpacity(0.08),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
