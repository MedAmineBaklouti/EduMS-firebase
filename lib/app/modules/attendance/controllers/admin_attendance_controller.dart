import 'dart:async';

import 'package:collection/collection.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/services/database_service.dart';
import '../../../core/services/pdf_downloader/pdf_downloader.dart';
import '../../../data/models/attendance_record_model.dart';
import '../../../data/models/child_model.dart';
import '../../../data/models/school_class_model.dart';
import '../../../data/models/subject_model.dart';
import '../../../data/models/teacher_model.dart';
import '../models/child_attendance_summary.dart';

class AdminAttendanceController extends GetxController {
  final DatabaseService _db = Get.find();

  StreamSubscription? _classesSubscription;
  StreamSubscription? _teachersSubscription;
  StreamSubscription? _subjectsSubscription;
  StreamSubscription? _childrenSubscription;
  StreamSubscription? _sessionsSubscription;

  bool _classesLoaded = false;
  bool _teachersLoaded = false;
  bool _sessionsLoaded = false;
  bool _subjectsLoaded = false;
  bool _childrenLoaded = false;

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  @override
  void onClose() {
    _classesSubscription?.cancel();
    _teachersSubscription?.cancel();
    _subjectsSubscription?.cancel();
    _childrenSubscription?.cancel();
    _sessionsSubscription?.cancel();
    super.onClose();
  }

  final RxList<AttendanceSessionModel> _allClassSessions =
      <AttendanceSessionModel>[].obs;
  final RxList<AttendanceSessionModel> classSessions =
      <AttendanceSessionModel>[].obs;

  final RxList<SchoolClassModel> classes = <SchoolClassModel>[].obs;
  final RxList<TeacherModel> teachers = <TeacherModel>[].obs;
  final RxList<SubjectModel> subjects = <SubjectModel>[].obs;
  final RxList<ChildModel> children = <ChildModel>[].obs;
  final RxList<ChildAttendanceSummary> childSummaries =
      <ChildAttendanceSummary>[].obs;

  final RxnString classFilter = RxnString();
  final Rx<DateTime?> dateFilter = Rx<DateTime?>(null);
  final RxBool isLoading = false.obs;
  final RxnString exportingChildId = RxnString();

  void clearFilters() {
    classFilter.value = null;
    dateFilter.value = null;
    _applySessionFilters();
  }

  Future<void> refreshData() async {
    try {
      final results = await Future.wait([
        _db.firestore.collection('classes').get(),
        _db.firestore.collection('teachers').get(),
        _db.firestore.collection('subjects').get(),
        _db.firestore.collection('children').get(),
        _db.firestore.collection('attendanceSessions').get(),
      ]);

      final classSnapshot = results[0];
      final teacherSnapshot = results[1];
      final subjectSnapshot = results[2];
      final childSnapshot = results[3];
      final sessionSnapshot = results[4];

      setClasses(
        classSnapshot.docs.map(SchoolClassModel.fromDoc).toList(),
      );
      setTeachers(
        teacherSnapshot.docs.map(TeacherModel.fromDoc).toList(),
      );
      setSubjects(
        subjectSnapshot.docs.map(SubjectModel.fromDoc).toList(),
      );
      setChildren(
        childSnapshot.docs.map(ChildModel.fromDoc).toList(),
      );
      setClassSessions(
        sessionSnapshot.docs.map(AttendanceSessionModel.fromDoc).toList(),
      );
    } catch (error) {
      Get.snackbar(
        'Refresh failed',
        'Unable to refresh attendance data: $error',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  String className(String classId) {
    return classes
            .firstWhereOrNull((item) => item.id == classId)
            ?.name ??
        'Class';
  }

  String? subjectName(String subjectId) {
    return subjects.firstWhereOrNull((item) => item.id == subjectId)?.name;
  }

  void setClasses(List<SchoolClassModel> items) {
    final sorted = List<SchoolClassModel>.from(items)
      ..sort((a, b) => a.name.compareTo(b.name));
    classes.assignAll(sorted);
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
    final sorted = List<TeacherModel>.from(items)
      ..sort((a, b) => a.name.compareTo(b.name));
    teachers.assignAll(sorted);
    _applySessionFilters();
    _teachersLoaded = true;
    _maybeFinishLoading();
  }

  void setSubjects(List<SubjectModel> items) {
    final sorted = List<SubjectModel>.from(items)
      ..sort((a, b) => a.name.compareTo(b.name));
    subjects.assignAll(sorted);
    _subjectsLoaded = true;
    _buildChildSummaries();
    _maybeFinishLoading();
  }

  void setChildren(List<ChildModel> items) {
    final sorted = List<ChildModel>.from(items)
      ..sort((a, b) => a.name.compareTo(b.name));
    children.assignAll(sorted);
    _childrenLoaded = true;
    _buildChildSummaries();
    _maybeFinishLoading();
  }

  void setClassSessions(List<AttendanceSessionModel> sessions) {
    final normalized = sessions
        .map((session) => session.copyWith(date: _normalizeDate(session.date)))
        .toList();
    _allClassSessions.assignAll(normalized);
    _applySessionFilters();
    _sessionsLoaded = true;
    _maybeFinishLoading();
  }

  void setClassFilter(String? classId) {
    classFilter.value = classId;
    _applySessionFilters();
  }

  void setDateFilter(DateTime? date) {
    dateFilter.value = date;
    _applySessionFilters();
  }

  void _applySessionFilters() {
    final classId = classFilter.value;
    final date = dateFilter.value;
    final filtered = _allClassSessions.where((session) {
      final matchesClass =
          classId == null || classId.isEmpty || session.classId == classId;
      final matchesDate = date == null ? true : _isSameDay(session.date, date);
      return matchesClass && matchesDate;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    classSessions.assignAll(filtered);
    _buildChildSummaries();
  }

  void _buildChildSummaries() {
    final filterClassId = classFilter.value;
    final targetDate = _normalizeDate(dateFilter.value ?? DateTime.now());
    final summaries = <String, ChildAttendanceSummaryBuilder>{};
    final classesById = {for (final item in classes) item.id: item};
    final childrenById = {for (final child in children) child.id: child};
    final teachersById = {for (final teacher in teachers) teacher.id: teacher};
    final subjectsById = {for (final subject in subjects) subject.id: subject};

    final classScope = <String>{};
    if (filterClassId != null && filterClassId.isNotEmpty) {
      classScope.add(filterClassId);
    }
    for (final session in classSessions) {
      classScope.add(session.classId);
    }
    if (classScope.isEmpty) {
      for (final classModel in classes) {
        if (classModel.id.isNotEmpty) {
          classScope.add(classModel.id);
        }
      }
    }
    if (classScope.isEmpty) {
      childSummaries.clear();
      return;
    }

    for (final classId in classScope) {
      final classModel = classesById[classId];
      if (classModel == null) continue;
      final classChildren =
          children.where((child) => child.classId == classId).toList();
      for (final child in classChildren) {
        if (child.id.isEmpty) continue;
        final resolvedName =
            child.name.trim().isEmpty ? 'Student' : child.name.trim();
        final builder = summaries.putIfAbsent(child.id, () {
          return ChildAttendanceSummaryBuilder(
            childId: child.id,
            childName: resolvedName,
            classId: classId,
            className: classModel.name,
            displayDate: targetDate,
          );
        });
        builder.childName = resolvedName;
        builder.classId = classId;
        builder.className = classModel.name;
        builder.displayDate = targetDate;
      }
    }

    for (final session in classSessions) {
      final normalizedDate = _normalizeDate(session.date);
      final participants = <String, String>{};
      final classChildren =
          children.where((child) => child.classId == session.classId);
      if (classChildren.isNotEmpty) {
        for (final child in classChildren) {
          if (child.id.isEmpty) continue;
          participants[child.id] = child.name;
        }
      }
      if (participants.isEmpty) {
        for (final record in session.records) {
          if (record.childId.isEmpty) continue;
          participants.putIfAbsent(record.childId, () => record.childName);
        }
      }
      if (participants.isEmpty) {
        continue;
      }

      for (final entry in participants.entries) {
        final childId = entry.key;
        if (childId.isEmpty) {
          continue;
        }
        final childModel = childrenById[childId];
        final displayName = childModel?.name ?? entry.value;
        final resolvedName =
            displayName.trim().isEmpty ? 'Student' : displayName.trim();
        final resolvedClassId = childModel?.classId.isNotEmpty == true
            ? childModel!.classId
            : session.classId;
        final resolvedClassName = resolvedClassId.isNotEmpty
            ? classesById[resolvedClassId]?.name ?? session.className
            : session.className;
        final builder = summaries.putIfAbsent(childId, () {
          return ChildAttendanceSummaryBuilder(
            childId: childId,
            childName: resolvedName,
            classId: resolvedClassId,
            className: resolvedClassName,
            displayDate: targetDate,
          );
        });
        builder.childName = resolvedName;
        if (resolvedClassId.isNotEmpty) {
          builder.classId = resolvedClassId;
          builder.className = resolvedClassName;
        }
        builder.displayDate = targetDate;

        final record = session.records
            .firstWhereOrNull((item) => item.childId == childId);
        final teacherModel = teachersById[session.teacherId];
        final subjectId = teacherModel?.subjectId ?? '';
        final subjectModel =
            subjectId.isEmpty ? null : subjectsById[subjectId];
        final subjectLabel = (subjectModel?.name ?? '').trim().isNotEmpty
            ? subjectModel!.name.trim()
            : session.teacherName;
        final teacherName = (teacherModel?.name ?? '').trim().isNotEmpty
            ? teacherModel!.name.trim()
            : session.teacherName;
        final bool isPending = !session.isSubmitted || record == null;

        builder.addOrUpdateEntry(
          ChildSubjectAttendance(
            sessionId: session.id,
            subjectId: subjectId,
            teacherId: session.teacherId,
            subjectLabel:
                subjectLabel.isEmpty ? session.teacherName : subjectLabel,
            teacherName: teacherName.isEmpty ? session.teacherName : teacherName,
            date: normalizedDate,
            isSubmitted: !isPending,
            status: isPending ? null : record!.status,
            submittedAt: session.submittedAt,
          ),
        );
      }
    }

    for (final classId in classScope) {
      final classModel = classesById[classId];
      if (classModel == null) continue;
      if (classModel.teacherSubjects.isEmpty) {
        continue;
      }
      final classChildren =
          children.where((child) => child.classId == classId).toList();
      if (classChildren.isEmpty) {
        continue;
      }
      final placeholderDate = targetDate;

      for (final child in classChildren) {
        if (child.id.isEmpty) continue;
        final resolvedName =
            child.name.trim().isEmpty ? 'Student' : child.name.trim();
        final builder = summaries.putIfAbsent(child.id, () {
          return ChildAttendanceSummaryBuilder(
            childId: child.id,
            childName: resolvedName,
            classId: classId,
            className: classModel.name,
            displayDate: targetDate,
          );
        });
        builder.childName = resolvedName;
        builder.classId = classId;
        builder.className = classModel.name;
        builder.displayDate = targetDate;

        for (final subjectEntry in classModel.teacherSubjects.entries) {
          final subjectId = subjectEntry.key;
          final teacherId = subjectEntry.value;
          if (subjectId.isEmpty && teacherId.isEmpty) {
            continue;
          }
          final teacherModel =
              teacherId.isEmpty ? null : teachersById[teacherId];
          final subjectModel =
              subjectId.isEmpty ? null : subjectsById[subjectId];
          final subjectName = (subjectModel?.name ?? '').trim();
          final teacherDisplayName = (teacherModel?.name ?? '').trim();
          final resolvedSubjectLabel = subjectName.isNotEmpty
              ? subjectName
              : (teacherDisplayName.isNotEmpty
                  ? teacherDisplayName
                  : 'Subject');
          final resolvedTeacherName = teacherDisplayName.isNotEmpty
              ? teacherDisplayName
              : (teacherId.isEmpty ? 'Unassigned teacher' : 'Unknown teacher');

          builder.addOrUpdateEntry(
            ChildSubjectAttendance(
              sessionId:
                  'pending-${child.id}-${subjectId.isNotEmpty ? subjectId : teacherId}-${_formatDateKey(placeholderDate)}',
              subjectId: subjectId,
              teacherId: teacherId,
              subjectLabel: resolvedSubjectLabel,
              teacherName: resolvedTeacherName,
              date: placeholderDate,
              isSubmitted: false,
              status: null,
            ),
          );
        }
      }
    }

    final results = summaries.values
        .map((builder) => builder.build())
        .toList()
      ..sort((a, b) {
        final classCompare =
            a.className.toLowerCase().compareTo(b.className.toLowerCase());
        if (classCompare != 0) {
          return classCompare;
        }
        return a.childName.toLowerCase().compareTo(b.childName.toLowerCase());
      });
    childSummaries.assignAll(results);
  }

  Future<void> exportChildAttendanceAsPdf(
      ChildAttendanceSummary summary) async {
    if (summary.subjectEntries.isEmpty) {
      Get.snackbar(
        'Nothing to export',
        'No attendance records are available for ${summary.childName}.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (exportingChildId.value != null) {
      return;
    }

    exportingChildId.value = summary.childId;
    try {
      final doc = pw.Document();
      final dateFormatter = DateFormat.yMMMd();
      final now = DateTime.now();
      final tableData = summary.subjectEntries.map((entry) {
        final statusLabel =
            entry.isSubmitted && entry.status != null ? entry.status!.label : 'Pending';
        return [
          dateFormatter.format(entry.date),
          entry.subjectLabel,
          entry.teacherName,
          statusLabel,
        ];
      }).toList();

      doc.addPage(
        pw.MultiPage(
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Attendance – ${summary.childName}',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Text(
              'Class: ${summary.className.isNotEmpty ? summary.className : 'Class'}',
            ),
            pw.SizedBox(height: 4),
            pw.Text('Generated on ${DateFormat.yMMMMd().format(now)}'),
            pw.SizedBox(height: 12),
            pw.Text(
              '${summary.presentCount} present • ${summary.absentCount} absent • ${summary.pendingCount} pending',
              style: const pw.TextStyle(fontSize: 12),
            ),
            pw.SizedBox(height: 16),
            pw.Table.fromTextArray(
              headers: const ['Date', 'Subject', 'Teacher', 'Status'],
              data: tableData,
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
              ),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              cellStyle: const pw.TextStyle(fontSize: 11),
              cellAlignment: pw.Alignment.centerLeft,
              columnWidths: {
                0: const pw.FlexColumnWidth(1.2),
                1: const pw.FlexColumnWidth(2.2),
                2: const pw.FlexColumnWidth(1.8),
                3: const pw.FlexColumnWidth(1.1),
              },
            ),
          ],
        ),
      );

      final sanitizedChild =
          _sanitizeFileName(summary.childName.isEmpty ? 'student' : summary.childName);
      final sanitizedClass =
          _sanitizeFileName(summary.className.isEmpty ? 'class' : summary.className);
      final dateStamp = DateFormat('yyyyMMdd').format(now);
      final fileName =
          'attendance-${sanitizedChild.isEmpty ? 'student' : sanitizedChild}-${sanitizedClass.isEmpty ? 'class' : sanitizedClass}-$dateStamp.pdf';
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
      exportingChildId.value = null;
    }
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  String _formatDateKey(DateTime date) {
    final normalized = _normalizeDate(date);
    final year = normalized.year.toString().padLeft(4, '0');
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '$year$month$day';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _sanitizeFileName(String value) {
    final normalized = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-{2,}'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return normalized;
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

      _subjectsSubscription = _db.firestore
          .collection('subjects')
          .snapshots()
          .listen((snapshot) {
        setSubjects(snapshot.docs.map(SubjectModel.fromDoc).toList());
      });

      _childrenSubscription = _db.firestore
          .collection('children')
          .snapshots()
          .listen((snapshot) {
        setChildren(snapshot.docs.map(ChildModel.fromDoc).toList());
      });

      _sessionsSubscription = _db.firestore
          .collection('attendanceSessions')
          .snapshots()
          .listen((snapshot) {
        setClassSessions(
          snapshot.docs.map(AttendanceSessionModel.fromDoc).toList(),
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
        _subjectsLoaded &&
        _childrenLoaded) {
      isLoading.value = false;
    }
  }
}
