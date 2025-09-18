import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../data/models/child_model.dart';
import '../../data/models/parent_model.dart';
import '../../data/models/school_class_model.dart';
import '../../data/models/subject_model.dart';
import '../../data/models/announcement_model.dart';
import '../../data/models/teacher_model.dart';
import '../../data/models/course_model.dart';

class DatabaseService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RxBool isInitialized = false.obs;

  Future<DatabaseService> init() async {
    // Configure any Firestore settings if needed
    // await _firestore.settings = const Settings(...);

    isInitialized.value = true;
    return this;
  }

  // Firestore instance getter for direct access when needed
  FirebaseFirestore get firestore => _firestore;

  /// Parent CRUD operations
  Future<void> addParent(ParentModel parent) async {
    await _firestore.collection('parents').doc(parent.id).set(parent.toMap());
  }

  Future<void> updateParent(ParentModel parent) async {
    await _firestore.collection('parents').doc(parent.id).update(parent.toMap());
  }

  Future<void> deleteParent(String id) async {
    await _firestore.collection('parents').doc(id).delete();
  }

  /// Teacher CRUD operations
  Future<void> addTeacher(TeacherModel teacher) async {
    await _firestore.collection('teachers').doc(teacher.id).set(teacher.toMap());
  }

  Future<void> updateTeacher(TeacherModel teacher) async {
    await _firestore.collection('teachers').doc(teacher.id).update(teacher.toMap());
  }

  Future<void> deleteTeacher(String id) async {
    await _firestore.collection('teachers').doc(id).delete();
  }

  /// Subject CRUD operations
  Future<void> addSubject(SubjectModel subject) async {
    await _firestore.collection('subjects').add(subject.toMap());
  }

  Future<void> updateSubject(SubjectModel subject) async {
    await _firestore.collection('subjects').doc(subject.id).update(subject.toMap());
  }

  Future<void> deleteSubject(String id) async {
    await _firestore.collection('subjects').doc(id).delete();
  }

  /// School class CRUD operations
  Future<String> addSchoolClass(SchoolClassModel schoolClass) async {
    final doc = await _firestore.collection('classes').add(schoolClass.toMap());
    return doc.id;
  }

  Future<void> updateSchoolClass(SchoolClassModel schoolClass) async {
    await _firestore.collection('classes').doc(schoolClass.id).update(schoolClass.toMap());
  }

  Future<void> deleteSchoolClass(String id) async {
    await _firestore.collection('classes').doc(id).delete();
  }

  Future<void> setChildrenClass(List<String> childIds, String classId) async {
    final batch = _firestore.batch();
    for (final id in childIds) {
      batch.update(_firestore.collection('children').doc(id), {'classId': classId});
    }
    await batch.commit();
  }

  /// Child CRUD operations
  Future<void> addChild(ChildModel child) async {
    await _firestore.collection('children').add(child.toMap());
  }

  Future<void> updateChild(ChildModel child) async {
    await _firestore.collection('children').doc(child.id).update(child.toMap());
  }

  Future<void> deleteChild(String id) async {
    await _firestore.collection('children').doc(id).delete();
  }

  /// Announcement CRUD operations
  Future<String> addAnnouncement(AnnouncementModel announcement) async {
    final docRef = _firestore.collection('announcements').doc();
    final payload = announcement
        .copyWith(id: docRef.id, createdAt: DateTime.now())
        .toMap(includeId: true, serverTimestamp: true);
    await docRef.set(payload);
    return docRef.id;
  }

  Future<void> updateAnnouncement(AnnouncementModel announcement) async {
    await _firestore.collection('announcements').doc(announcement.id).update(announcement.toMap());
  }

  Future<void> deleteAnnouncement(String id) async {
    await _firestore.collection('announcements').doc(id).delete();
  }

  Stream<List<AnnouncementModel>> streamAnnouncements({String? audience}) {
    Query query = _firestore.collection('announcements');
    if (audience != null) {
      query = query.where('audience', arrayContains: audience);
    }
    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AnnouncementModel.fromDoc(doc)).toList());
  }

  /// Course CRUD operations
  Future<String> addCourse(CourseModel course) async {
    final doc = await _firestore.collection('courses').add(course.toMap());
    return doc.id;
  }

  Future<void> updateCourse(CourseModel course) async {
    await _firestore.collection('courses').doc(course.id).update(course.toMap());
  }

  Future<void> deleteCourse(String id) async {
    await _firestore.collection('courses').doc(id).delete();
  }

  Stream<List<CourseModel>> streamCourses() {
    return _firestore
        .collection('courses')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => CourseModel.fromDoc(doc)).toList());
  }
}
