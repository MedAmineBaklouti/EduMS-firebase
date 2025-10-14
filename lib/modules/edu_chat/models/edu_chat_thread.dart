import 'package:cloud_firestore/cloud_firestore.dart';

class EduChatThread {
  const EduChatThread({
    required this.id,
    this.title,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? title;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory EduChatThread.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};

    DateTime? parseTimestamp(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      }
      if (value is DateTime) {
        return value;
      }
      return null;
    }

    return EduChatThread(
      id: snapshot.id,
      title: (data['title'] as String?)?.trim(),
      createdAt: parseTimestamp(data['createdAt']),
      updatedAt: parseTimestamp(data['updatedAt']),
    );
  }
}
