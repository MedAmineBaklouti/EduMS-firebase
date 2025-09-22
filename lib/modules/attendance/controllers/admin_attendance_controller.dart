import 'package:collection/collection.dart';
import 'package:get/get.dart';

import '../../../data/models/attendance_record_model.dart';
import '../../../data/models/school_class_model.dart';
import '../../../data/models/teacher_model.dart';

class AdminAttendanceController extends GetxController {
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

  void setClasses(List<SchoolClassModel> items) {
    classes.assignAll(items);
    if (classFilter.value != null &&
        classes.firstWhereOrNull((item) => item.id == classFilter.value) ==
            null) {
      classFilter.value = null;
    }
    _applySessionFilters();
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
  }

  void setTeacherRecords(List<TeacherAttendanceRecord> records) {
    _allTeacherRecords.assignAll(records);
    _applyTeacherFilters();
  }

  void setClassSessions(List<AttendanceSessionModel> sessions) {
    _allClassSessions.assignAll(sessions);
    _applySessionFilters();
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
}
