import 'package:cloud_firestore/cloud_firestore.dart';

class SchoolClassModel {
  final String id;
  final String name;
  final String teacherId;
  final List<String> childIds;

  SchoolClassModel({
    required this.id,
    required this.name,
    required this.teacherId,
    this.childIds = const [],
  });

  factory SchoolClassModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SchoolClassModel(
      id: doc.id,
      name: data['name'] ?? '',
      teacherId: data['teacherId'] ?? '',
      childIds: List<String>.from(data['childIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'teacherId': teacherId,
      'childIds': childIds,
    };
  }
}
