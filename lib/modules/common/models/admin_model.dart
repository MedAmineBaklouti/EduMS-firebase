import 'package:cloud_firestore/cloud_firestore.dart';

class AdminModel {
  final String id;
  final String name;
  final String email;
  final DateTime createdAt;

  const AdminModel({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
  });

  factory AdminModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    return AdminModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}