import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationModel {
  final String id;
  final List<String> participants;
  final Map<String, dynamic> participantDetails;
  final String? lastMessage;
  final String? lastSenderId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> unreadBy;
  final String participantKey;

  const ConversationModel({
    required this.id,
    required this.participants,
    required this.participantDetails,
    required this.lastMessage,
    required this.lastSenderId,
    required this.createdAt,
    required this.updatedAt,
    required this.unreadBy,
    required this.participantKey,
  });

  factory ConversationModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return ConversationModel(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? const <String>[]),
      participantDetails:
          Map<String, dynamic>.from(data['participantDetails'] ?? const <String, dynamic>{}),
      lastMessage: data['lastMessage'] as String?,
      lastSenderId: data['lastSenderId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadBy: List<String>.from(data['unreadBy'] ?? const <String>[]),
      participantKey: data['participantKey'] as String? ?? '',
    );
  }

  ConversationModel copyWith({
    String? lastMessage,
    String? lastSenderId,
    DateTime? updatedAt,
    List<String>? unreadBy,
    Map<String, dynamic>? participantDetails,
  }) {
    return ConversationModel(
      id: id,
      participants: participants,
      participantDetails: participantDetails ?? this.participantDetails,
      lastMessage: lastMessage ?? this.lastMessage,
      lastSenderId: lastSenderId ?? this.lastSenderId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      unreadBy: unreadBy ?? this.unreadBy,
      participantKey: participantKey,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'participantDetails': participantDetails,
      'lastMessage': lastMessage,
      'lastSenderId': lastSenderId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'unreadBy': unreadBy,
      'participantKey': participantKey,
    };
  }
}
