import 'package:cloud_firestore/cloud_firestore.dart';

class SchoolClassModel {
  final String id;
  final String name;
  final String teacherId;

  SchoolClassModel({
    required this.id,
    required this.name,
    required this.teacherId,
  });

  factory SchoolClassModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SchoolClassModel(
      id: doc.id,
      name: data['name'] ?? '',
      teacherId: data['teacherId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'teacherId': teacherId,
    };
  }
}
