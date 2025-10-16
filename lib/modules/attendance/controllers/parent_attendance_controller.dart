import 'dart:async';

import 'package:collection/collection.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:edums/modules/auth/service/auth_service.dart';
import '../../../common/services/database_service.dart';
import '../../../common/services/pdf_downloader/pdf_downloader.dart';
import '../models/attendance_record_model.dart';
import '../../common/models/child_model.dart';
import '../../common/models/school_class_model.dart';
import '../../common/models/subject_model.dart';
import '../../common/models/teacher_model.dart';
import '../models/child_attendance_summary.dart';

class ParentAttendanceController extends GetxController {
  final DatabaseService _db = Get.find();
  final AuthService _auth = Get.find();

  StreamSubscription? _childrenSubscription;
  StreamSubscription? _sessionsSubscription;
  StreamSubscription? _classesSubscription;
  StreamSubscription? _teachersSubscription;
  StreamSubscription? _subjectsSubscription;

  bool _childrenLoaded = false;
  bool _sessionsLoaded = false;
  bool _classesLoaded = false;
  bool _teachersLoaded = false;
  bool _subjectsLoaded = false;

  final Set<String> _childIds = <String>{};

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  @override
  void onClose() {
    _childrenSubscription?.cancel();
    _sessionsSubscription?.cancel();
    _classesSubscription?.cancel();
    _teachersSubscription?.cancel();
    _subjectsSubscription?.cancel();
    super.onClose();
  }

  final RxList<AttendanceSessionModel> _allSessions =
      <AttendanceSessionModel>[].obs;
  final RxList<AttendanceSessionModel> sessions =
      <AttendanceSessionModel>[].obs;
  final RxList<ChildModel> children = <ChildModel>[].obs;
  final RxList<SchoolClassModel> classes = <SchoolClassModel>[].obs;
  final RxList<TeacherModel> teachers = <TeacherModel>[].obs;
  final RxList<SubjectModel> subjects = <SubjectModel>[].obs;

  final RxList<ChildAttendanceSummary> _allChildSummaries =
      <ChildAttendanceSummary>[].obs;
  final RxList<ChildAttendanceSummary> childSummaries =
      <ChildAttendanceSummary>[].obs;

  final RxnString childFilter = RxnString();
  final Rx<DateTime?> dateFilter = Rx<DateTime?>(null);
  final RxBool isLoading = false.obs;
  final RxnString exportingChildId = RxnString();

  void clearFilters() {
    childFilter.value = null;
    dateFilter.value = null;
    _applyFilters();
  }

  void setChildren(List<ChildModel> items) {
    children.assignAll(items);
    if (childFilter.value != null &&
        children.firstWhereOrNull((child) => child.id == childFilter.value) ==
            null) {
      childFilter.value = null;
    }
    _childIds
      ..clear()
      ..addAll(items.map((child) => child.id));
    if (children.length == 1 &&
        (childFilter.value == null || childFilter.value!.isEmpty)) {
      childFilter.value = children.first.id;
    }
    _applyFilters();
    _childrenLoaded = true;
    _maybeFinishLoading();
  }

  void setClasses(List<SchoolClassModel> items) {
    final sorted = List<SchoolClassModel>.from(items)
      ..sort((a, b) => a.name.compareTo(b.name));
    classes.assignAll(sorted);
    _classesLoaded = true;
    _applyFilters();
    _maybeFinishLoading();
  }

  void setTeachers(List<TeacherModel> items) {
    final sorted = List<TeacherModel>.from(items)
      ..sort((a, b) => a.name.compareTo(b.name));
    teachers.assignAll(sorted);
    _teachersLoaded = true;
    _applyFilters();
    _maybeFinishLoading();
  }

  void setSubjects(List<SubjectModel> items) {
    final sorted = List<SubjectModel>.from(items)
      ..sort((a, b) => a.name.compareTo(b.name));
    subjects.assignAll(sorted);
    _subjectsLoaded = true;
    _applyFilters();
    _maybeFinishLoading();
  }

  void setSessions(List<AttendanceSessionModel> items) {
    final normalized = items
        .map((session) => session.copyWith(date: _normalizeDate(session.date)))
        .toList();
    _allSessions.assignAll(normalized);
    _applyFilters();
    _sessionsLoaded = true;
    _maybeFinishLoading();
  }

  void setChildFilter(String? childId) {
    childFilter.value = childId;
    _applySummaryFilters();
  }

  void setDateFilter(DateTime? date) {
    dateFilter.value = date == null ? null : _normalizeDate(date);
    _applyFilters();
  }

  void _applyFilters() {
    if (_childIds.isEmpty) {
      sessions.clear();
      _allChildSummaries.clear();
      childSummaries.clear();
      return;
    }

    final targetDate = dateFilter.value;
    final relevantSessions = _allSessions.where((session) {
      final hasChild =
          session.records.any((entry) => _childIds.contains(entry.childId));
      if (!hasChild) {
        return false;
      }
      if (targetDate != null && !_isSameDay(session.date, targetDate)) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    sessions.assignAll(relevantSessions);
    _buildChildSummaries(relevantSessions);
  }

  void _buildChildSummaries(List<AttendanceSessionModel> sessionList) {
    if (_childIds.isEmpty) {
      _allChildSummaries.clear();
      childSummaries.clear();
      return;
    }

    final targetDate = _normalizeDate(dateFilter.value ?? DateTime.now());
    final builders = <String, ChildAttendanceSummaryBuilder>{};
    final childrenById = {for (final child in children) child.id: child};
    final classesById = {for (final item in classes) item.id: item};
    final teachersById = {for (final item in teachers) item.id: item};
    final subjectsById = {for (final item in subjects) item.id: item};

    final classScope = <String>{};
    for (final child in children) {
      if (child.classId.isNotEmpty) {
        classScope.add(child.classId);
      }
    }
    for (final session in sessionList) {
      if (session.records.any((entry) => _childIds.contains(entry.childId))) {
        classScope.add(session.classId);
      }
    }
    if (classScope.isEmpty) {
      _allChildSummaries.clear();
      childSummaries.clear();
      return;
    }

    for (final child in children) {
      if (child.id.isEmpty) continue;
      final classModel = classesById[child.classId];
      final resolvedName =
          child.name.trim().isEmpty ? 'Student' : child.name.trim();
      final builder = builders.putIfAbsent(child.id, () {
        return ChildAttendanceSummaryBuilder(
          childId: child.id,
          childName: resolvedName,
          classId: child.classId,
          className: classModel?.name ?? 'Class',
          displayDate: targetDate,
        );
      });
      builder.childName = resolvedName;
      builder.displayDate = targetDate;
      if (child.classId.isNotEmpty) {
        builder.classId = child.classId;
        builder.className = classModel?.name ?? builder.className;
      }
    }

    for (final session in sessionList) {
      final normalizedDate = _normalizeDate(session.date);
      final participants = <String, String>{};
      for (final record in session.records) {
        if (_childIds.contains(record.childId)) {
          participants.putIfAbsent(record.childId, () => record.childName);
        }
      }
      if (participants.isEmpty) {
        continue;
      }

      for (final entry in participants.entries) {
        final childId = entry.key;
        final childModel = childrenById[childId];
        final displayName = childModel?.name ?? entry.value;
        final resolvedName =
            displayName.trim().isEmpty ? 'Student' : displayName.trim();
        final builder = builders.putIfAbsent(childId, () {
          return ChildAttendanceSummaryBuilder(
            childId: childId,
            childName: resolvedName,
            classId: childModel?.classId ?? session.classId,
            className: childModel?.classId.isNotEmpty == true
                ? classesById[childModel!.classId]?.name ?? session.className
                : session.className,
            displayDate: targetDate,
          );
        });
        builder.childName = resolvedName;
        builder.displayDate = targetDate;
        if (childModel?.classId.isNotEmpty == true) {
          builder.classId = childModel!.classId;
          builder.className =
              classesById[childModel.classId]?.name ?? builder.className;
        } else if (session.classId.isNotEmpty) {
          builder.classId = session.classId;
          builder.className = session.className;
        }

        final record =
            session.records.firstWhereOrNull((item) => item.childId == childId);
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

    final placeholderDate =
        targetDate;
    for (final classId in classScope) {
      final classModel = classesById[classId];
      if (classModel == null || classModel.teacherSubjects.isEmpty) {
        continue;
      }
      final classChildren =
          children.where((child) => child.classId == classId).toList();
      if (classChildren.isEmpty) {
        continue;
      }

      for (final child in classChildren) {
        if (child.id.isEmpty) continue;
        final resolvedName =
            child.name.trim().isEmpty ? 'Student' : child.name.trim();
        final builder = builders.putIfAbsent(child.id, () {
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

    final results = builders.values
        .map((builder) => builder.build())
        .toList()
      ..sort((a, b) =>
          a.childName.toLowerCase().compareTo(b.childName.toLowerCase()));

    _allChildSummaries.assignAll(results);
    _applySummaryFilters();
  }

  void _applySummaryFilters() {
    final selectedChild = childFilter.value;
    if (selectedChild == null || selectedChild.isEmpty) {
      childSummaries.assignAll(_allChildSummaries);
      return;
    }
    childSummaries.assignAll(
      _allChildSummaries.where((summary) => summary.childId == selectedChild),
    );
  }

  Future<void> refreshData() async {
    final parentId = _auth.currentUser?.uid;
    if (parentId == null) {
      return;
    }

    final childrenSnapshot = await _db.firestore
        .collection('children')
        .where('parentId', isEqualTo: parentId)
        .get();
    setChildren(childrenSnapshot.docs.map(ChildModel.fromDoc).toList());

    final sessionsSnapshot =
        await _db.firestore.collection('attendanceSessions').get();
    setSessions(
        sessionsSnapshot.docs.map(AttendanceSessionModel.fromDoc).toList());

    final classesSnapshot = await _db.firestore.collection('classes').get();
    setClasses(classesSnapshot.docs.map(SchoolClassModel.fromDoc).toList());

    final teachersSnapshot = await _db.firestore.collection('teachers').get();
    setTeachers(teachersSnapshot.docs.map(TeacherModel.fromDoc).toList());

    final subjectsSnapshot = await _db.firestore.collection('subjects').get();
    setSubjects(subjectsSnapshot.docs.map(SubjectModel.fromDoc).toList());
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

  void _initialize() {
    final parentId = _auth.currentUser?.uid;
    if (parentId == null) {
      Get.snackbar(
        'Authentication required',
        'Unable to determine the authenticated parent.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isLoading.value = true;

    _childrenSubscription = _db.firestore
        .collection('children')
        .where('parentId', isEqualTo: parentId)
        .snapshots()
        .listen((snapshot) {
      setChildren(snapshot.docs.map(ChildModel.fromDoc).toList());
    });

    _sessionsSubscription = _db.firestore
        .collection('attendanceSessions')
        .snapshots()
        .listen((snapshot) {
      setSessions(snapshot.docs.map(AttendanceSessionModel.fromDoc).toList());
    });

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
  }

  void _maybeFinishLoading() {
    if (_childrenLoaded &&
        _sessionsLoaded &&
        _classesLoaded &&
        _teachersLoaded &&
        _subjectsLoaded) {
      isLoading.value = false;
    }
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDateKey(DateTime date) {
    final normalized = _normalizeDate(date);
    final year = normalized.year.toString().padLeft(4, '0');
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '$year$month$day';
  }

  String _sanitizeFileName(String value) {
    final normalized = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-{2,}'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return normalized;
  }
}
