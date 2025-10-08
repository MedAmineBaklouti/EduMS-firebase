import 'package:intl/intl.dart';

import '../../../data/models/attendance_record_model.dart';

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
    this.submittedAt,
  });

  final String sessionId;
  final String subjectId;
  final String teacherId;
  final String subjectLabel;
  final String teacherName;
  final DateTime date;
  final bool isSubmitted;
  final AttendanceStatus? status;
  final DateTime? submittedAt;
}

class ChildAttendanceSummary {
  ChildAttendanceSummary({
    required this.childId,
    required this.childName,
    required this.classId,
    required this.className,
    required this.displayDate,
    required List<ChildSubjectAttendance> subjectEntries,
  }) : subjectEntries = List<ChildSubjectAttendance>.unmodifiable(
          subjectEntries..sort((a, b) => b.date.compareTo(a.date)),
        );

  final String childId;
  final String childName;
  final String classId;
  final String className;
  final DateTime displayDate;
  final List<ChildSubjectAttendance> subjectEntries;

  Iterable<ChildSubjectAttendance> get _entriesForDisplay {
    final normalizedDisplayDate =
        DateTime(displayDate.year, displayDate.month, displayDate.day);
    final filtered = subjectEntries.where(
      (entry) => entry.date.year == normalizedDisplayDate.year &&
          entry.date.month == normalizedDisplayDate.month &&
          entry.date.day == normalizedDisplayDate.day,
    );
    return filtered.isNotEmpty ? filtered : subjectEntries;
  }

  int get presentCount => _entriesForDisplay
      .where((entry) => entry.status == AttendanceStatus.present)
      .length;

  int get absentCount => _entriesForDisplay
      .where((entry) => entry.status == AttendanceStatus.absent)
      .length;

  int get pendingCount => _entriesForDisplay
      .where((entry) =>
          entry.status == null ||
          entry.status == AttendanceStatus.pending ||
          !entry.isSubmitted)
      .length;

  int get totalSubjects => _entriesForDisplay.length;
}

class ChildAttendanceSummaryBuilder {
  ChildAttendanceSummaryBuilder({
    required this.childId,
    required this.childName,
    required this.classId,
    required this.className,
    required this.displayDate,
  });

  final String childId;
  String childName;
  String classId;
  String className;
  DateTime displayDate;

  final List<ChildSubjectAttendance> _entries = <ChildSubjectAttendance>[];
  final Map<String, int> _entryIndexByKey = <String, int>{};

  void addOrUpdateEntry(ChildSubjectAttendance entry) {
    final key = _entryKey(entry);
    final existingIndex = _entryIndexByKey[key];
    if (existingIndex == null) {
      _entryIndexByKey[key] = _entries.length;
      _entries.add(entry);
      return;
    }

    final existing = _entries[existingIndex];
    if (_shouldReplace(existing, entry)) {
      _entries[existingIndex] = entry;
    }
  }

  ChildAttendanceSummary build() {
    return ChildAttendanceSummary(
      childId: childId,
      childName: childName,
      classId: classId,
      className: className,
      displayDate: displayDate,
      subjectEntries: List<ChildSubjectAttendance>.from(_entries),
    );
  }

  bool _shouldReplace(
    ChildSubjectAttendance existing,
    ChildSubjectAttendance updated,
  ) {
    if (!existing.isSubmitted && updated.isSubmitted) {
      return true;
    }

    if (existing.isSubmitted == updated.isSubmitted) {
      if (existing.status == null && updated.status != null) {
        return true;
      }
      final existingTimestamp = existing.submittedAt ?? existing.date;
      final updatedTimestamp = updated.submittedAt ?? updated.date;
      if (updatedTimestamp.isAfter(existingTimestamp)) {
        return true;
      }
    }

    return false;
  }

  String _entryKey(ChildSubjectAttendance entry) {
    final normalizedDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
    final dateKey = DateFormat('yyyyMMdd').format(normalizedDate);
    final subjectKey = entry.subjectId.isNotEmpty
        ? entry.subjectId
        : (entry.teacherId.isNotEmpty
            ? entry.teacherId
            : entry.subjectLabel.toLowerCase());
    return '$subjectKey-$dateKey';
  }
}
