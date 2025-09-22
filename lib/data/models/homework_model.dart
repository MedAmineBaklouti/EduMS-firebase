import 'package:cloud_firestore/cloud_firestore.dart';

class HomeworkModel {
  final String id;
  final String title;
  final String description;
  final String classId;
  final String className;
  final String teacherId;
  final String teacherName;
  final DateTime assignedDate;
  final DateTime dueDate;
  final Map<String, bool> completionByChildId;

  const HomeworkModel({
    required this.id,
    required this.title,
    required this.description,
    required this.classId,
    required this.className,
    required this.teacherId,
    required this.teacherName,
    required this.assignedDate,
    required this.dueDate,
    required this.completionByChildId,
  });

  factory HomeworkModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    return HomeworkModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      classId: data['classId'] as String? ?? '',
      className: data['className'] as String? ?? '',
      teacherId: data['teacherId'] as String? ?? '',
      teacherName: data['teacherName'] as String? ?? '',
      assignedDate:
          (data['assignedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dueDate: (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completionByChildId: Map<String, bool>.from(
        (data['completionByChildId'] as Map<String, dynamic>?) ??
            <String, dynamic>{},
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'title': title,
      'description': description,
      'classId': classId,
      'className': className,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'assignedDate': Timestamp.fromDate(assignedDate),
      'dueDate': Timestamp.fromDate(dueDate),
      'completionByChildId': completionByChildId,
    };
  }

  bool isCompletedForChild(String childId) {
    return completionByChildId[childId] ?? false;
  }

  bool isLockedForParent(DateTime now) {
    return now.isAfter(dueDate);
  }

  HomeworkModel copyWith({
    String? id,
    String? title,
    String? description,
    String? classId,
    String? className,
    String? teacherId,
    String? teacherName,
    DateTime? assignedDate,
    DateTime? dueDate,
    Map<String, bool>? completionByChildId,
  }) {
    return HomeworkModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      assignedDate: assignedDate ?? this.assignedDate,
      dueDate: dueDate ?? this.dueDate,
      completionByChildId:
          completionByChildId ?? Map<String, bool>.from(this.completionByChildId),
    );
  }
}
