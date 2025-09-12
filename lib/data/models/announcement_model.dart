import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementModel {
  final String id;
  final String title;
  final String body;
  final String audience; // parents, teachers, both
  final DateTime createdAt;
  final DateTime expireAt;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.body,
    required this.audience,
    required this.createdAt,
    required this.expireAt,
  });

  factory AnnouncementModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AnnouncementModel(
      id: doc.id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      audience: data['audience'] ?? 'both',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expireAt: (data['expireAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'audience': audience,
      'createdAt': Timestamp.fromDate(createdAt),
      'expireAt': Timestamp.fromDate(expireAt),
    };
  }
}
