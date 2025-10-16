import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../models/course_model.dart';
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
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        title: Text('courses_title'.tr),
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
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          itemCount: controller.courses.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final course = controller.courses[index];
                            return _AdminCourseTile(course: course);
                          },
                        ),
                ),
              ),
            ],
          ),
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
                'courses_filter_title'.tr,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Obx(() {
                final hasFilters = controller.selectedSubjectId.value.isNotEmpty ||
                    controller.selectedTeacherId.value.isNotEmpty ||
                    controller.selectedClassId.value.isNotEmpty;
                return TextButton.icon(
                  onPressed: hasFilters ? controller.clearFilters : null,
                  icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                  label: Text('common_clear'.tr),
                );
              }),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() {
            final chips = <Widget>[];
            if (controller.selectedSubjectId.value.isNotEmpty) {
              chips.add(_buildActiveFilterChip(
                context,
                label: 'courses_filter_chip_subject'.trParams({
                  'subject': controller
                      .subjectName(controller.selectedSubjectId.value),
                }),
                onRemoved: () => controller.updateSubjectFilter(''),
              ));
            }
            if (controller.selectedTeacherId.value.isNotEmpty) {
              final teacher = controller.teacherName(
                  controller.selectedTeacherId.value);
              chips.add(_buildActiveFilterChip(
                context,
                label: 'courses_filter_chip_teacher'
                    .trParams({'teacher': teacher}),
                onRemoved: () => controller.updateTeacherFilter(''),
              ));
            }
            if (controller.selectedClassId.value.isNotEmpty) {
              chips.add(_buildActiveFilterChip(
                context,
                label: 'courses_filter_chip_class'.trParams({
                  'class': controller.className(
                    controller.selectedClassId.value,
                  ),
                }),
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
                    decoration: InputDecoration(
                      labelText: 'courses_filter_label_subject'.tr,
                      border: const OutlineInputBorder(),
                    ),
                    hint: Text('courses_filter_option_all_subjects'.tr),
                    items: [
                      DropdownMenuItem<String>(
                        value: '',
                        child: Text(
                            'courses_filter_option_all_subjects'.tr),
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
                    decoration: InputDecoration(
                      labelText: 'courses_filter_label_teacher'.tr,
                      border: const OutlineInputBorder(),
                    ),
                    hint: Text('courses_filter_option_all_teachers'.tr),
                    items: [
                      DropdownMenuItem<String>(
                        value: '',
                        child: Text(
                            'courses_filter_option_all_teachers'.tr),
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
                    decoration: InputDecoration(
                      labelText: 'courses_filter_label_class'.tr,
                      border: const OutlineInputBorder(),
                    ),
                    hint: Text('courses_filter_option_all_classes'.tr),
                    items: [
                      DropdownMenuItem<String>(
                        value: '',
                        child: Text(
                            'courses_filter_option_all_classes'.tr),
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
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 120, 16, 160),
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
          'courses_empty_title'.tr,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'courses_empty_message_admin'.tr,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
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
        : 'courses_subject_not_specified'.tr;
    final teacher = course.teacherName.isNotEmpty
        ? course.teacherName
        : 'courses_teacher_unknown'.tr;
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
                      : 'courses_description_missing'.tr,
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
                      ? 'courses_classes_none'.tr
                      : uniqueClasses.length == 1
                          ? 'courses_classes_single'.tr
                          : 'courses_classes_plural'.trParams({
                              'count': uniqueClasses.length.toString(),
                            }),
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
                      label: 'courses_created_on'
                          .trParams({'date': createdLabel}),
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
