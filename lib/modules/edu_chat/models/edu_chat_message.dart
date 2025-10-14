import 'package:cloud_firestore/cloud_firestore.dart';

class EduChatMessage {
  const EduChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.model,
    this.tokens,
    this.refused,
  });

  final String id;
  final String role;
  final String content;
  final DateTime? createdAt;
  final String? model;
  final int? tokens;
  final bool? refused;

  factory EduChatMessage.fromSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    DateTime? createdAt;
    final timestamp = data['createdAt'];
    if (timestamp is Timestamp) {
      createdAt = timestamp.toDate();
    } else if (timestamp is DateTime) {
      createdAt = timestamp;
    }

    return EduChatMessage(
      id: snapshot.id,
      role: (data['role'] as String?) ?? 'system',
      content: (data['content'] as String?) ?? '',
      createdAt: createdAt,
      model: data['model'] as String?,
      tokens: _parseTokens(data['tokens']),
      refused: data['refused'] as bool?,
    );
  }

  static int? _parseTokens(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.round();
    }
    return int.tryParse(value.toString());
  }
}
