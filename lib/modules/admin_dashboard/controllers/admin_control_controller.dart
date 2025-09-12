import 'package:get/get.dart';

import '../../../core/services/database_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../data/models/child_model.dart';
import '../../../data/models/parent_model.dart';
import '../../../data/models/school_class_model.dart';
import '../../../data/models/subject_model.dart';
import '../../../data/models/teacher_model.dart';

class AdminControlController extends GetxController {
  final DatabaseService _db = Get.find();
  final AuthService _auth = Get.find();

  final RxList<ParentModel> parents = <ParentModel>[].obs;
  final RxList<TeacherModel> teachers = <TeacherModel>[].obs;
  final RxList<SchoolClassModel> classes = <SchoolClassModel>[].obs;
  final RxList<ChildModel> children = <ChildModel>[].obs;
  final RxList<SubjectModel> subjects = <SubjectModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    parents.bindStream(_db.firestore
        .collection('parents')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ParentModel.fromDoc(d)).toList()));
    teachers.bindStream(_db.firestore
        .collection('teachers')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => TeacherModel.fromDoc(d)).toList()));
    classes.bindStream(_db.firestore
        .collection('classes')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => SchoolClassModel.fromDoc(d)).toList()));
    children.bindStream(_db.firestore
        .collection('children')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ChildModel.fromDoc(d)).toList()));
    subjects.bindStream(_db.firestore
        .collection('subjects')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => SubjectModel.fromDoc(d)).toList()));
  }

  Future<void> addParent(
      {required String name,
      required String email,
      required String phone,
      required String password}) async {
    final uid = await _auth.createUser(email, password, 'parent');
    await _db.addParent(ParentModel(
      id: uid,
      name: name,
      email: email,
      phone: phone,
    ));
  }

  Future<void> updateParent(ParentModel parent) async {
    await _db.updateParent(parent);
  }

  Future<void> deleteParent(String id) async {
    await _db.deleteParent(id);
  }

  Future<void> addTeacher(
      {required String name,
      required String email,
      required String subjectId,
      required String password}) async {
    final uid = await _auth.createUser(email, password, 'teacher');
    await _db.addTeacher(TeacherModel(
      id: uid,
      name: name,
      email: email,
      subjectId: subjectId,
    ));
  }

  Future<void> updateTeacher(TeacherModel teacher) async {
    await _db.updateTeacher(teacher);
  }

  Future<void> deleteTeacher(String id) async {
    await _db.deleteTeacher(id);
  }

  Future<void> addClass(SchoolClassModel schoolClass) async {
    await _db.addSchoolClass(schoolClass);
  }

  Future<void> updateClass(SchoolClassModel schoolClass) async {
    await _db.updateSchoolClass(schoolClass);
  }

  Future<void> deleteClass(String id) async {
    await _db.deleteSchoolClass(id);
  }

  Future<void> addChild(ChildModel child) async {
    await _db.addChild(child);
  }

  Future<void> updateChild(ChildModel child) async {
    await _db.updateChild(child);
  }

  Future<void> deleteChild(String id) async {
    await _db.deleteChild(id);
  }

  Future<void> addSubject(SubjectModel subject) async {
    await _db.addSubject(subject);
  }

  Future<void> updateSubject(SubjectModel subject) async {
    await _db.updateSubject(subject);
  }

  Future<void> deleteSubject(String id) async {
    await _db.deleteSubject(id);
  }
}
