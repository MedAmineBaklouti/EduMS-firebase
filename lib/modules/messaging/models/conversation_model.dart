import 'package:intl/intl.dart';

class ConversationModel {
  static const Object _unset = Object();

  ConversationModel({
    required this.id,
    required this.title,
    required this.lastMessagePreview,
    required this.updatedAt,
    required this.participants,
    this.unreadCount = 0,
    this.deletedAt,
  });

  final String id;
  final String title;
  final String lastMessagePreview;
  final DateTime updatedAt;
  final List<ConversationParticipant> participants;
  final int unreadCount;
  final DateTime? deletedAt;

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
      deletedAt: _parseOptionalDateTime(json['deletedAt'] ?? json['deleted_at']),
    );
  }

  ConversationModel copyWith({
    String? id,
    String? title,
    String? lastMessagePreview,
    DateTime? updatedAt,
    List<ConversationParticipant>? participants,
    int? unreadCount,
    Object? deletedAt = _unset,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      updatedAt: updatedAt ?? this.updatedAt,
      participants: participants ?? this.participants,
      unreadCount: unreadCount ?? this.unreadCount,
      deletedAt:
          identical(deletedAt, _unset) ? this.deletedAt : deletedAt as DateTime?,
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

  static DateTime? _parseOptionalDateTime(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value.toUtc();
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
    }
    if (value is String) {
      return DateTime.tryParse(value)?.toUtc();
    }
    return null;
  }
}

class ConversationParticipant {
  ConversationParticipant({
    required this.id,
    required this.name,
    required this.role,
    String? userId,
  }) : userId = userId ?? id;

  final String id;
  final String name;
  final String role;
  final String userId;

  factory ConversationParticipant.fromJson(Map<String, dynamic> json) {
    final rawId = (json['id'] ?? json['userId'] ?? '').toString();
    final resolvedUserId =
        (json['userId'] ?? json['uid'] ?? rawId).toString();
    return ConversationParticipant(
      id: rawId,
      name: (json['name'] ?? json['displayName'] ?? json['email'] ?? 'User')
          as String,
      role: (json['role'] ?? 'user') as String,
      userId: resolvedUserId,
    );
  }
}
