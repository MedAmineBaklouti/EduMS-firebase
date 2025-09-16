import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/admin_control_controller.dart';
import '../../../data/models/child_model.dart';
import '../../../data/models/parent_model.dart';
import '../../../data/models/school_class_model.dart';
import '../../../data/models/subject_model.dart';
import '../../../data/models/teacher_model.dart';

class AdminControlView extends StatelessWidget {
  final AdminControlController c = Get.put(AdminControlController());

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Control'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Parents'),
              Tab(text: 'Teachers'),
              Tab(text: 'Classes'),
              Tab(text: 'Children'),
              Tab(text: 'Subjects'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildParents(),
            _buildTeachers(),
            _buildClasses(),
            _buildChildren(),
            _buildSubjects(),
          ],
        ),
      ),
    );
  }

  Widget _buildParents() {
    return Scaffold(
      body: Obx(() => ListView(
            children: c.parents
                .map((p) => ListTile(
                      title: Text(p.name),
                      subtitle: Text(p.email),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => c.deleteParent(p.id),
                      ),
                      onTap: () => _showParentDialog(parent: p),
                    ))
                .toList(),
          )),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showParentDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTeachers() {
    return Scaffold(
      body: Obx(() => ListView(
            children: c.teachers
                .map((t) => ListTile(
                      title: Text(t.name),
                      subtitle: Text(t.email),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => c.deleteTeacher(t.id),
                      ),
                      onTap: () => _showTeacherDialog(teacher: t),
                    ))
                .toList(),
          )),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTeacherDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildClasses() {
    return Scaffold(
      body: Obx(() => ListView(
            children: c.classes
                .map((cl) => ListTile(
                      title: Text(cl.name),
                      subtitle: Text(cl.teacherSubjects.entries
                          .map((e) {
                            final subjectName = c.subjects
                                .firstWhere(
                                    (s) => s.id == e.key,
                                    orElse: () =>
                                        SubjectModel(id: '', name: ''))
                                .name;
                            final teacherName = c.teachers
                                .firstWhere(
                                    (t) => t.id == e.value,
                                    orElse: () => TeacherModel(
                                        id: '', name: '', email: '', subjectId: ''))
                                .name;
                            return '$subjectName: $teacherName';
                          })
                          .join(', ')),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => c.deleteClass(cl.id),
                      ),
                      onTap: () => _showClassDialog(schoolClass: cl),
                    ))
                .toList(),
          )),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showClassDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildChildren() {
    return Scaffold(
      body: Obx(() => ListView(
            children: c.childItems
                .map((childItem) => ListTile(
                      title: Text(childItem.child.name),
                      subtitle: Text(
                          'Parent: ${childItem.parentName} | Class: ${childItem.className}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => c.deleteChild(childItem.child.id),
                      ),
                      onTap: () =>
                          _showChildDialog(child: childItem.child),
                    ))
                .toList(),
          )),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showChildDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSubjects() {
    return Scaffold(
      body: Obx(() => ListView(
            children: c.subjects
                .map((s) => ListTile(
                      title: Text(s.name),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => c.deleteSubject(s.id),
                      ),
                      onTap: () => _showSubjectDialog(subject: s),
                    ))
                .toList(),
          )),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSubjectDialog(),
        child: const Icon(Icons.add),
      ),
    );
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
