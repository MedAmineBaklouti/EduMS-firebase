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
    Get.dialog(AlertDialog(
      title: Text(parent == null ? 'Add Parent' : 'Edit Parent'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
          TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
          TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone')),
        ],
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
                c.addParent(model);
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
    final subjectCtrl = TextEditingController(text: teacher?.subjectId);
    Get.dialog(AlertDialog(
      title: Text(teacher == null ? 'Add Teacher' : 'Edit Teacher'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
          TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
          TextField(controller: subjectCtrl, decoration: const InputDecoration(labelText: 'Subject ID')),
        ],
      ),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Cancel')),
        TextButton(
            onPressed: () {
              final model = TeacherModel(
                id: teacher?.id ?? '',
                name: nameCtrl.text,
                email: emailCtrl.text,
                subjectId: subjectCtrl.text,
              );
              if (teacher == null) {
                c.addTeacher(model);
              } else {
                c.updateTeacher(model);
              }
              Get.back();
            },
            child: const Text('Save')),
      ],
    ));
  }

  void _showClassDialog({SchoolClassModel? schoolClass}) {
    final nameCtrl = TextEditingController(text: schoolClass?.name);
    final teacherCtrl = TextEditingController(text: schoolClass?.teacherId);
    Get.dialog(AlertDialog(
      title: Text(schoolClass == null ? 'Add Class' : 'Edit Class'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
          TextField(controller: teacherCtrl, decoration: const InputDecoration(labelText: 'Teacher ID')),
        ],
      ),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Cancel')),
        TextButton(
            onPressed: () {
              final model = SchoolClassModel(
                id: schoolClass?.id ?? '',
                name: nameCtrl.text,
                teacherId: teacherCtrl.text,
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
    ));
  }

  void _showChildDialog({ChildModel? child}) {
    final nameCtrl = TextEditingController(text: child?.name);
    final parentCtrl = TextEditingController(text: child?.parentId);
    final classCtrl = TextEditingController(text: child?.classId);
    Get.dialog(AlertDialog(
      title: Text(child == null ? 'Add Child' : 'Edit Child'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
          TextField(controller: parentCtrl, decoration: const InputDecoration(labelText: 'Parent ID')),
          TextField(controller: classCtrl, decoration: const InputDecoration(labelText: 'Class ID')),
        ],
      ),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Cancel')),
        TextButton(
            onPressed: () {
              final model = ChildModel(
                id: child?.id ?? '',
                name: nameCtrl.text,
                parentId: parentCtrl.text,
                classId: classCtrl.text,
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
    ));
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
