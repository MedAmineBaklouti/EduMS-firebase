import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherModel {
  final String id;
  final String name;
  final String email;
  final String subjectId;

  TeacherModel({
    required this.id,
    required this.name,
    required this.email,
    required this.subjectId,
  });

  factory TeacherModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TeacherModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      subjectId: data['subjectId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'subjectId': subjectId,
    };
  }
}
