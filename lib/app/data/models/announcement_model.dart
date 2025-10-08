import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementModel {
  final String id;
  final String title;
  final String description;
  final List<String> audience;
  final DateTime createdAt;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.audience,
    required this.createdAt,
  });

  factory AnnouncementModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AnnouncementModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      audience: List<String>.from(data['audience'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'audience': audience,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
