import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/admin_control_controller.dart';
import '../../../data/models/child_model.dart';
import '../../../data/models/parent_model.dart';
import '../../../data/models/school_class_model.dart';
import '../../../data/models/subject_model.dart';
import '../../../data/models/teacher_model.dart';

class AdminControlView extends StatelessWidget {
  final AdminControlController c = Get.find();

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
                      subtitle: Text('Teacher: ${cl.teacherId}'),
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
            children: c.children
                .map((ch) => ListTile(
                      title: Text(ch.name),
                      subtitle: Text('Parent: ${ch.parentId} | Class: ${ch.classId}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => c.deleteChild(ch.id),
                      ),
                      onTap: () => _showChildDialog(child: ch),
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
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
          TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
          TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone')),
          if (parent == null)
            TextField(
              controller: passwordCtrl,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
        ],
      ),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Cancel')),
        TextButton(
            onPressed: () {
              if (parent == null) {
                c.addParent(
                    name: nameCtrl.text,
                    email: emailCtrl.text,
                    phone: phoneCtrl.text,
                    password: passwordCtrl.text);
              } else {
                final model = ParentModel(
                  id: parent.id,
                  name: nameCtrl.text,
                  email: emailCtrl.text,
                  phone: phoneCtrl.text,
                );
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
    String? selectedSubject = teacher?.subjectId;
    final passwordCtrl = TextEditingController();
    Get.dialog(StatefulBuilder(builder: (context, setState) {
      return AlertDialog(
        title: Text(teacher == null ? 'Add Teacher' : 'Edit Teacher'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
            DropdownButton<String>(
              value: selectedSubject,
              hint: const Text('Select Subject'),
              items: c.subjects
                  .map((s) => DropdownMenuItem(
                      value: s.id, child: Text(s.name)))
                  .toList(),
              onChanged: (v) => setState(() => selectedSubject = v),
            ),
            if (teacher == null)
              TextField(
                controller: passwordCtrl,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          TextButton(
              onPressed: () {
                if (teacher == null) {
                  c.addTeacher(
                      name: nameCtrl.text,
                      email: emailCtrl.text,
                      subjectId: selectedSubject ?? '',
                      password: passwordCtrl.text);
                } else {
                  final model = TeacherModel(
                    id: teacher.id,
                    name: nameCtrl.text,
                    email: emailCtrl.text,
                    subjectId: selectedSubject ?? '',
                  );
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
    String? selectedTeacher = schoolClass?.teacherId;
    final Set<String> selectedChildren =
        {...(schoolClass?.childIds ?? [])};
    Get.dialog(StatefulBuilder(builder: (context, setState) {
      return AlertDialog(
        title: Text(schoolClass == null ? 'Add Class' : 'Edit Class'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
              DropdownButton<String>(
                value: selectedTeacher,
                hint: const Text('Select Teacher'),
                items: c.teachers
                    .map((t) => DropdownMenuItem(
                        value: t.id, child: Text(t.name)))
                    .toList(),
                onChanged: (v) => setState(() => selectedTeacher = v),
              ),
              const SizedBox(height: 10),
              const Text('Children'),
              SizedBox(
                height: 200,
                width: 300,
                child: Obx(() => ListView(
                      children: c.children
                          .map((ch) => CheckboxListTile(
                                value: selectedChildren.contains(ch.id),
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      selectedChildren.add(ch.id);
                                    } else {
                                      selectedChildren.remove(ch.id);
                                    }
                                  });
                                },
                                title: Text(ch.name),
                              ))
                          .toList(),
                    )),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          TextButton(
              onPressed: () {
                final model = SchoolClassModel(
                  id: schoolClass?.id ?? '',
                  name: nameCtrl.text,
                  teacherId: selectedTeacher ?? '',
                  childIds: selectedChildren.toList(),
                );
                if (schoolClass == null) {
                  c.addClass(model);
                } else {
                  c.updateClass(model);
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            DropdownButton<String>(
              value: selectedParent,
              hint: const Text('Select Parent'),
              items: c.parents
                  .map((p) => DropdownMenuItem(
                      value: p.id, child: Text(p.name)))
                  .toList(),
              onChanged: (v) => setState(() => selectedParent = v),
            ),
            DropdownButton<String>(
              value: selectedClass,
              hint: const Text('Select Class'),
              items: c.classes
                  .map((cl) => DropdownMenuItem(
                      value: cl.id, child: Text(cl.name)))
                  .toList(),
              onChanged: (v) => setState(() => selectedClass = v),
            ),
          ],
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
      content: TextField(
        controller: nameCtrl,
        decoration: const InputDecoration(labelText: 'Name'),
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
