import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/admin_control_controller.dart';
import '../../../common/models/child_model.dart';
import '../../../common/models/parent_model.dart';
import '../../../common/models/school_class_model.dart';
import '../../../common/models/subject_model.dart';
import '../../../common/models/teacher_model.dart';

class AdminControlView extends StatelessWidget {
  final AdminControlController c = Get.put(AdminControlController());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          title: const Text('Admin Control'),
          centerTitle: true,
          elevation: 0,
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: theme.colorScheme.onPrimary,
            indicatorWeight: 3,
            labelStyle: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            labelColor: theme.colorScheme.onPrimary,
            unselectedLabelColor:
                theme.colorScheme.onPrimary.withOpacity(0.7),
            tabs: const [
              Tab(text: 'Parents'),
              Tab(text: 'Teachers'),
              Tab(text: 'Classes'),
              Tab(text: 'Children'),
              Tab(text: 'Subjects'),
            ],
          ),
        ),
        body: Container(
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
          child: TabBarView(
            children: [
              _buildParents(),
              _buildTeachers(),
              _buildClasses(),
              _buildChildren(),
              _buildSubjects(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParents() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Builder(
        builder: (context) => Obx(() {
          if (c.parents.isEmpty) {
            return _buildEmptyState(
              context,
              icon: Icons.diversity_3_outlined,
              title: 'No parents yet',
              message: 'Tap the button below to add a parent profile.',
            );
          }
          final filteredParents = c.filteredParents;
          final hasFilters = c.selectedParentClassId.value.isNotEmpty;
          return Column(
            children: [
              _buildParentFilters(context),
              const SizedBox(height: 8),
              Expanded(
                child: filteredParents.isEmpty
                    ? _buildFilteredResultsState(
                        context,
                        icon: Icons.filter_list_off_outlined,
                        title: 'No parents match your filters',
                        message:
                            'No parents are linked to the selected class. Try a different class or clear the filter.',
                        onClear: hasFilters ? c.clearParentFilters : null,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                        physics: const BouncingScrollPhysics(),
                        itemCount: filteredParents.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final parent = filteredParents[index];
                          final theme = Theme.of(context);
                          return _buildManagementCard(
                            context: context,
                            icon: Icons.badge_outlined,
                            iconColor: theme.colorScheme.primary,
                            title: parent.name,
                            subtitle: 'Parent account',
                            onTap: () => _showParentDialog(parent: parent),
                            onDelete: () => c.deleteParent(parent.id),
                            footer: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildInfoChip(
                                    context,
                                    icon: Icons.mail_outline,
                                    label: parent.email,
                                  ),
                                  if (parent.phone.isNotEmpty)
                                    _buildInfoChip(
                                      context,
                                      icon: Icons.phone_outlined,
                                      label: parent.phone,
                                    ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          );
        }),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'parentsFab',
        onPressed: () => _showParentDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Parent'),
      ),
    );
  }

  Widget _buildTeachers() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Builder(
        builder: (context) => Obx(() {
          if (c.teachers.isEmpty) {
            return _buildEmptyState(
              context,
              icon: Icons.school_outlined,
              title: 'No teachers yet',
              message:
                  'Invite teachers to start assigning them to subjects and classes.',
            );
          }
          final filteredTeachers = c.filteredTeachers;
          final hasFilters = c.selectedTeacherClassId.value.isNotEmpty;
          return Column(
            children: [
              _buildTeacherFilters(context),
              const SizedBox(height: 8),
              Expanded(
                child: filteredTeachers.isEmpty
                    ? _buildFilteredResultsState(
                        context,
                        icon: Icons.filter_list_off_outlined,
                        title: 'No teachers found for this class',
                        message:
                            'No teachers are assigned to the selected class. Try another class or clear the filter.',
                        onClear: hasFilters ? c.clearTeacherFilters : null,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                        physics: const BouncingScrollPhysics(),
                        itemCount: filteredTeachers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final teacher = filteredTeachers[index];
                          final theme = Theme.of(context);
                          final subject = _findSubjectById(teacher.subjectId);
                          final hasSubject =
                              subject != null && subject.name.trim().isNotEmpty;
                          final subjectLabel = hasSubject
                              ? subject!.name
                              : 'Subject pending';

                          return _buildManagementCard(
                            context: context,
                            icon: Icons.person_outline,
                            iconColor: theme.colorScheme.secondary,
                            title: teacher.name,
                            subtitle: hasSubject
                                ? 'Teaches $subjectLabel'
                                : 'No subject assigned',
                            onTap: () => _showTeacherDialog(teacher: teacher),
                            onDelete: () => c.deleteTeacher(teacher.id),
                            footer: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildInfoChip(
                                    context,
                                    icon: Icons.mail_outline,
                                    label: teacher.email,
                                  ),
                                  _buildInfoChip(
                                    context,
                                    icon: Icons.menu_book_outlined,
                                    label: subjectLabel,
                                    color: hasSubject
                                        ? theme.colorScheme.secondary
                                        : theme.colorScheme.outline,
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          );
        }),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'teachersFab',
        onPressed: () => _showTeacherDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Teacher'),
      ),
    );
  }

  Widget _buildParentFilters(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter parents',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Obx(() {
                final hasFilters = c.selectedParentClassId.value.isNotEmpty;
                return TextButton.icon(
                  onPressed: hasFilters ? c.clearParentFilters : null,
                  icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                  label: const Text('Clear'),
                );
              }),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() {
            final classes = c.classes.toList()
              ..sort((a, b) => a.name.compareTo(b.name));
            final selected = c.selectedParentClassId.value;
            final dropdownValue = classes.any((cls) => cls.id == selected)
                ? selected
                : '';
            return DropdownButtonFormField<String>(
              value: dropdownValue,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Class',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: '',
                  child: Text('All classes'),
                ),
                ...classes.map(
                  (schoolClass) => DropdownMenuItem<String>(
                    value: schoolClass.id,
                    child: Text(schoolClass.name),
                  ),
                ),
              ],
              onChanged: (value) =>
                  c.updateParentClassFilter(value ?? ''),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTeacherFilters(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter teachers',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Obx(() {
                final hasFilters = c.selectedTeacherClassId.value.isNotEmpty;
                return TextButton.icon(
                  onPressed: hasFilters ? c.clearTeacherFilters : null,
                  icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                  label: const Text('Clear'),
                );
              }),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() {
            final classes = c.classes.toList()
              ..sort((a, b) => a.name.compareTo(b.name));
            final selected = c.selectedTeacherClassId.value;
            final dropdownValue = classes.any((cls) => cls.id == selected)
                ? selected
                : '';
            return DropdownButtonFormField<String>(
              value: dropdownValue,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Class',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: '',
                  child: Text('All classes'),
                ),
                ...classes.map(
                  (schoolClass) => DropdownMenuItem<String>(
                    value: schoolClass.id,
                    child: Text(schoolClass.name),
                  ),
                ),
              ],
              onChanged: (value) =>
                  c.updateTeacherClassFilter(value ?? ''),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFilteredResultsState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
    VoidCallback? onClear,
  }) {
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
                icon,
                color: theme.colorScheme.primary,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            if (onClear != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.filter_alt_off_outlined),
                label: const Text('Clear filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildClasses() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Builder(
        builder: (context) => Obx(() {
          final classes = c.classes;
          if (classes.isEmpty) {
            return _buildEmptyState(
              context,
              icon: Icons.meeting_room_outlined,
              title: 'No classes created',
              message: 'Add a class to start organising teachers and students.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
            physics: const BouncingScrollPhysics(),
            itemCount: classes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final schoolClass = classes[index];
              final theme = Theme.of(context);
              final studentCount = schoolClass.childIds.length;
              final subjectCount = schoolClass.teacherSubjects.length;
              final subtitle =
                  '${studentCount} ${studentCount == 1 ? 'student' : 'students'} • '
                  '${subjectCount} ${subjectCount == 1 ? 'subject' : 'subjects'}';

              return _buildManagementCard(
                context: context,
                icon: Icons.class_outlined,
                iconColor: theme.colorScheme.primary,
                title: schoolClass.name,
                subtitle: subtitle,
                onTap: () => _showClassDialog(schoolClass: schoolClass),
                onDelete: () => c.deleteClass(schoolClass.id),
                footer: [
                  if (schoolClass.teacherSubjects.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: schoolClass.teacherSubjects.entries
                          .map((entry) {
                        final subject = _findSubjectById(entry.key);
                        final subjectName =
                            subject != null && subject.name.trim().isNotEmpty
                                ? subject.name
                                : 'Subject';
                        final teacher = _findTeacherById(entry.value);
                        final teacherAssigned =
                            teacher != null && teacher.name.trim().isNotEmpty;
                        final teacherName =
                            teacherAssigned ? teacher!.name : 'Unassigned';
                        return _buildInfoChip(
                          context,
                          icon: Icons.menu_book_outlined,
                          label: '$subjectName: $teacherName',
                          color: teacherAssigned
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline,
                        );
                      }).toList(),
                    )
                  else
                    Text(
                      'No teacher assignments yet',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  const SizedBox(height: 8),
                  _buildInfoChip(
                    context,
                    icon: Icons.people_alt_outlined,
                    label:
                        '$studentCount ${studentCount == 1 ? 'student' : 'students'}',
                  ),
                ],
              );
            },
          );
        }),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'classesFab',
        onPressed: () => _showClassDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Class'),
      ),
    );
  }

  Widget _buildChildren() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Builder(
        builder: (context) => Obx(() {
          final children = c.children;
          if (children.isEmpty) {
            return _buildEmptyState(
              context,
              icon: Icons.family_restroom_outlined,
              title: 'No children registered',
              message: 'Add students to link them with parents and classes.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
            physics: const BouncingScrollPhysics(),
            itemCount: children.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final child = children[index];
              final theme = Theme.of(context);
              final parent = _findParentById(child.parentId);
              final parentAssigned =
                  parent != null && parent.name.trim().isNotEmpty;
              final parentLabel =
                  parentAssigned ? parent!.name : 'No parent linked';
              final schoolClass = _findClassById(child.classId);
              final classAssigned =
                  schoolClass != null && schoolClass.name.trim().isNotEmpty;
              final classLabel =
                  classAssigned ? schoolClass!.name : 'Class pending';

              return _buildManagementCard(
                context: context,
                icon: Icons.child_care_outlined,
                iconColor: theme.colorScheme.tertiary,
                title: child.name,
                subtitle: classAssigned
                    ? 'Class • $classLabel'
                    : 'Awaiting class placement',
                onTap: () => _showChildDialog(child: child),
                onDelete: () => c.deleteChild(child.id),
                footer: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildInfoChip(
                        context,
                        icon: Icons.diversity_3_outlined,
                        label: parentLabel,
                        color: parentAssigned
                            ? null
                            : theme.colorScheme.outline,
                      ),
                      _buildInfoChip(
                        context,
                        icon: Icons.meeting_room_outlined,
                        label: classLabel,
                        color: classAssigned
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        }),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'childrenFab',
        onPressed: () => _showChildDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Child'),
      ),
    );
  }

  Widget _buildSubjects() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Builder(
        builder: (context) => Obx(() {
          final subjects = c.subjects;
          if (subjects.isEmpty) {
            return _buildEmptyState(
              context,
              icon: Icons.menu_book_outlined,
              title: 'No subjects yet',
              message: 'Create subjects to assign them to teachers and classes.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
            physics: const BouncingScrollPhysics(),
            itemCount: subjects.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final subject = subjects[index];
              final theme = Theme.of(context);
              final assignedTeachers =
                  c.teachers.where((t) => t.subjectId == subject.id).toList();
              final teacherCount = assignedTeachers.length;
              final subtitle = teacherCount == 0
                  ? 'No teachers assigned yet'
                  : '$teacherCount ${teacherCount == 1 ? 'teacher' : 'teachers'} assigned';

              return _buildManagementCard(
                context: context,
                icon: Icons.menu_book_outlined,
                iconColor: theme.colorScheme.primary,
                title: subject.name,
                subtitle: subtitle,
                onTap: () => _showSubjectDialog(subject: subject),
                onDelete: () => c.deleteSubject(subject.id),
                footer: [
                  if (teacherCount > 0)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: assignedTeachers
                          .map((teacher) => _buildInfoChip(
                                context,
                                icon: Icons.person_outline,
                                label: teacher.name,
                                color: theme.colorScheme.secondary,
                              ))
                          .toList(),
                    )
                  else
                    Text(
                      'Tap to assign a teacher.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              );
            },
          );
        }),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'subjectsFab',
        onPressed: () => _showSubjectDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Subject'),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
  }) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 84,
              width: 84,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
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

  Widget _buildManagementCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    VoidCallback? onDelete,
    List<Widget> footer = const [],
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      shadowColor: theme.colorScheme.primary.withOpacity(0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: iconColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (onDelete != null)
                    IconButton(
                      onPressed: onDelete,
                      icon: Icon(
                        Icons.delete_outline,
                        color: theme.colorScheme.error,
                      ),
                      tooltip: 'Delete',
                    ),
                ],
              ),
              if (footer.isNotEmpty) ...[
                const SizedBox(height: 16),
                ...footer,
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final baseColor = color ?? theme.colorScheme.primary;
    return Chip(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      avatar: Icon(
        icon,
        size: 18,
        color: baseColor,
      ),
      label: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: baseColor.withOpacity(0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  ParentModel? _findParentById(String id) {
    if (id.isEmpty) return null;
    for (final parent in c.parents) {
      if (parent.id == id) {
        return parent;
      }
    }
    return null;
  }

  SchoolClassModel? _findClassById(String id) {
    if (id.isEmpty) return null;
    for (final schoolClass in c.classes) {
      if (schoolClass.id == id) {
        return schoolClass;
      }
    }
    return null;
  }

  TeacherModel? _findTeacherById(String id) {
    if (id.isEmpty) return null;
    for (final teacher in c.teachers) {
      if (teacher.id == id) {
        return teacher;
      }
    }
    return null;
  }

  SubjectModel? _findSubjectById(String id) {
    if (id.isEmpty) return null;
    for (final subject in c.subjects) {
      if (subject.id == id) {
        return subject;
      }
    }
    return null;
  }

  void _showParentDialog({ParentModel? parent}) {
    final nameCtrl = TextEditingController(text: parent?.name);
    final emailCtrl = TextEditingController(text: parent?.email);
    final phoneCtrl = TextEditingController(text: parent?.phone);
    final passwordCtrl = TextEditingController();
    Get.dialog(AlertDialog(
      title: Text(parent == null ? 'Add Parent' : 'Edit Parent'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 12),
              TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 12),
              TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Phone')),
              if (parent == null) ...[
                const SizedBox(height: 12),
                TextField(
                    controller: passwordCtrl,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Cancel')),
        TextButton(
            onPressed: () {
              final model = ParentModel(
                id: parent?.id ?? '',
                name: nameCtrl.text,
                email: emailCtrl.text,
                phone: phoneCtrl.text,
              );
              if (parent == null) {
                c.addParent(model, passwordCtrl.text);
              } else {
                c.updateParent(model);
              }
              Get.back();
            },
            child: const Text('Save')),
      ],
    ));
  }

  void _showTeacherDialog({TeacherModel? teacher}) {
    final nameCtrl = TextEditingController(text: teacher?.name);
    final emailCtrl = TextEditingController(text: teacher?.email);
    final passwordCtrl = TextEditingController();
    String? selectedSubject = teacher?.subjectId;
    Get.dialog(StatefulBuilder(builder: (context, setState) {
      return AlertDialog(
        title: Text(teacher == null ? 'Add Teacher' : 'Edit Teacher'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Name')),
                const SizedBox(height: 12),
                TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email')),
                if (teacher == null) ...[
                  const SizedBox(height: 12),
                  TextField(
                      controller: passwordCtrl,
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true),
                ],
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: selectedSubject,
                  items: c.subjects
                      .map((s) =>
                          DropdownMenuItem(value: s.id, child: Text(s.name)))
                      .toList(),
                  onChanged: (val) => setState(() => selectedSubject = val),
                  decoration: const InputDecoration(labelText: 'Subject'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          TextButton(
              onPressed: () {
                final model = TeacherModel(
                  id: teacher?.id ?? '',
                  name: nameCtrl.text,
                  email: emailCtrl.text,
                  subjectId: selectedSubject ?? '',
                );
                if (teacher == null) {
                  c.addTeacher(model, passwordCtrl.text);
                } else {
                  c.updateTeacher(model);
                }
                Get.back();
              },
              child: const Text('Save')),
        ],
      );
    }));
  }

  void _showClassDialog({SchoolClassModel? schoolClass}) {
    final nameCtrl = TextEditingController(text: schoolClass?.name);
    final selectedChildren = <String>[...?schoolClass?.childIds];
    final assignments = <Map<String, String>>[
      for (final e
          in schoolClass?.teacherSubjects.entries ?? <MapEntry<String, String>>[])
        {'subjectId': e.key, 'teacherId': e.value}
    ];

    Get.dialog(StatefulBuilder(builder: (context, setState) {
      final theme = Theme.of(context);

      void addAssignment() {
        final availableSubjects = c.subjects
            .where(
                (s) => !assignments.any((a) => a['subjectId'] == s.id))
            .toList();
        if (availableSubjects.isEmpty) return;
        final subjectId = availableSubjects.first.id;
        final teachersForSubject = c.teachers
            .where((t) => t.subjectId == subjectId)
            .toList();
        final teacherId =
            teachersForSubject.isNotEmpty ? teachersForSubject.first.id : '';
        setState(() {
          assignments.add({'subjectId': subjectId, 'teacherId': teacherId});
        });
      }

      return AlertDialog(
        title: Text(schoolClass == null ? 'Add Class' : 'Edit Class'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Name')),
                const SizedBox(height: 16),
                if (assignments.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      'No teacher assignments yet. Tap "Add Teacher" to create one.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ...assignments.asMap().entries.map((entry) {
                  final i = entry.key;
                  final assignment = entry.value;
                  final subjectItems = c.subjects
                      .where((s) =>
                          s.id == assignment['subjectId'] ||
                          !assignments.any((a) => a['subjectId'] == s.id))
                      .map((s) =>
                          DropdownMenuItem(value: s.id, child: Text(s.name)))
                      .toList();
                  final teacherItems = c.teachers
                      .where((t) => t.subjectId == assignment['subjectId'])
                      .map((t) =>
                          DropdownMenuItem(value: t.id, child: Text(t.name)))
                      .toList();
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: assignment['subjectId']!.isEmpty
                                ? null
                                : assignment['subjectId'],
                            items: subjectItems,
                            onChanged: (val) {
                              setState(() {
                                assignment['subjectId'] = val ?? '';
                                final teachers = c.teachers
                                    .where((t) =>
                                        t.subjectId == assignment['subjectId'])
                                    .toList();
                                assignment['teacherId'] = teachers.isNotEmpty
                                    ? teachers.first.id
                                    : '';
                              });
                            },
                            decoration:
                                const InputDecoration(labelText: 'Subject'),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: assignment['teacherId']!.isEmpty
                                ? null
                                : assignment['teacherId'],
                            items: teacherItems,
                            onChanged: (val) => setState(
                                () => assignment['teacherId'] = val ?? ''),
                            decoration:
                                const InputDecoration(labelText: 'Teacher'),
                          ),
                          if (teacherItems.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'No teachers available for the selected subject yet.',
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () => setState(() {
                                assignments.removeAt(i);
                              }),
                              icon: const Icon(Icons.remove_circle_outline),
                              label: const Text('Remove'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: addAssignment,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Teacher'),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Add a child',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                if (c.children.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      'No children available to add right now.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ...c.children.map((ch) => CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(ch.name),
                      value: selectedChildren.contains(ch.id),
                      onChanged: (val) => setState(() {
                        if (val == true) {
                          if (!selectedChildren.contains(ch.id)) {
                            selectedChildren.add(ch.id);
                          }
                        } else {
                          selectedChildren.remove(ch.id);
                        }
                      }),
                    )),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          TextButton(
              onPressed: () {
                final teacherSubjects = <String, String>{
                  for (final a in assignments)
                    if ((a['subjectId'] ?? '').isNotEmpty &&
                        (a['teacherId'] ?? '').isNotEmpty)
                      a['subjectId']!: a['teacherId']!,
                };
                final model = SchoolClassModel(
                  id: schoolClass?.id ?? '',
                  name: nameCtrl.text,
                  teacherSubjects: teacherSubjects,
                  childIds: selectedChildren,
                );
                if (schoolClass == null) {
                  c.addClass(model);
                } else {
                  c.updateClass(model,
                      previousChildIds: schoolClass.childIds);
                }
                Get.back();
              },
              child: const Text('Save')),
        ],
      );
    }));
  }

  void _showChildDialog({ChildModel? child}) {
    final nameCtrl = TextEditingController(text: child?.name);
    String? selectedParent = child?.parentId;
    String? selectedClass = child?.classId;
    Get.dialog(StatefulBuilder(builder: (context, setState) {
      return AlertDialog(
        title: Text(child == null ? 'Add Child' : 'Edit Child'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Name')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: selectedParent,
                  items: c.parents
                      .map((p) =>
                          DropdownMenuItem(value: p.id, child: Text(p.name)))
                      .toList(),
                  onChanged: (val) => setState(() => selectedParent = val),
                  decoration: const InputDecoration(labelText: 'Parent'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: selectedClass,
                  items: c.classes
                      .map((cl) =>
                          DropdownMenuItem(value: cl.id, child: Text(cl.name)))
                      .toList(),
                  onChanged: (val) => setState(() => selectedClass = val),
                  decoration: const InputDecoration(labelText: 'Class'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          TextButton(
              onPressed: () {
                final model = ChildModel(
                  id: child?.id ?? '',
                  name: nameCtrl.text,
                  parentId: selectedParent ?? '',
                  classId: selectedClass ?? '',
                );
                if (child == null) {
                  c.addChild(model);
                } else {
                  c.updateChild(model);
                }
                Get.back();
              },
              child: const Text('Save')),
        ],
      );
    }));
  }

  void _showSubjectDialog({SubjectModel? subject}) {
    final nameCtrl = TextEditingController(text: subject?.name);
    Get.dialog(AlertDialog(
      title: Text(subject == null ? 'Add Subject' : 'Edit Subject'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 360,
          child: TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Cancel')),
        TextButton(
            onPressed: () {
              final model = SubjectModel(
                id: subject?.id ?? '',
                name: nameCtrl.text,
              );
              if (subject == null) {
                c.addSubject(model);
              } else {
                c.updateSubject(model);
              }
              Get.back();
            },
            child: const Text('Save')),
      ],
    ));
  }
}
