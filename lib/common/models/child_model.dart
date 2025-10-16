import 'package:cloud_firestore/cloud_firestore.dart';

class ChildModel {
  final String id;
  final String name;
  final String parentId;
  final String classId;

  ChildModel({
    required this.id,
    required this.name,
    required this.parentId,
    required this.classId,
  });

  factory ChildModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChildModel(
      id: doc.id,
      name: data['name'] ?? '',
      parentId: data['parentId'] ?? '',
      classId: data['classId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'parentId': parentId,
      'classId': classId,
    };
  }
}
