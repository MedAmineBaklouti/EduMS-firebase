import 'dart:async';

import 'package:collection/collection.dart';
import 'package:get/get.dart';

import '../../../core/services/database_service.dart';
import '../../../data/models/attendance_record_model.dart';
import '../../../data/models/child_model.dart';
import '../../../data/models/school_class_model.dart';
import '../../../data/models/subject_model.dart';
import '../../../data/models/teacher_model.dart';

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

  void clearFilters() {
    classFilter.value = null;
    dateFilter.value = null;
    _applySessionFilters();
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
    final targetDate = dateFilter.value;
    final summaries = <String, _ChildSummaryBuilder>{};
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
          return _ChildSummaryBuilder(
            childId: child.id,
            childName: resolvedName,
            classId: classId,
            className: classModel.name,
          );
        });
        builder.childName = resolvedName;
        builder.classId = classId;
        builder.className = classModel.name;
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
          return _ChildSummaryBuilder(
            childId: childId,
            childName: resolvedName,
            classId: resolvedClassId,
            className: resolvedClassName,
          );
        });
        builder.childName = resolvedName;
        if (resolvedClassId.isNotEmpty) {
          builder.classId = resolvedClassId;
          builder.className = resolvedClassName;
        }

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

        builder.entries.add(
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
      final placeholderDate =
          _normalizeDate(targetDate ?? DateTime.now());

      for (final child in classChildren) {
        if (child.id.isEmpty) continue;
        final resolvedName =
            child.name.trim().isEmpty ? 'Student' : child.name.trim();
        final builder = summaries.putIfAbsent(child.id, () {
          return _ChildSummaryBuilder(
            childId: child.id,
            childName: resolvedName,
            classId: classId,
            className: classModel.name,
          );
        });
        builder.childName = resolvedName;
        builder.classId = classId;
        builder.className = classModel.name;

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

          final hasEntry = builder.entries.any((existing) {
            final matchesSubject = subjectId.isNotEmpty
                ? existing.subjectId == subjectId
                : (existing.subjectId.isEmpty &&
                    existing.teacherId == teacherId);
            if (!matchesSubject) {
              return false;
            }
            return _isSameDay(existing.date, placeholderDate);
          });

          if (!hasEntry) {
            builder.entries.add(
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

class ChildAttendanceSummary {
  ChildAttendanceSummary({
    required this.childId,
    required this.childName,
    required this.classId,
    required this.className,
    required List<ChildSubjectAttendance> subjectEntries,
  }) : subjectEntries = List<ChildSubjectAttendance>.unmodifiable(
          subjectEntries..sort((a, b) => b.date.compareTo(a.date)),
        );

  final String childId;
  final String childName;
  final String classId;
  final String className;
  final List<ChildSubjectAttendance> subjectEntries;

  int get presentCount =>
      subjectEntries.where((entry) => entry.status == AttendanceStatus.present).length;

  int get absentCount =>
      subjectEntries.where((entry) => entry.status == AttendanceStatus.absent).length;

  int get pendingCount =>
      subjectEntries.where((entry) => entry.status == null || !entry.isSubmitted).length;

  int get totalSubjects => subjectEntries.length;
}

class ChildSubjectAttendance {
  const ChildSubjectAttendance({
    required this.sessionId,
    this.subjectId = '',
    this.teacherId = '',
    required this.subjectLabel,
    required this.teacherName,
    required this.date,
    required this.isSubmitted,
    this.status,
  });

  final String sessionId;
  final String subjectId;
  final String teacherId;
  final String subjectLabel;
  final String teacherName;
  final DateTime date;
  final bool isSubmitted;
  final AttendanceStatus? status;
}

class _ChildSummaryBuilder {
  _ChildSummaryBuilder({
    required this.childId,
    required this.childName,
    required this.classId,
    required this.className,
  });

  final String childId;
  String childName;
  String classId;
  String className;
  final List<ChildSubjectAttendance> entries = <ChildSubjectAttendance>[];

  ChildAttendanceSummary build() {
    return ChildAttendanceSummary(
      childId: childId,
      childName: childName,
      classId: classId,
      className: className,
      subjectEntries: List<ChildSubjectAttendance>.from(entries),
    );
  }
}
