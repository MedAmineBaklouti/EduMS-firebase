import 'package:cloud_firestore/cloud_firestore.dart';

class EduChatMessage {
  EduChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.model,
    this.tokens,
  });

  final String id;
  final String role;
  final String content;
  final DateTime? createdAt;
  final String? model;
  final int? tokens;

  bool get isUser => role == 'user';

  bool get isModel => role == 'model';

  bool get isSystem => role == 'system';

  DateTime get createdAtOrNow => createdAt ?? DateTime.now();

  EduChatMessage copyWith({
    String? role,
    String? content,
    DateTime? createdAt,
    String? model,
    int? tokens,
  }) {
    return EduChatMessage(
      id: id,
      role: role ?? this.role,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      model: model ?? this.model,
      tokens: tokens ?? this.tokens,
    );
  }

  static EduChatMessage fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final createdAt = data['createdAt'];
    DateTime? createdAtDate;
    if (createdAt is Timestamp) {
      createdAtDate = createdAt.toDate();
    } else if (createdAt is DateTime) {
      createdAtDate = createdAt;
    }

    return EduChatMessage(
      id: doc.id,
      role: (data['role'] as String?)?.toLowerCase() ?? 'system',
      content: (data['content'] as String?) ?? '',
      createdAt: createdAtDate,
      model: data['model'] as String?,
      tokens: (data['tokens'] is int) ? data['tokens'] as int : null,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'role': role,
      'content': content,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      if (model != null) 'model': model,
      if (tokens != null) 'tokens': tokens,
    };
  }
}
