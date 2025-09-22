import 'package:cloud_firestore/cloud_firestore.dart';

enum AttendanceStatus { present, absent }

extension AttendanceStatusParser on AttendanceStatus {
  static AttendanceStatus fromString(String? value) {
    return AttendanceStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => AttendanceStatus.present,
    );
  }

  String get label {
    switch (this) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
    }
  }
}

class ChildAttendanceEntry {
  final String childId;
  final String childName;
  final AttendanceStatus status;

  const ChildAttendanceEntry({
    required this.childId,
    required this.childName,
    required this.status,
  });

  factory ChildAttendanceEntry.fromMap(Map<String, dynamic> data) {
    return ChildAttendanceEntry(
      childId: data['childId'] as String? ?? '',
      childName: data['childName'] as String? ?? '',
      status: AttendanceStatusParser.fromString(data['status'] as String?),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'childId': childId,
      'childName': childName,
      'status': status.name,
    };
  }

  ChildAttendanceEntry copyWith({
    String? childId,
    String? childName,
    AttendanceStatus? status,
  }) {
    return ChildAttendanceEntry(
      childId: childId ?? this.childId,
      childName: childName ?? this.childName,
      status: status ?? this.status,
    );
  }
}

class AttendanceSessionModel {
  final String id;
  final String classId;
  final String className;
  final String teacherId;
  final String teacherName;
  final DateTime date;
  final List<ChildAttendanceEntry> records;
  final DateTime? submittedAt;

  const AttendanceSessionModel({
    required this.id,
    required this.classId,
    required this.className,
    required this.teacherId,
    required this.teacherName,
    required this.date,
    required this.records,
    required this.submittedAt,
  });

  factory AttendanceSessionModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    final records = (data['records'] as List<dynamic>? ?? <dynamic>[])
        .map((entry) =>
            ChildAttendanceEntry.fromMap(entry as Map<String, dynamic>))
        .toList();
    return AttendanceSessionModel(
      id: doc.id,
      classId: data['classId'] as String? ?? '',
      className: data['className'] as String? ?? '',
      teacherId: data['teacherId'] as String? ?? '',
      teacherName: data['teacherName'] as String? ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      records: records,
      submittedAt: (data['submittedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'classId': classId,
      'className': className,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'date': Timestamp.fromDate(date),
      'records': records.map((entry) => entry.toMap()).toList(),
      'submittedAt':
          submittedAt == null ? null : Timestamp.fromDate(submittedAt!),
    };
  }

  bool get isSubmitted => submittedAt != null;

  AttendanceSessionModel copyWith({
    String? id,
    String? classId,
    String? className,
    String? teacherId,
    String? teacherName,
    DateTime? date,
    List<ChildAttendanceEntry>? records,
    DateTime? submittedAt,
  }) {
    return AttendanceSessionModel(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      date: date ?? this.date,
      records: records ?? List<ChildAttendanceEntry>.from(this.records),
      submittedAt: submittedAt ?? this.submittedAt,
    );
  }
}

class TeacherAttendanceRecord {
  final String id;
  final String teacherId;
  final String teacherName;
  final DateTime date;
  final AttendanceStatus status;
  final String note;

  const TeacherAttendanceRecord({
    required this.id,
    required this.teacherId,
    required this.teacherName,
    required this.date,
    required this.status,
    required this.note,
  });

  factory TeacherAttendanceRecord.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    return TeacherAttendanceRecord(
      id: doc.id,
      teacherId: data['teacherId'] as String? ?? '',
      teacherName: data['teacherName'] as String? ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: AttendanceStatusParser.fromString(data['status'] as String?),
      note: data['note'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'teacherId': teacherId,
      'teacherName': teacherName,
      'date': Timestamp.fromDate(date),
      'status': status.name,
      'note': note,
    };
  }

  TeacherAttendanceRecord copyWith({
    String? id,
    String? teacherId,
    String? teacherName,
    DateTime? date,
    AttendanceStatus? status,
    String? note,
  }) {
    return TeacherAttendanceRecord(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      date: date ?? this.date,
      status: status ?? this.status,
      note: note ?? this.note,
    );
  }
}
