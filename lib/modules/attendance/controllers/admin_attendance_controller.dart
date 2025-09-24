import 'dart:async';

import 'package:collection/collection.dart';
import 'package:get/get.dart';

import '../../../core/services/database_service.dart';
import '../../../data/models/attendance_record_model.dart';
import '../../../data/models/school_class_model.dart';
import '../../../data/models/teacher_model.dart';

class AdminAttendanceController extends GetxController {
  final DatabaseService _db = Get.find();

  StreamSubscription? _classesSubscription;
  StreamSubscription? _teachersSubscription;
  StreamSubscription? _sessionsSubscription;
  StreamSubscription? _teacherAttendanceSubscription;

  bool _classesLoaded = false;
  bool _teachersLoaded = false;
  bool _sessionsLoaded = false;
  bool _teacherAttendanceLoaded = false;

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  @override
  void onClose() {
    _classesSubscription?.cancel();
    _teachersSubscription?.cancel();
    _sessionsSubscription?.cancel();
    _teacherAttendanceSubscription?.cancel();
    super.onClose();
  }

  final RxList<TeacherAttendanceRecord> _allTeacherRecords =
      <TeacherAttendanceRecord>[].obs;
  final RxList<TeacherAttendanceRecord> teacherRecords =
      <TeacherAttendanceRecord>[].obs;

  final RxList<AttendanceSessionModel> _allClassSessions =
      <AttendanceSessionModel>[].obs;
  final RxList<AttendanceSessionModel> classSessions =
      <AttendanceSessionModel>[].obs;

  final RxList<SchoolClassModel> classes = <SchoolClassModel>[].obs;
  final RxList<TeacherModel> teachers = <TeacherModel>[].obs;

  final RxnString classFilter = RxnString();
  final RxnString teacherFilter = RxnString();
  final Rx<DateTime?> dateFilter = Rx<DateTime?>(null);
  final RxBool isLoading = false.obs;

  void clearFilters() {
    classFilter.value = null;
    teacherFilter.value = null;
    dateFilter.value = null;
    _applyTeacherFilters();
    _applySessionFilters();
  }

  String className(String classId) {
    return classes
            .firstWhereOrNull((item) => item.id == classId)
            ?.name ??
        'Class';
  }

  String teacherName(String teacherId) {
    return teachers
            .firstWhereOrNull((item) => item.id == teacherId)
            ?.name ??
        'Teacher';
  }

  void setClasses(List<SchoolClassModel> items) {
    classes.assignAll(items);
    if (classFilter.value != null &&
        classes.firstWhereOrNull((item) => item.id == classFilter.value) ==
            null) {
      classFilter.value = null;
    }
    _applySessionFilters();
    _classesLoaded = true;
    _maybeFinishLoading();
  }

  void setTeachers(List<TeacherModel> items) {
    teachers.assignAll(items);
    if (teacherFilter.value != null &&
        teachers.firstWhereOrNull((item) => item.id == teacherFilter.value) ==
            null) {
      teacherFilter.value = null;
    }
    _applyTeacherFilters();
    _applySessionFilters();
    _teachersLoaded = true;
    _maybeFinishLoading();
  }

  void setTeacherRecords(List<TeacherAttendanceRecord> records) {
    _allTeacherRecords.assignAll(records);
    _applyTeacherFilters();
    _teacherAttendanceLoaded = true;
    _maybeFinishLoading();
  }

  void setClassSessions(List<AttendanceSessionModel> sessions) {
    _allClassSessions.assignAll(sessions);
    _applySessionFilters();
    _sessionsLoaded = true;
    _maybeFinishLoading();
  }

  void setClassFilter(String? classId) {
    classFilter.value = classId;
    _applySessionFilters();
  }

  void setTeacherFilter(String? teacherId) {
    teacherFilter.value = teacherId;
    _applyTeacherFilters();
    _applySessionFilters();
  }

  void setDateFilter(DateTime? date) {
    dateFilter.value = date;
    _applyTeacherFilters();
    _applySessionFilters();
  }

  void _applyTeacherFilters() {
    final teacherId = teacherFilter.value;
    final date = dateFilter.value;
    final filtered = _allTeacherRecords.where((record) {
      final matchesTeacher =
          teacherId == null || teacherId.isEmpty || record.teacherId == teacherId;
      final matchesDate = date == null ? true : _isSameDay(record.date, date);
      return matchesTeacher && matchesDate;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    teacherRecords.assignAll(filtered);
  }

  void _applySessionFilters() {
    final classId = classFilter.value;
    final teacherId = teacherFilter.value;
    final date = dateFilter.value;
    final filtered = _allClassSessions.where((session) {
      final matchesClass =
          classId == null || classId.isEmpty || session.classId == classId;
      final matchesTeacher =
          teacherId == null || teacherId.isEmpty || session.teacherId == teacherId;
      final matchesDate = date == null ? true : _isSameDay(session.date, date);
      return matchesClass && matchesTeacher && matchesDate;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    classSessions.assignAll(filtered);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _initialize() {
    try {
      isLoading.value = true;

      _classesSubscription = _db.firestore
          .collection('classes')
          .snapshots()
          .listen((snapshot) {
        setClasses(snapshot.docs.map(SchoolClassModel.fromDoc).toList());
      });

      _teachersSubscription = _db.firestore
          .collection('teachers')
          .snapshots()
          .listen((snapshot) {
        setTeachers(snapshot.docs.map(TeacherModel.fromDoc).toList());
      });

      _sessionsSubscription = _db.firestore
          .collection('attendanceSessions')
          .snapshots()
          .listen((snapshot) {
        setClassSessions(
          snapshot.docs.map(AttendanceSessionModel.fromDoc).toList(),
        );
      });

      _teacherAttendanceSubscription = _db.firestore
          .collection('teacherAttendanceRecords')
          .snapshots()
          .listen((snapshot) {
        setTeacherRecords(
          snapshot.docs.map(TeacherAttendanceRecord.fromDoc).toList(),
        );
      });
    } catch (error) {
      isLoading.value = false;
      Get.snackbar(
        'Load failed',
        'Unable to load attendance data: $error',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _maybeFinishLoading() {
    if (_classesLoaded &&
        _teachersLoaded &&
        _sessionsLoaded &&
        _teacherAttendanceLoaded) {
      isLoading.value = false;
    }
  }
}
