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

  AnnouncementModel copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? audience,
    DateTime? createdAt,
  }) {
    return AnnouncementModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      audience: audience ?? List<String>.from(this.audience),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap({bool includeId = false, bool serverTimestamp = false}) {
    final map = <String, dynamic>{
      'title': title,
      'description': description,
      'audience': audience,
      'createdAt': serverTimestamp
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt),
    };
    if (includeId) {
      map['id'] = id;
    }
    return map;
  }
}
