import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/services/database_service.dart';
import '../../../core/services/pdf_downloader/pdf_downloader.dart';
import '../../../data/models/attendance_record_model.dart';
import '../../../data/models/school_class_model.dart';
import '../../../data/models/subject_model.dart';
import '../../../data/models/teacher_model.dart';

class AdminTeacherAttendanceController extends GetxController {
  final DatabaseService _db = Get.find();

  StreamSubscription? _teachersSubscription;
  StreamSubscription? _attendanceSubscription;
  StreamSubscription? _classesSubscription;
  StreamSubscription? _subjectsSubscription;

  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;
  final RxBool isExporting = false.obs;

  final RxList<TeacherModel> teachers = <TeacherModel>[].obs;
  final RxList<SchoolClassModel> classes = <SchoolClassModel>[].obs;
  final RxList<SubjectModel> subjects = <SubjectModel>[].obs;
  final RxList<TeacherAttendanceRecord> _records = <TeacherAttendanceRecord>[].obs;
  final RxList<TeacherAttendanceRecord> currentEntries = <TeacherAttendanceRecord>[].obs;

  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final RxnString classFilter = RxnString();
  final RxnString subjectFilter = RxnString();

  bool _teachersLoaded = false;
  bool _attendanceLoaded = false;
  bool _classesLoaded = false;
  bool _subjectsLoaded = false;

  final Map<String, Set<String>> _teacherClassMap = <String, Set<String>>{};

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  @override
  void onClose() {
    _teachersSubscription?.cancel();
    _attendanceSubscription?.cancel();
    _classesSubscription?.cancel();
    _subjectsSubscription?.cancel();
    super.onClose();
  }

  void setDate(DateTime date) {
    selectedDate.value = DateTime(date.year, date.month, date.day);
    _rebuildEntries();
  }

  void updateStatus(String teacherId, AttendanceStatus status) {
    final index = currentEntries.indexWhere((entry) => entry.teacherId == teacherId);
    if (index == -1) {
      return;
    }
    final entry = currentEntries[index];
    currentEntries[index] = entry.copyWith(status: status);
  }

  void clearFilters() {
    classFilter.value = null;
    subjectFilter.value = null;
    _rebuildEntries();
  }

  Future<void> refreshData() async {
    try {
      final results = await Future.wait([
        _db.firestore.collection('teachers').get(),
        _db.firestore.collection('classes').get(),
        _db.firestore.collection('subjects').get(),
        _db.firestore.collection('teacherAttendanceRecords').get(),
      ]);

      final teacherSnapshot = results[0];
      final classSnapshot = results[1];
      final subjectSnapshot = results[2];
      final attendanceSnapshot = results[3];

      setTeachers(
        teacherSnapshot.docs.map(TeacherModel.fromDoc).toList(),
      );
      setClasses(
        classSnapshot.docs.map(SchoolClassModel.fromDoc).toList(),
      );
      setSubjects(
        subjectSnapshot.docs.map(SubjectModel.fromDoc).toList(),
      );
      _records.assignAll(
        attendanceSnapshot.docs.map(TeacherAttendanceRecord.fromDoc).toList(),
      );
      _attendanceLoaded = true;
      _rebuildEntries();
      _maybeFinishLoading();
    } catch (error) {
      Get.snackbar(
        'Refresh failed',
        'Unable to refresh teacher attendance data: $error',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void setClassFilter(String? classId) {
    classFilter.value = classId == null || classId.isEmpty ? null : classId;
    _rebuildEntries();
  }

  void setSubjectFilter(String? subjectId) {
    subjectFilter.value = subjectId == null || subjectId.isEmpty ? null : subjectId;
    _rebuildEntries();
  }

  String? className(String classId) {
    return classes.firstWhereOrNull((item) => item.id == classId)?.name;
  }

  String? subjectName(String subjectId) {
    return subjects.firstWhereOrNull((item) => item.id == subjectId)?.name;
  }

  String subjectLabelForTeacher(String teacherId) {
    final teacher = teachers.firstWhereOrNull((item) => item.id == teacherId);
    if (teacher == null || teacher.subjectId.isEmpty) {
      return 'Subject';
    }
    final subject = subjectName(teacher.subjectId);
    return subject == null || subject.isEmpty ? 'Subject' : subject;
  }

  List<String> classNamesForTeacher(String teacherId) {
    final classIds = _teacherClassMap[teacherId];
    if (classIds == null || classIds.isEmpty) {
      return const <String>[];
    }
    final names = classIds
        .map((id) => className(id))
        .whereType<String>()
        .where((name) => name.isNotEmpty)
        .toList()
      ..sort((a, b) => a.compareTo(b));
    return names;
  }

  String subjectLabelForRecord(TeacherAttendanceRecord record) {
    if (record.subjectId.isNotEmpty) {
      final subject = subjectName(record.subjectId);
      if (subject != null && subject.isNotEmpty) {
        return subject;
      }
    }
    return subjectLabelForTeacher(record.teacherId);
  }

  void setTeachers(List<TeacherModel> items) {
    final sorted = List<TeacherModel>.from(items)
      ..sort((a, b) => a.name.compareTo(b.name));
    teachers.assignAll(sorted);
    _teachersLoaded = true;
    _rebuildEntries();
    _maybeFinishLoading();
  }

  void setClasses(List<SchoolClassModel> items) {
    final sorted = List<SchoolClassModel>.from(items)
      ..sort((a, b) => a.name.compareTo(b.name));
    classes.assignAll(sorted);
    _rebuildTeacherAssignments();
    final selected = classFilter.value;
    if (selected != null && selected.isNotEmpty) {
      final exists = classes.firstWhereOrNull((item) => item.id == selected);
      if (exists == null) {
        classFilter.value = null;
      }
    }
    _classesLoaded = true;
    _rebuildEntries();
    _maybeFinishLoading();
  }

  void setSubjects(List<SubjectModel> items) {
    final sorted = List<SubjectModel>.from(items)
      ..sort((a, b) => a.name.compareTo(b.name));
    subjects.assignAll(sorted);
    final selected = subjectFilter.value;
    if (selected != null && selected.isNotEmpty) {
      final exists = subjects.firstWhereOrNull((item) => item.id == selected);
      if (exists == null) {
        subjectFilter.value = null;
      }
    }
    _subjectsLoaded = true;
    _rebuildEntries();
    _maybeFinishLoading();
  }

  Future<void> saveAttendance() async {
    if (currentEntries.isEmpty) {
      Get.snackbar(
        'No teachers found',
        'There are no teachers to mark on this date.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    isSaving.value = true;
    try {
      final entries = currentEntries.toList();
      final batch = _db.firestore.batch();
      final day = selectedDate.value;
      for (final entry in entries) {
        final normalized = entry.copyWith(date: day);
        final docRef =
            _db.firestore.collection('teacherAttendanceRecords').doc(normalized.id);
        batch.set(docRef, normalized.toMap());
      }
      await batch.commit();
      final presentCount = entries
          .where((entry) => entry.status == AttendanceStatus.present)
          .length;
      final absentCount = entries
          .where((entry) => entry.status == AttendanceStatus.absent)
          .length;
      final dateLabel = DateFormat.yMMMd().format(day);
      Get.snackbar(
        'Attendance saved',
        '$presentCount present and $absentCount absent recorded for $dateLabel.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      Get.snackbar(
        'Save failed',
        'Unable to store attendance: $error',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> exportAttendanceAsPdf() async {
    final entries = currentEntries;
    if (entries.isEmpty) {
      Get.snackbar(
        'Nothing to export',
        'Add at least one teacher attendance record before exporting.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    isExporting.value = true;
    try {
      final dateLabel = DateFormat.yMMMMd().format(selectedDate.value);
      final doc = pw.Document();
      final tableData = entries
          .map(
            (entry) => [
              entry.teacherName,
              subjectLabelForRecord(entry),
              entry.status.label,
            ],
          )
          .toList();

      doc.addPage(
        pw.MultiPage(
          build: (pw.Context context) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Teacher Attendance – $dateLabel',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Table.fromTextArray(
              headers: const ['Teacher', 'Subject', 'Status'],
              data: tableData,
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              cellStyle: const pw.TextStyle(fontSize: 11),
              cellAlignment: pw.Alignment.centerLeft,
              columnWidths: {
                0: const pw.FlexColumnWidth(2.4),
                1: const pw.FlexColumnWidth(1.8),
                2: const pw.FlexColumnWidth(1.2),
              },
            ),
          ],
        ),
      );

      final fileName =
          'teacher-attendance-${DateFormat('yyyyMMdd').format(selectedDate.value)}.pdf';
      final bytes = await doc.save();
      final savedPath = await savePdf(bytes, fileName);
      Get.closeCurrentSnackbar();
      Get.snackbar(
        'Download complete',
        savedPath != null
            ? 'Saved to $savedPath'
            : 'The PDF was not saved. Please check storage permissions or try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      Get.snackbar(
        'Export failed',
        'Unable to create the PDF: $error',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isExporting.value = false;
    }
  }

  void _initialize() {
    try {
      _teachersSubscription = _db.firestore
          .collection('teachers')
          .snapshots()
          .listen((snapshot) {
        setTeachers(snapshot.docs.map(TeacherModel.fromDoc).toList());
      });

      _classesSubscription = _db.firestore
          .collection('classes')
          .snapshots()
          .listen((snapshot) {
        setClasses(snapshot.docs.map(SchoolClassModel.fromDoc).toList());
      });

      _subjectsSubscription = _db.firestore
          .collection('subjects')
          .snapshots()
          .listen((snapshot) {
        setSubjects(snapshot.docs.map(SubjectModel.fromDoc).toList());
      });

      _attendanceSubscription = _db.firestore
          .collection('teacherAttendanceRecords')
          .snapshots()
          .listen((snapshot) {
        _records.assignAll(
          snapshot.docs.map(TeacherAttendanceRecord.fromDoc).toList(),
        );
        _attendanceLoaded = true;
        _rebuildEntries();
        _maybeFinishLoading();
      });
    } catch (error) {
      isLoading.value = false;
      Get.snackbar(
        'Load failed',
        'Unable to load teacher attendance data: $error',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _rebuildTeacherAssignments() {
    _teacherClassMap.clear();
    for (final schoolClass in classes) {
      for (final entry in schoolClass.teacherSubjects.entries) {
        final teacherId = entry.value;
        if (teacherId.isEmpty) {
          continue;
        }
        _teacherClassMap.putIfAbsent(teacherId, () => <String>{}).add(schoolClass.id);
      }
    }
  }

  void _rebuildEntries() {
    if (teachers.isEmpty) {
      currentEntries.clear();
      return;
    }
    final day = selectedDate.value;
    final classId = classFilter.value;
    final subjectId = subjectFilter.value;
    final dayRecords =
        _records.where((record) => _isSameDay(record.date, day)).toList();

    final filteredTeachers = teachers.where((teacher) {
      final matchesSubject =
          subjectId == null || subjectId.isEmpty || teacher.subjectId == subjectId;
      final assignedClasses = _teacherClassMap[teacher.id] ?? <String>{};
      final matchesClass = classId == null || classId.isEmpty
          ? true
          : assignedClasses.contains(classId);
      return matchesSubject && matchesClass;
    }).toList();

    final entries = filteredTeachers.map((teacher) {
      final existing =
          dayRecords.firstWhereOrNull((record) => record.teacherId == teacher.id);
      if (existing != null) {
        return existing.copyWith(
          teacherName: teacher.name,
          subjectId: teacher.subjectId,
          date: DateTime(day.year, day.month, day.day),
        );
      }
      return TeacherAttendanceRecord(
        id: _composeRecordId(teacher.id, day),
        teacherId: teacher.id,
        teacherName: teacher.name,
        subjectId: teacher.subjectId,
        date: DateTime(day.year, day.month, day.day),
        status: AttendanceStatus.pending,
        note: '',
      );
    }).toList()
      ..sort((a, b) => a.teacherName.compareTo(b.teacherName));

    currentEntries.assignAll(entries);
  }

  void _maybeFinishLoading() {
    if (_teachersLoaded && _attendanceLoaded && _classesLoaded && _subjectsLoaded) {
      isLoading.value = false;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _composeRecordId(String teacherId, DateTime date) {
    final safeDate = DateFormat('yyyyMMdd').format(date);
    return '$teacherId-$safeDate';
  }
}
