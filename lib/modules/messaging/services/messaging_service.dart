import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../../data/models/conversation_model.dart';
import '../../../data/models/message_model.dart';
import 'push_notification_service.dart';

class MessagingService extends GetxService {
  MessagingService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final PushNotificationService _pushService = PushNotificationService();

  CollectionReference<Map<String, dynamic>> get _conversationCollection =>
      _firestore.collection('conversations');

  String _participantKey(List<String> participantIds) {
    final sorted = List<String>.from(participantIds)..sort();
    return sorted.join('_');
  }

  Future<void> saveDeviceToken(String userId, String token) async {
    if (userId.isEmpty || token.isEmpty) {
      return;
    }

    final docRef = _firestore.collection('userTokens').doc(userId);
    await docRef.set(
      <String, dynamic>{
        'tokens': FieldValue.arrayUnion(<String>[token]),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> removeDeviceToken(String userId, String token) async {
    if (userId.isEmpty || token.isEmpty) {
      return;
    }
    final docRef = _firestore.collection('userTokens').doc(userId);
    await docRef.set(
      <String, dynamic>{
        'tokens': FieldValue.arrayRemove(<String>[token]),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Stream<List<ConversationModel>> streamConversations(String userId) {
    return _conversationCollection
        .where('participants', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(ConversationModel.fromDoc).toList(growable: false));
  }

  Stream<List<MessageModel>> streamMessages(String conversationId) {
    return _conversationCollection
        .doc(conversationId)
        .collection('messages')
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromDoc(conversationId, doc))
            .toList(growable: false));
  }

  Future<ConversationModel> getOrCreateConversation({
    required String currentUserId,
    required Map<String, dynamic> currentUserDetails,
    required String otherUserId,
    required Map<String, dynamic> otherUserDetails,
  }) async {
    final participants = <String>[currentUserId, otherUserId];
    final key = _participantKey(participants);

    final existingSnapshot = await _conversationCollection
        .where('participantKey', isEqualTo: key)
        .limit(1)
        .get();
    if (existingSnapshot.docs.isNotEmpty) {
      return ConversationModel.fromDoc(existingSnapshot.docs.first);
    }

    final now = DateTime.now();
    final docRef = _conversationCollection.doc();
    final participantDetails = <String, dynamic>{
      currentUserId: currentUserDetails,
      otherUserId: otherUserDetails,
    };

    await docRef.set(<String, dynamic>{
      'participants': participants,
      'participantDetails': participantDetails,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
      'lastMessage': null,
      'lastSenderId': null,
      'unreadBy': <String>[],
      'participantKey': key,
    });

    final createdDoc = await docRef.get();
    return ConversationModel.fromDoc(createdDoc);
  }

  Future<void> sendMessage({
    required ConversationModel conversation,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String text,
    Map<String, dynamic>? participantDetails,
  }) async {
    final now = DateTime.now();
    final docRef = _conversationCollection.doc(conversation.id);
    final participants = conversation.participants;

    await docRef.collection('messages').add(<String, dynamic>{
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'text': text,
      'sentAt': Timestamp.fromDate(now),
    });

    final unreadFor = participants.where((id) => id != senderId).toList();

    await docRef.update(<String, dynamic>{
      'lastMessage': text,
      'lastSenderId': senderId,
      'updatedAt': Timestamp.fromDate(now),
      'unreadBy': unreadFor,
      if (participantDetails != null) 'participantDetails': participantDetails,
    });

    final tokens = await _collectRecipientTokens(unreadFor);
    if (tokens.isEmpty) {
      return;
    }

    try {
      await _pushService.sendMessageNotification(
        tokens: tokens,
        title: senderName,
        body: text,
        data: <String, dynamic>{
          'conversationId': conversation.id,
          'senderId': senderId,
        },
      );
    } catch (error) {
      // ignore: avoid_print
      print('FCM send failed: $error');
    }
  }

  Future<void> markConversationRead(
    String conversationId,
    String userId,
  ) async {
    await _conversationCollection.doc(conversationId).update(<String, dynamic>{
      'unreadBy': FieldValue.arrayRemove(<String>[userId]),
    });
  }

  Future<List<String>> _collectRecipientTokens(List<String> userIds) async {
    if (userIds.isEmpty) {
      return <String>[];
    }

    final futures = userIds
        .map((id) => _firestore.collection('userTokens').doc(id).get())
        .toList();
    final docs = await Future.wait(futures);
    final tokens = <String>[];
    for (final doc in docs) {
      final data = doc.data();
      if (data == null) {
        continue;
      }
      tokens.addAll(List<String>.from(data['tokens'] ?? const <String>[]));
    }
    return tokens;
  }
}
