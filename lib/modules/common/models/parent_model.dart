import 'package:cloud_firestore/cloud_firestore.dart';

class ParentModel {
  final String id;
  final String name;
  final String email;
  final String phone;

  ParentModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
  });

  factory ParentModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ParentModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
    };
  }
}
