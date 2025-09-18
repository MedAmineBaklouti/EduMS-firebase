import 'package:collection/collection.dart';
import 'package:get/get.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/database_service.dart';
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

  final RxString selectedParentClassId = ''.obs;
  final RxString selectedTeacherClassId = ''.obs;

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

  Future<void> addParent(ParentModel parent, String password) async {
    final uid = await _auth.registerUser(
        email: parent.email, password: password, role: 'parent');
    final model = ParentModel(
      id: uid,
      name: parent.name,
      email: parent.email,
      phone: parent.phone,
    );
    await _db.addParent(model);
    await _loadAll();
  }

  Future<void> updateParent(ParentModel parent) async {
    await _db.updateParent(parent);
    await _loadAll();
  }

  Future<void> deleteParent(String id) async {
    await _db.deleteParent(id);
    await _loadAll();
  }

  Future<void> addTeacher(TeacherModel teacher, String password) async {
    final uid = await _auth.registerUser(
        email: teacher.email, password: password, role: 'teacher');
    final model = TeacherModel(
      id: uid,
      name: teacher.name,
      email: teacher.email,
      subjectId: teacher.subjectId,
    );
    await _db.addTeacher(model);
    await _loadAll();
  }

  Future<void> updateTeacher(TeacherModel teacher) async {
    await _db.updateTeacher(teacher);
    await _loadAll();
  }

  Future<void> deleteTeacher(String id) async {
    await _db.deleteTeacher(id);
    await _loadAll();
  }

  Future<void> addClass(SchoolClassModel schoolClass) async {
    final id = await _db.addSchoolClass(schoolClass);
    if (schoolClass.childIds.isNotEmpty) {
      await _db.setChildrenClass(schoolClass.childIds, id);
    }
    await _loadAll();
  }

  Future<void> updateClass(SchoolClassModel schoolClass,
      {required List<String> previousChildIds}) async {
    await _db.updateSchoolClass(schoolClass);

    final added = schoolClass.childIds
        .where((id) => !previousChildIds.contains(id))
        .toList();
    final removed = previousChildIds
        .where((id) => !schoolClass.childIds.contains(id))
        .toList();

    if (added.isNotEmpty) {
      await _db.setChildrenClass(added, schoolClass.id);
    }
    if (removed.isNotEmpty) {
      await _db.setChildrenClass(removed, '');
    }

    await _loadAll();
  }

  Future<void> deleteClass(String id) async {
    await _db.deleteSchoolClass(id);
    await _loadAll();
  }

  Future<void> addChild(ChildModel child) async {
    await _db.addChild(child);
    await _loadAll();
  }

  Future<void> updateChild(ChildModel child) async {
    await _db.updateChild(child);
    await _loadAll();
  }

  Future<void> deleteChild(String id) async {
    await _db.deleteChild(id);
    await _loadAll();
  }

  Future<void> addSubject(SubjectModel subject) async {
    await _db.addSubject(subject);
    await _loadAll();
  }

  Future<void> updateSubject(SubjectModel subject) async {
    await _db.updateSubject(subject);
    await _loadAll();
  }

  Future<void> deleteSubject(String id) async {
    await _db.deleteSubject(id);
    await _loadAll();
  }

  List<ParentModel> get filteredParents {
    final classId = selectedParentClassId.value;
    if (classId.isEmpty) {
      return parents.toList();
    }

    final parentIdsForClass = children
        .where((child) => child.classId == classId && child.parentId.isNotEmpty)
        .map((child) => child.parentId)
        .toSet();

    return parents
        .where((parent) => parentIdsForClass.contains(parent.id))
        .toList();
  }

  List<TeacherModel> get filteredTeachers {
    final classId = selectedTeacherClassId.value;
    if (classId.isEmpty) {
      return teachers.toList();
    }

    final schoolClass = classes.firstWhereOrNull((cls) => cls.id == classId);
    if (schoolClass == null) {
      return <TeacherModel>[];
    }

    final teacherIds = schoolClass.teacherSubjects.values
        .where((id) => id.isNotEmpty)
        .toSet();

    return teachers
        .where((teacher) => teacherIds.contains(teacher.id))
        .toList();
  }

  void updateParentClassFilter(String value) {
    selectedParentClassId.value = value;
  }

  void clearParentFilters() {
    selectedParentClassId.value = '';
  }

  void updateTeacherClassFilter(String value) {
    selectedTeacherClassId.value = value;
  }

  void clearTeacherFilters() {
    selectedTeacherClassId.value = '';
  }
}
