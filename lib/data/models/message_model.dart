import 'package:firebase_messaging/firebase_messaging.dart';

/// Represents a single message in a conversation.
class MessageModel {
  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.sentAt,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime sentAt;

  /// Builds a [MessageModel] from a JSON map returned by the API.
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: (json['id'] ?? json['messageId'] ?? '') as String,
      conversationId:
          (json['conversationId'] ?? json['conversation_id'] ?? 'general')
              as String,
      senderId: (json['senderId'] ?? json['sender_id'] ?? '') as String,
      senderName: (json['senderName'] ?? json['sender_name'] ?? 'User') as String,
      content: (json['content'] ?? json['text'] ?? '') as String,
      sentAt: _parseDateTime(json['sentAt'] ?? json['sent_at']),
    );
  }

  /// Builds a [MessageModel] from an incoming push notification.
  factory MessageModel.fromRemoteMessage(RemoteMessage message) {
    final data = message.data;
    return MessageModel(
      id: (data['id'] ?? data['messageId'] ?? message.messageId ?? '') as String,
      conversationId:
          (data['conversationId'] ?? data['conversation_id'] ?? 'general')
              as String,
      senderId: (data['senderId'] ?? data['sender_id'] ?? '') as String,
      senderName: (data['senderName'] ?? data['sender_name'] ??
              message.notification?.title ??
              'User')
          as String,
      content: (data['content'] ?? data['text'] ?? message.notification?.body ??
              '')
          as String,
      sentAt: _parseDateTime(data['sentAt'] ?? data['sent_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'sentAt': sentAt.toUtc().toIso8601String(),
    };
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
