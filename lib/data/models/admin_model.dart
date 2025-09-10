import 'package:cloud_firestore/cloud_firestore.dart';

class Admin {
  final String uid;
  final String email;
  final DateTime createdAt;

  Admin({
    required this.uid,
    required this.email,
    required this.createdAt,
  });

  factory Admin.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Admin(
      uid: doc.id,
      email: data['email'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'createdAt': createdAt,
    };
  }
}