import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:get/get.dart';

import '../models/edu_chat_message.dart';

class EduChatResponse {
  EduChatResponse({
    required this.text,
    required this.persisted,
    this.refused = false,
    this.throttled = false,
    this.tokens,
    this.model,
  });

  factory EduChatResponse.fromMap(Map<String, dynamic> map) {
    return EduChatResponse(
      text: (map['text'] as String?) ?? '',
      refused: map['refused'] as bool? ?? false,
      throttled: map['throttled'] as bool? ?? false,
      tokens: map['tokens'] is int ? map['tokens'] as int : null,
      model: map['model'] as String?,
      persisted: map['persisted'] as bool? ?? false,
    );
  }

  final String text;
  final bool refused;
  final bool throttled;
  final int? tokens;
  final String? model;
  final bool persisted;
}

class EduChatService {
  EduChatService()
      : _firestore = FirebaseFirestore.instance,
        _functions = FirebaseFunctions.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> _chatCollection(String uid) {
    return _firestore.collection('users').doc(uid).collection('eduChats');
  }

  CollectionReference<Map<String, dynamic>> _messageCollection(
    String uid,
    String chatId,
  ) {
    return _chatCollection(uid).doc(chatId).collection('messages');
  }

  Future<String> ensureChatThread(String uid) async {
    final chats = await _chatCollection(uid)
        .orderBy('createdAt', descending: false)
        .limit(1)
        .get();

    if (chats.docs.isNotEmpty) {
      final doc = chats.docs.first;
      final data = doc.data();
      if (!data.containsKey('title') || (data['title'] as String?)?.isEmpty != false) {
        await doc.reference.set(<String, dynamic>{
          'title': 'Educational Assistant',
        }, SetOptions(merge: true));
      }
      return doc.id;
    }

    final chatRef = _chatCollection(uid).doc();
    final now = Timestamp.now();
    await chatRef.set({
      'createdAt': now,
      'lastMessageAt': now,
      'title': 'Educational Assistant',
    });
    return chatRef.id;
  }

  Stream<List<EduChatMessage>> watchMessages({
    required String uid,
    required String chatId,
  }) {
    return _messageCollection(uid, chatId)
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots()
        .map(
      (snapshot) => snapshot.docs
          .map(EduChatMessage.fromDoc)
          .toList(growable: false),
    );
  }

  Future<EduChatResponse> sendMessage({
    required String uid,
    required String chatId,
    required String message,
  }) async {
    try {
      final callable = _functions.httpsCallable('generateEducationalReply');
      final result = await callable.call(<String, dynamic>{
        'chatId': chatId,
        'message': message,
      });
      final raw = result.data;
      final map = raw is Map ? Map<String, dynamic>.from(raw as Map) : <String, dynamic>{};
      return EduChatResponse.fromMap(map);
    } on FirebaseFunctionsException catch (error) {
      Get.log('EduChatService.sendMessage FirebaseFunctionsException: $error');
      rethrow;
    }
  }

  Future<void> addSystemMessage({
    required String uid,
    required String chatId,
    required String content,
    String role = 'model',
  }) async {
    final now = Timestamp.now();
    final batch = _firestore.batch();
    final messageRef = _messageCollection(uid, chatId).doc();
    batch.set(messageRef, <String, dynamic>{
      'role': role,
      'content': content,
      'createdAt': now,
    });
    final chatRef = _chatCollection(uid).doc(chatId);
    batch.set(
      chatRef,
      <String, dynamic>{
        'lastMessageAt': now,
      },
      SetOptions(merge: true),
    );
    await batch.commit();
  }
}
