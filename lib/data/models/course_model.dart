import 'package:cloud_firestore/cloud_firestore.dart';

class CourseModel {
  final String id;
  final String title;
  final String description;
  final String content;
  final String subjectId;
  final String subjectName;
  final String teacherId;
  final String teacherName;
  final List<String> classIds;
  final List<String> classNames;
  final DateTime createdAt;

  CourseModel({
    required this.id,
    required this.title,
    required this.description,
    required this.content,
    required this.subjectId,
    required this.subjectName,
    required this.teacherId,
    required this.teacherName,
    required this.classIds,
    required this.classNames,
    required this.createdAt,
  });

  factory CourseModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CourseModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      content: data['content'] ?? '',
      subjectId: data['subjectId'] ?? '',
      subjectName: data['subjectName'] ?? '',
      teacherId: data['teacherId'] ?? '',
      teacherName: data['teacherName'] ?? '',
      classIds: List<String>.from(data['classIds'] ?? const []),
      classNames: List<String>.from(data['classNames'] ?? const []),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'content': content,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'classIds': classIds,
      'classNames': classNames,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
