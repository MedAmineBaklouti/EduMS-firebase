import 'package:cloud_firestore/cloud_firestore.dart';

class SchoolClassModel {
  final String id;
  final String name;
  final Map<String, String> teacherSubjects; // subjectId -> teacherId
  final List<String> childIds;

  SchoolClassModel({
    required this.id,
    required this.name,
    this.teacherSubjects = const {},
    this.childIds = const [],
  });

  factory SchoolClassModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SchoolClassModel(
      id: doc.id,
      name: data['name'] ?? '',
      teacherSubjects:
          Map<String, String>.from(data['teacherSubjects'] ?? {}),
      childIds: List<String>.from(data['childIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'teacherSubjects': teacherSubjects,
      'childIds': childIds,
    };
  }
}
