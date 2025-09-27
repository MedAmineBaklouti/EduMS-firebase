import 'package:intl/intl.dart';

class ConversationModel {
  ConversationModel({
    required this.id,
    required this.title,
    required this.lastMessagePreview,
    required this.updatedAt,
    required this.participants,
    this.unreadCount = 0,
  });

  final String id;
  final String title;
  final String lastMessagePreview;
  final DateTime updatedAt;
  final List<ConversationParticipant> participants;
  final int unreadCount;

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    final participantsJson = json['participants'];
    return ConversationModel(
      id: (json['id'] ?? json['conversationId'] ?? '') as String,
      title: (json['title'] ?? json['name'] ?? 'Conversation') as String,
      lastMessagePreview: (json['lastMessagePreview'] ??
              json['lastMessage'] ??
              json['preview'] ??
              '')
          as String,
      updatedAt: _parseDateTime(json['updatedAt'] ?? json['updated_at']),
      participants: participantsJson is List
          ? participantsJson
              .whereType<Map<String, dynamic>>()
              .map(ConversationParticipant.fromJson)
              .toList()
          : <ConversationParticipant>[],
      unreadCount: (json['unreadCount'] ?? json['unread_count'] ?? 0) as int,
    );
  }

  ConversationModel copyWith({
    String? id,
    String? title,
    String? lastMessagePreview,
    DateTime? updatedAt,
    List<ConversationParticipant>? participants,
    int? unreadCount,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      updatedAt: updatedAt ?? this.updatedAt,
      participants: participants ?? this.participants,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  String formattedTimestamp() {
    final formatter = DateFormat('MMM d, h:mm a');
    return formatter.format(updatedAt.toLocal());
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) {
      return DateTime.now().toUtc();
    }
    if (value is DateTime) {
      return value.toUtc();
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
    }
    if (value is String) {
      return DateTime.tryParse(value)?.toUtc() ?? DateTime.now().toUtc();
    }
    return DateTime.now().toUtc();
  }
}

class ConversationParticipant {
  ConversationParticipant({
    required this.id,
    required this.name,
    required this.role,
  });

  final String id;
  final String name;
  final String role;

  factory ConversationParticipant.fromJson(Map<String, dynamic> json) {
    return ConversationParticipant(
      id: (json['id'] ?? json['userId'] ?? '') as String,
      name: (json['name'] ?? json['displayName'] ?? json['email'] ?? 'User')
          as String,
      role: (json['role'] ?? 'user') as String,
    );
  }
}
