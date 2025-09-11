import 'package:get/get.dart';

import '../../../core/services/database_service.dart';
import '../../../data/models/child_model.dart';
import '../../../data/models/parent_model.dart';
import '../../../data/models/school_class_model.dart';
import '../../../data/models/subject_model.dart';
import '../../../data/models/teacher_model.dart';

class AdminControlController extends GetxController {
  final DatabaseService _db = Get.find();

  final RxList<ParentModel> parents = <ParentModel>[].obs;
  final RxList<TeacherModel> teachers = <TeacherModel>[].obs;
  final RxList<SchoolClassModel> classes = <SchoolClassModel>[].obs;
  final RxList<ChildModel> children = <ChildModel>[].obs;
  final RxList<SubjectModel> subjects = <SubjectModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadParents(),
      _loadTeachers(),
      _loadClasses(),
      _loadChildren(),
      _loadSubjects(),
    ]);
  }

  Future<void> _loadParents() async {
    final snap = await _db.firestore.collection('parents').get();
    parents.assignAll(
        snap.docs.map((d) => ParentModel.fromDoc(d)).toList());
  }

  Future<void> _loadTeachers() async {
    final snap = await _db.firestore.collection('teachers').get();
    teachers.assignAll(
        snap.docs.map((d) => TeacherModel.fromDoc(d)).toList());
  }

  Future<void> _loadClasses() async {
    final snap = await _db.firestore.collection('classes').get();
    classes.assignAll(
        snap.docs.map((d) => SchoolClassModel.fromDoc(d)).toList());
  }

  Future<void> _loadChildren() async {
    final snap = await _db.firestore.collection('children').get();
    children.assignAll(
        snap.docs.map((d) => ChildModel.fromDoc(d)).toList());
  }

  Future<void> _loadSubjects() async {
    final snap = await _db.firestore.collection('subjects').get();
    subjects.assignAll(
        snap.docs.map((d) => SubjectModel.fromDoc(d)).toList());
  }

  Future<void> addParent(ParentModel parent) async {
    await _db.addParent(parent);
    await _loadParents();
  }

  Future<void> updateParent(ParentModel parent) async {
    await _db.updateParent(parent);
    await _loadParents();
  }

  Future<void> deleteParent(String id) async {
    await _db.deleteParent(id);
    await _loadParents();
  }

  Future<void> addTeacher(TeacherModel teacher) async {
    await _db.addTeacher(teacher);
    await _loadTeachers();
  }

  Future<void> updateTeacher(TeacherModel teacher) async {
    await _db.updateTeacher(teacher);
    await _loadTeachers();
  }

  Future<void> deleteTeacher(String id) async {
    await _db.deleteTeacher(id);
    await _loadTeachers();
  }

  Future<void> addClass(SchoolClassModel schoolClass) async {
    await _db.addSchoolClass(schoolClass);
    await _loadClasses();
  }

  Future<void> updateClass(SchoolClassModel schoolClass) async {
    await _db.updateSchoolClass(schoolClass);
    await _loadClasses();
  }

  Future<void> deleteClass(String id) async {
    await _db.deleteSchoolClass(id);
    await _loadClasses();
  }

  Future<void> addChild(ChildModel child) async {
    await _db.addChild(child);
    await _loadChildren();
  }

  Future<void> updateChild(ChildModel child) async {
    await _db.updateChild(child);
    await _loadChildren();
  }

  Future<void> deleteChild(String id) async {
    await _db.deleteChild(id);
    await _loadChildren();
  }

  Future<void> addSubject(SubjectModel subject) async {
    await _db.addSubject(subject);
    await _loadSubjects();
  }

  Future<void> updateSubject(SubjectModel subject) async {
    await _db.updateSubject(subject);
    await _loadSubjects();
  }

  Future<void> deleteSubject(String id) async {
    await _db.deleteSubject(id);
    await _loadSubjects();
  }
}
