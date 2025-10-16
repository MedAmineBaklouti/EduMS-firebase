import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart' hide Response;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/config/app_config.dart';
import 'package:edums/modules/auth/service/auth_service.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../models/messaging_contact.dart';
import 'messaging_notification_channel.dart';
import 'messaging_push_handler.dart';

class _DeviceTokenSaveResult {
  _DeviceTokenSaveResult({this.previousDeviceToken});

  final String? previousDeviceToken;
}

class MessagingService extends GetxService {
  MessagingService({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
    FirebaseFirestore? firestore,
    AuthService? authService,
    Dio? pushClient,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _localNotifications =
            localNotifications ?? FlutterLocalNotificationsPlugin(),
        _firestore = firestore ?? FirebaseFirestore.instance,
        _authService = authService ?? Get.find<AuthService>(),
        _pushClient = pushClient ?? _createPushClient();

  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;
  final FirebaseFirestore _firestore;
  final AuthService _authService;
  final Dio? _pushClient;

  final StreamController<MessageModel> _messageStreamController =
      StreamController<MessageModel>.broadcast();

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<RemoteMessage>? _messageOpenedAppSubscription;
  String? _lastKnownToken;
  String? _pendingToken;
  String? _lastKnownUserId;
  bool _pushPermissionGranted = false;
  SharedPreferences? _preferences;
  String? _deviceId;
  bool _deviceTokenRestored = false;

  static const String _messagingRoute = '/messaging';
  static const String _tokenCollection = 'userPushTokens';
  static const String _conversationsCollection = 'conversations';
  static const String _messagesCollection = 'messages';
  static const String _classesCollection = 'classes';
  static const String _subjectsCollection = 'subjects';
  static const String _parentsCollection = 'parents';
  static const String _teachersCollection = 'teachers';
  static const String _adminsCollection = 'admins';
  static const String _childrenCollection = 'children';
  static const int _firestoreBatchLimit = 10;
  static const String _deviceIdPrefsKey = 'messaging_device_id';

  static Dio? _createPushClient() {
    final serverKey = AppConfig.fcmServerKey.trim();
    if (serverKey.isEmpty) {
      debugPrint('FCM server key missing; push notifications will be disabled.');
      return null;
    }

    final authorizationHeader = _resolveFcmAuthorizationHeader(serverKey);
    if (authorizationHeader == null) {
      debugPrint(
        'FCM server key is not in a recognised format; push notifications will be disabled.',
      );
      return null;
    }

    return Dio(
      BaseOptions(
        baseUrl: 'https://fcm.googleapis.com',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: <String, dynamic>{
          'Content-Type': 'application/json',
          'Authorization': authorizationHeader,
        },
      ),
    );
  }

  static String? _resolveFcmAuthorizationHeader(String rawKey) {
    final trimmed = rawKey.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final lower = trimmed.toLowerCase();
    if (lower.startsWith('key=')) {
      return trimmed;
    }
    if (lower.startsWith('bearer ')) {
      return trimmed;
    }

    return 'key=$trimmed';
  }

  Stream<MessageModel> get messageStream => _messageStreamController.stream;

  Future<MessagingService> init() async {
    await _ensureDeviceId();
    await _setupLocalNotifications();
    await _initializePushNotifications();
    await _handleInitialMessage();
    _authSubscription?.cancel();
    _authSubscription = _authService.user.listen(_handleAuthStateChanged);
    if (_pushPermissionGranted) {
      await _ensureTokenForCurrentUser();
    }

    debugPrint('INIT: deviceId=$_deviceId pushGranted=$_pushPermissionGranted');

    return this;
  }

  Future<List<MessageModel>> fetchMessages(String conversationId) async {
    try {
      final snapshot = await _firestore
          .collection(_conversationsCollection)
          .doc(conversationId)
          .collection(_messagesCollection)
          .orderBy('sentAt')
          .get();

      final messages = snapshot.docs.map((doc) {
        final data = doc.data();
        final Map<String, dynamic> payload = <String, dynamic>{
          'id': doc.id,
          'conversationId': conversationId,
          'senderId': data['senderId'] ?? '',
          'senderName': data['senderName'] ?? '',
          'content': data['content'] ?? '',
          'sentAt': (data['sentAt'] as Timestamp?)?.toDate(),
          'readBy': data['readBy'],
        };
        return MessageModel.fromJson(payload);
      }).toList();

      messages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
      return messages;
    } on FirebaseException catch (error) {
      final message = error.message ?? error.code;
      throw Exception('Failed to load messages: $message');
    } catch (error) {
      throw Exception('Failed to load messages: $error');
    }
  }

  Future<List<ConversationModel>> fetchConversations() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      return <ConversationModel>[];
    }

    try {
      final snapshot = await _firestore
          .collection(_conversationsCollection)
          .where('participantIds', arrayContains: userId)
          .get();

      final conversations = snapshot.docs
          .map((doc) => _conversationFromData(doc.id, doc.data()))
          .toList();
      conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return conversations;
    } on FirebaseException catch (error) {
      final message = error.message ?? error.code;
      throw Exception('Failed to load conversations: $message');
    } catch (error) {
      throw Exception('Failed to load conversations: $error');
    }
  }

  Stream<List<ConversationModel>> watchConversations() {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      return Stream<List<ConversationModel>>.value(<ConversationModel>[]);
    }

    return _firestore
        .collection(_conversationsCollection)
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      final conversations = snapshot.docs
          .map((doc) => _conversationFromData(doc.id, doc.data()))
          .toList();
      conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return conversations;
    });
  }

  Future<ConversationModel?> fetchConversation(String conversationId) async {
    try {
      final doc = await _firestore
          .collection(_conversationsCollection)
          .doc(conversationId)
          .get();
      final data = doc.data();
      if (data == null) {
        return null;
      }
      return _conversationFromData(doc.id, data);
    } on FirebaseException catch (error) {
      final message = error.message ?? error.code;
      throw Exception('Failed to load conversation: $message');
    } catch (error) {
      throw Exception('Failed to load conversation: $error');
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    final conversationRef =
        _firestore.collection(_conversationsCollection).doc(conversationId);
    final messagesRef = conversationRef.collection(_messagesCollection);

    try {
      const batchSize = 500;
      while (true) {
        final snapshot = await messagesRef.limit(batchSize).get();
        if (snapshot.docs.isEmpty) {
          break;
        }
        final batch = _firestore.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      await conversationRef.delete();
    } on FirebaseException catch (error) {
      final message = error.message ?? error.code;
      throw Exception('Failed to delete conversation: $message');
    } catch (error) {
      throw Exception('Failed to delete conversation: $error');
    }
  }

  Future<MessageModel> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String content,
    List<ConversationParticipant>? participants,
  }) async {
    final now = DateTime.now().toUtc();
    final conversationRef =
        _firestore.collection(_conversationsCollection).doc(conversationId);
    final messageRef = conversationRef.collection(_messagesCollection).doc();

    try {
      await messageRef.set(<String, dynamic>{
        'conversationId': conversationId,
        'senderId': senderId,
        'senderName': senderName,
        'content': content,
        'sentAt': Timestamp.fromDate(now),
      });

      final resolvedParticipants =
          await _resolveParticipants(conversationId, participants);

      final participantIds = <String>{senderId};
      for (final participant in resolvedParticipants) {
        if (participant.userId.isNotEmpty) {
          participantIds.add(participant.userId);
        }
        if (participant.id.isNotEmpty) {
          participantIds.add(participant.id);
        }
      }

      final updateData = <String, dynamic>{
        'lastMessagePreview': content,
        'updatedAt': Timestamp.fromDate(now),
        'participantIds': FieldValue.arrayUnion(participantIds.toList()),
        'unreadBy': <String, dynamic>{
          senderId: 0,
        },
      };

      if (resolvedParticipants.isNotEmpty) {
        updateData['participants'] = resolvedParticipants
            .map((participant) => <String, dynamic>{
                  'id': participant.id,
                  'userId': participant.userId,
                  'name': participant.name,
                  'role': participant.role,
                })
            .toList();
      }

      await conversationRef.set(updateData, SetOptions(merge: true));

      final unreadFieldUpdates = <String, Object>{};
      for (final participant in resolvedParticipants) {
        final unreadKey =
            participant.userId.isNotEmpty ? participant.userId : participant.id;
        if (unreadKey.isEmpty || unreadKey == senderId) {
          continue;
        }
        unreadFieldUpdates['unreadBy.$unreadKey'] = FieldValue.increment(1);
      }

      if (unreadFieldUpdates.isNotEmpty) {
        await conversationRef.update(unreadFieldUpdates);
      }

      final message = MessageModel(
        id: messageRef.id,
        conversationId: conversationId,
        senderId: senderId,
        senderName: senderName,
        content: content,
        sentAt: now,
        readBy: <String>{senderId},
      );

      _messageStreamController.add(message);

      if (resolvedParticipants.isNotEmpty) {
        unawaited(_sendPushNotification(message, resolvedParticipants));
      }

      return message;
    } on FirebaseException catch (error) {
      final message = error.message ?? error.code;
      throw Exception('Failed to send message: $message');
    } catch (error) {
      throw Exception('Failed to send message: $error');
    }
  }

  Future<ConversationModel> ensureConversationWithContact(
    MessagingContact contact,
  ) async {
    final user = _authService.currentUser;
    if (user == null) {
      throw Exception('You must be signed in to start a conversation.');
    }

    try {
      final existingSnapshot = await _firestore
          .collection(_conversationsCollection)
          .where('participantIds', arrayContains: user.uid)
          .get();

      for (final doc in existingSnapshot.docs) {
        final data = doc.data();
        final participantIds = (data['participantIds'] as Iterable?)
                ?.whereType<String>()
                .toSet() ??
            <String>{};
        if (participantIds.contains(contact.id) ||
            (contact.userId.isNotEmpty &&
                participantIds.contains(contact.userId))) {
          return _conversationFromData(doc.id, data);
        }
      }

      final now = DateTime.now().toUtc();
      final currentUserName = _formatDisplayName(
        user.displayName,
        user.email,
        'User',
      );
      final currentRole = (_authService.currentRole ?? 'user').toLowerCase();

      final participants = <ConversationParticipant>[
        ConversationParticipant(
          id: user.uid,
          name: currentUserName,
          role: currentRole,
          userId: user.uid,
        ),
        ConversationParticipant(
          id: contact.id,
          name: contact.name,
          role: contact.role,
          userId: contact.userId,
        ),
      ];

      final docRef =
          _firestore.collection(_conversationsCollection).doc();
      final participantIds = <String>{user.uid};
      if (contact.userId.isNotEmpty) {
        participantIds.add(contact.userId);
      }
      if (contact.id.isNotEmpty) {
        participantIds.add(contact.id);
      }
      await docRef.set(<String, dynamic>{
        'title': contact.name,
        'lastMessagePreview': '',
        'participantIds': participantIds.toList(),
        'participants': participants
            .map((participant) => <String, dynamic>{
                  'id': participant.id,
                  'userId': participant.userId,
                  'name': participant.name,
                  'role': participant.role,
                })
            .toList(),
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'unreadCount': 0,
        'unreadBy': <String, dynamic>{
          user.uid: 0,
          if (contact.userId.isNotEmpty) contact.userId: 0,
        },
      });

      return ConversationModel(
        id: docRef.id,
        title: contact.name,
        lastMessagePreview: '',
        updatedAt: now,
        participants: participants,
        unreadCount: 0,
      );
    } on FirebaseException catch (error) {
      final message = error.message ?? error.code;
      throw Exception('Failed to start conversation: $message');
    } catch (error) {
      throw Exception('Failed to start conversation: $error');
    }
  }

  String _resolveUserId(Map<String, dynamic>? data, String fallback) {
    if (data != null) {
      for (final key in const ['userId', 'uid', 'authId', 'user_id', 'firebaseUid']) {
        final value = data[key];
        if (value is String) {
          final trimmed = value.trim();
          if (trimmed.isNotEmpty) {
            return trimmed;
          }
        }
      }
    }
    return fallback;
  }

  Future<List<MessagingContact>> fetchAllowedContacts({
    required String userRole,
    required String userId,
    List<String>? classIds,
  }) async {
    try {
      final normalizedRole = userRole.toLowerCase();
      final filterClassIds =
          classIds?.where((id) => id.isNotEmpty).toSet() ?? <String>{};

      final classesFuture =
          _firestore.collection(_classesCollection).get();
      final childrenFuture =
          _firestore.collection(_childrenCollection).get();
      final parentsFuture =
          _firestore.collection(_parentsCollection).get();
      final teachersFuture =
          _firestore.collection(_teachersCollection).get();
      final adminsFuture =
          _firestore.collection(_adminsCollection).get();
      final subjectsFuture =
          _firestore.collection(_subjectsCollection).get();

      final results = await Future.wait([
        classesFuture,
        childrenFuture,
        parentsFuture,
        teachersFuture,
        adminsFuture,
        subjectsFuture,
      ]);

      final QuerySnapshot classesSnapshot = results[0] as QuerySnapshot;
      final QuerySnapshot childrenSnapshot = results[1] as QuerySnapshot;
      final QuerySnapshot parentsSnapshot = results[2] as QuerySnapshot;
      final QuerySnapshot teachersSnapshot = results[3] as QuerySnapshot;
      final QuerySnapshot adminsSnapshot = results[4] as QuerySnapshot;
      final QuerySnapshot subjectsSnapshot = results[5] as QuerySnapshot;

      final Map<String, String> subjectNames = <String, String>{};
      for (final doc in subjectsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
        final name = (data['name'] as String?)?.trim();
        if (name != null && name.isNotEmpty) {
          subjectNames[doc.id] = name;
        }
      }

      final Map<String, Set<String>> teacherClassMap = <String, Set<String>>{};
      final Map<String, Map<String, Set<String>>> teacherSubjectsByClass =
          <String, Map<String, Set<String>>>{};
      for (final doc in classesSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
        final teacherSubjects =
            (data['teacherSubjects'] as Map<String, dynamic>?) ??
                <String, dynamic>{};
        for (final entry in teacherSubjects.entries) {
          final teacherId = entry.value;
          if (teacherId is String && teacherId.isNotEmpty) {
            teacherClassMap.putIfAbsent(teacherId, () => <String>{});
            teacherClassMap[teacherId]!.add(doc.id);
            final subjectKey = entry.key;
            if (subjectKey is String && subjectKey.trim().isNotEmpty) {
              final subjectId = subjectKey.trim();
              final resolvedSubjectName =
                  subjectNames[subjectId] ?? _prettifyDisplayValue(subjectId);
              if (resolvedSubjectName.isEmpty) {
                continue;
              }
              teacherSubjectsByClass.putIfAbsent(
                  teacherId, () => <String, Set<String>>{});
              final subjectsForClass = teacherSubjectsByClass[teacherId]!
                  .putIfAbsent(doc.id, () => <String>{});
              subjectsForClass.add(resolvedSubjectName);
            }
          }
        }
      }

      final Map<String, Set<String>> parentClassMap = <String, Set<String>>{};
      final Map<String, List<_ChildInfo>> parentChildren =
          <String, List<_ChildInfo>>{};
      for (final doc in childrenSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
        final parentId = (data['parentId'] as String?)?.trim();
        if (parentId == null || parentId.isEmpty) {
          continue;
        }
        parentClassMap.putIfAbsent(parentId, () => <String>{});
        final classId = (data['classId'] as String?)?.trim();
        if (classId != null && classId.isNotEmpty) {
          parentClassMap[parentId]!.add(classId);
        }
        final childName = (data['name'] as String?)?.trim();
        if (childName != null && childName.isNotEmpty) {
          parentChildren.putIfAbsent(parentId, () => <_ChildInfo>[]);
          parentChildren[parentId]!
              .add(_ChildInfo(name: childName, classId: classId));
        }
      }

      final List<MessagingContact> contacts = <MessagingContact>[];
      final Set<String> seenIds = <String>{userId};

      void addContact(MessagingContact contact) {
        final dedupeKey =
            contact.userId.isNotEmpty ? contact.userId : contact.id;
        if (seenIds.contains(dedupeKey)) {
          return;
        }
        seenIds.add(dedupeKey);
        contacts.add(contact);
      }

      for (final doc in teachersSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
        final id = doc.id;
        final resolvedUserId = _resolveUserId(data, id);
        final name = (data['name'] as String?)?.trim();
        final email = (data['email'] as String?)?.trim();
        final displayName = _formatDisplayName(name, email, 'Teacher');
        final teacherClassIds = List<String>.from(
          teacherClassMap[resolvedUserId] ?? teacherClassMap[id] ?? <String>{},
        );
        final teacherClassSet = teacherClassIds.toSet();
        if (filterClassIds.isNotEmpty &&
            normalizedRole != 'admin' &&
            teacherClassSet.isNotEmpty &&
            teacherClassSet.intersection(filterClassIds).isEmpty) {
          continue;
        }
        String? relationship;
        if (normalizedRole == 'parent') {
          final myChildren = parentChildren[userId] ?? <_ChildInfo>[];
          final relevantChildren = myChildren
              .where((child) =>
                  child.classId != null &&
                  teacherClassSet.contains(child.classId!))
              .toList();
          if (relevantChildren.isNotEmpty) {
            final childNames = relevantChildren
                .map((child) => _prettifyDisplayValue(child.name))
                .where((name) => name.isNotEmpty)
                .toList();
            final subjectLabels = <String>{};
            for (final child in relevantChildren) {
              final classId = child.classId;
              if (classId == null) {
                continue;
              }
              final subjects =
                  teacherSubjectsByClass[resolvedUserId]?[classId] ??
                      teacherSubjectsByClass[id]?[classId] ??
                      const <String>{};
              subjectLabels.addAll(subjects);
            }
            final formattedChildren = _formatList(childNames);
            final formattedSubjects = _formatList(subjectLabels);
            if (formattedChildren.isNotEmpty) {
              relationship = formattedSubjects.isNotEmpty
                  ? 'messaging_relationship_subject_teacher_of'.trParams({
                      'subject': formattedSubjects,
                      'name': formattedChildren,
                    })
                  : 'messaging_relationship_teacher_of'
                      .trParams({'name': formattedChildren});
            }
          }
        }
        addContact(MessagingContact(
          id: id,
          userId: resolvedUserId,
          name: displayName,
          role: 'teacher',
          classIds: teacherClassIds,
          relationship: relationship,
        ));
      }

      for (final doc in parentsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
        final id = doc.id;
        final resolvedUserId = _resolveUserId(data, id);
        final name = (data['name'] as String?)?.trim();
        final email = (data['email'] as String?)?.trim();
        final displayName = _formatDisplayName(name, email, 'Parent');
        final parentClassIds = List<String>.from(
          parentClassMap[resolvedUserId] ?? parentClassMap[id] ?? <String>{},
        );
        final parentClassSet = parentClassIds.toSet();
        if (filterClassIds.isNotEmpty &&
            normalizedRole != 'admin' &&
            parentClassSet.isNotEmpty &&
            parentClassSet.intersection(filterClassIds).isEmpty) {
          continue;
        }
        Iterable<_ChildInfo> relevantChildren =
            parentChildren[resolvedUserId] ??
                parentChildren[id] ??
                <_ChildInfo>[];
        if (normalizedRole == 'teacher' && filterClassIds.isNotEmpty) {
          relevantChildren = relevantChildren.where((child) {
            final classId = child.classId;
            if (classId == null || classId.isEmpty) {
              return false;
            }
            return filterClassIds.contains(classId);
          });
        }
        final childNames = relevantChildren
            .map((child) => _prettifyDisplayValue(child.name))
            .where((name) => name.isNotEmpty)
            .toList();
        final relationship = childNames.isEmpty
            ? null
            : 'messaging_relationship_parent_of'
                .trParams({'name': _formatList(childNames)});
        addContact(MessagingContact(
          id: id,
          userId: resolvedUserId,
          name: displayName,
          role: 'parent',
          classIds: parentClassIds,
          relationship: relationship,
        ));
      }

      for (final doc in adminsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
        final id = doc.id;
        final resolvedUserId = _resolveUserId(data, id);
        final name = (data['name'] as String?)?.trim();
        final email = (data['email'] as String?)?.trim();
        final displayName =
            _formatDisplayName(name, email, 'Administrator');
        addContact(MessagingContact(
          id: id,
          userId: resolvedUserId,
          name: displayName,
          role: 'admin',
        ));
      }

      contacts.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return contacts;
    } on FirebaseException catch (error) {
      final message = error.message ?? error.code;
      throw Exception('Failed to load contacts: $message');
    } catch (error) {
      throw Exception('Failed to load contacts: $error');
    }
  }

  Future<List<ConversationParticipant>> _resolveParticipants(
    String conversationId,
    List<ConversationParticipant>? participants,
  ) async {
    if (participants != null && participants.isNotEmpty) {
      return participants;
    }

    try {
      final doc = await _firestore
          .collection(_conversationsCollection)
          .doc(conversationId)
          .get();
      final data = doc.data();
      if (data == null) {
        return <ConversationParticipant>[];
      }
      final rawParticipants = data['participants'];
      if (rawParticipants is Iterable) {
        return rawParticipants
            .whereType<Map<String, dynamic>>()
            .map(ConversationParticipant.fromJson)
            .toList();
      }
      final participantIds =
          (data['participantIds'] as Iterable?)?.whereType<String>() ??
              <String>[];
      if (participantIds.isEmpty) {
        return <ConversationParticipant>[];
      }
      return participantIds
          .map(
            (id) => ConversationParticipant(
              id: id,
              name: id == _authService.currentUser?.uid ? 'You' : id,
              role: 'user',
              userId: id,
            ),
          )
          .toList();
    } on FirebaseException {
      return <ConversationParticipant>[];
    }
  }

  ConversationModel _conversationFromData(
    String id,
    Map<String, dynamic> data,
  ) {
    final participantsRaw = data['participants'];
    final participants = participantsRaw is Iterable
        ? participantsRaw
            .whereType<Map<String, dynamic>>()
            .map(ConversationParticipant.fromJson)
            .toList()
        : <ConversationParticipant>[];
    final updatedAt =
        (data['updatedAt'] as Timestamp?)?.toDate().toUtc() ?? DateTime.now().toUtc();
    final title = (data['title'] as String?)?.trim();
    final resolvedTitle =
        (title != null && title.isNotEmpty)
            ? _prettifyDisplayValue(title)
            : _deriveTitleFromParticipants(participants);

    final unreadCount = _resolveUnreadCount(data);

    return ConversationModel(
      id: id,
      title: resolvedTitle,
      lastMessagePreview: (data['lastMessagePreview'] as String?) ?? '',
      updatedAt: updatedAt,
      participants: participants,
      unreadCount: unreadCount,
    );
  }

  int _resolveUnreadCount(Map<String, dynamic> data) {
    final currentUserId = _authService.currentUser?.uid;
    if (currentUserId != null) {
      final unreadBy = data['unreadBy'];
      if (unreadBy is Map<String, dynamic>) {
        final value = unreadBy[currentUserId];
        if (value is num) {
          return value.toInt();
        }
      }
    }

    final fallback = data['unreadCount'];
    if (fallback is num) {
      return fallback.toInt();
    }
    return 0;
  }

  String _formatDisplayName(String? name, String? email, String fallback) {
    final cleanedName = _prettifyDisplayValue(name);
    if (cleanedName.isNotEmpty) {
      return cleanedName;
    }
    final cleanedEmail = _prettifyDisplayValue(email);
    if (cleanedEmail.isNotEmpty) {
      return cleanedEmail;
    }
    return fallback;
  }

  String _prettifyDisplayValue(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) {
      return '';
    }
    if (raw.contains('@')) {
      final localPart = raw.split('@').first;
      final sanitized =
          localPart.replaceAll(RegExp(r'[._]+'), ' ').replaceAll('-', ' ').trim();
      if (sanitized.isEmpty) {
        return raw;
      }
      final words = sanitized.split(RegExp(r'\s+'));
      return words.map(_capitalize).join(' ');
    }
    return raw.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _formatList(Iterable<String> values) {
    final seen = LinkedHashSet<String>();
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      seen.add(trimmed);
    }
    if (seen.isEmpty) {
      return '';
    }
    if (seen.length == 1) {
      return seen.first;
    }
    if (seen.length == 2) {
      final iterator = seen.iterator;
      iterator.moveNext();
      final first = iterator.current;
      iterator.moveNext();
      final second = iterator.current;
      return '$first & $second';
    }
    final items = seen.toList();
    final last = items.removeLast();
    return '${items.join(', ')} & $last';
  }

  String _capitalize(String value) {
    if (value.isEmpty) {
      return value;
    }
    final lower = value.toLowerCase();
    return '${lower[0].toUpperCase()}${lower.substring(1)}';
  }

  Future<void> markConversationAsRead({
    required String conversationId,
    required String userId,
    List<String>? messageIds,
  }) async {
    final conversationRef =
        _firestore.collection(_conversationsCollection).doc(conversationId);
    final batch = _firestore.batch();

    batch.set(
      conversationRef,
      <String, dynamic>{
        'unreadBy': <String, dynamic>{
          userId: 0,
        },
      },
      SetOptions(merge: true),
    );

    final ids = messageIds?.where((id) => id.isNotEmpty).toSet() ?? <String>{};
    for (final id in ids) {
      final messageRef =
          conversationRef.collection(_messagesCollection).doc(id);
      batch.set(
        messageRef,
        <String, dynamic>{
          'readBy': FieldValue.arrayUnion(<String>[userId]),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  String _deriveTitleFromParticipants(
    List<ConversationParticipant> participants,
  ) {
    if (participants.isEmpty) {
      return 'Conversation';
    }
    final currentUserId = _authService.currentUser?.uid;
    final otherNames = participants
        .where((participant) => participant.id != currentUserId)
        .map((participant) => _prettifyDisplayValue(participant.name))
        .where((name) => name.isNotEmpty)
        .toList();
    if (otherNames.isNotEmpty) {
      return _formatList(otherNames);
    }
    final allNames = participants
        .map((participant) => _prettifyDisplayValue(participant.name))
        .where((name) => name.isNotEmpty)
        .toList();
    if (allNames.isNotEmpty) {
      return _formatList(allNames);
    }
    return 'Conversation';
  }

  Future<void> _handleAuthStateChanged(User? user) async {
    if (user == null) {
      unawaited(_handleUserSignedOut());
    } else {
      unawaited(_handleUserSignedIn(user));
    }
  }

  Future<void> _handleUserSignedIn(User user) async {
    _lastKnownUserId = user.uid;
    _deviceTokenRestored = false;
    debugPrint('User ${user.uid} signed in. pushPermissionGranted=$_pushPermissionGranted');
    if (!_pushPermissionGranted) {
      debugPrint('Push permission not granted yet. Deferring token registration.');
      return;
    }

    await _restoreDeviceToken(user.uid);
    final pending = _pendingToken;
    if (pending != null && pending.isNotEmpty) {
      debugPrint('Registering pending FCM token for user ${user.uid}.');
      await _registerTokenForUser(user.uid, pending);
      return;
    }

    await _ensureTokenForUser(user.uid);
  }

  Future<void> _handleUserSignedOut() async {
    final userId = _lastKnownUserId;
    final token = _lastKnownToken;
    _lastKnownUserId = null;
    _pendingToken = null;
    _deviceTokenRestored = false;
    if (userId == null || token == null || token.isEmpty) {
      _lastKnownToken = null;
      return;
    }

    await _removeTokenFromFirestore(
      userId,
      token,
      removeDeviceAssociation: true,
    );
    _lastKnownToken = null;
  }

  Future<void> _ensureTokenForCurrentUser() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      return;
    }
    await _ensureTokenForUser(userId);
  }

  Future<void> _ensureTokenForUser(String userId) async {
    if (!_pushPermissionGranted) {
      debugPrint('Skipped ensureTokenForUser for $userId because push permission is not granted.');
      return;
    }

    try {
      await _restoreDeviceToken(userId);
      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        final preview = token.length > 8 ? '${token.substring(0, 8)}…' : token;
        debugPrint('FirebaseMessaging.getToken for $userId returned $preview');
        await _registerTokenForUser(userId, token);
      } else {
        debugPrint('FirebaseMessaging.getToken returned empty token for $userId.');
      }
    } catch (error) {
      debugPrint('Failed to retrieve FCM token: $error');
    }
  }

  void _handleNewToken(String token) {
    if (token.isEmpty) {
      return;
    }
    final preview = token.length > 8 ? '${token.substring(0, 8)}…' : token;
    debugPrint('Received refreshed FCM token $preview');
    _pendingToken = token;
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      debugPrint('Token refresh received before user login; storing pending token.');
      return;
    }

    unawaited(_registerTokenForUser(userId, token));
  }

  Future<void> _registerTokenForUser(String userId, String token) async {
    if (token.isEmpty) {
      debugPrint('Ignoring empty FCM token for user $userId.');
      return;
    }

    try {
      final previousToken = _lastKnownToken;
      if (previousToken != null && previousToken == token) {
        debugPrint('FCM token unchanged for $userId; ensuring Firestore metadata is current.');
      } else if (previousToken != null && previousToken.isNotEmpty) {
        final previewPrev =
            previousToken.length > 8 ? '${previousToken.substring(0, 8)}…' : previousToken;
        final previewNew = token.length > 8 ? '${token.substring(0, 8)}…' : token;
        debugPrint('Replacing stored FCM token for $userId: $previewPrev → $previewNew');
      } else {
        final preview = token.length > 8 ? '${token.substring(0, 8)}…' : token;
        debugPrint('Registering new FCM token for $userId: $preview');
      }

      await _saveTokenToFirestore(userId, token);
      if (previousToken != null && previousToken.isNotEmpty &&
          previousToken != token) {
        await _removeTokenFromFirestore(userId, previousToken);
      }
      _lastKnownToken = token;
      _pendingToken = null;
      _lastKnownUserId = userId;
    } catch (error) {
      debugPrint('Failed to register FCM token: $error');
    }
  }

  Future<void> _saveTokenToFirestore(String userId, String token) async {
    try {
      final preview = token.length > 8 ? '${token.substring(0, 8)}…' : token;
      debugPrint('Saving FCM token for user $userId (preview: $preview)');
      final doc = _firestore.collection(_tokenCollection).doc(userId);
      final deviceId = _deviceId;

      final result = await _firestore
          .runTransaction<_DeviceTokenSaveResult?>((transaction) async {
        final snapshot = await transaction.get(doc);
        final now = FieldValue.serverTimestamp();
        final updates = <String, dynamic>{
          'tokens': FieldValue.arrayUnion(<String>[token]),
          'updatedAt': now,
          'lastPlatform': defaultTargetPlatform.name,
        };

        String? previousDeviceToken;
        if (!snapshot.exists) {
          updates['createdAt'] = now;
        }

        final data = snapshot.data();
        if (deviceId != null && deviceId.isNotEmpty) {
          updates['deviceTokens.$deviceId'] = token;
          updates['devicePlatforms.$deviceId'] = defaultTargetPlatform.name;
          updates['deviceUpdatedAt.$deviceId'] = now;

          if (data != null) {
            final deviceTokens =
                (data['deviceTokens'] as Map<String, dynamic>?) ?? <String, dynamic>{};
            previousDeviceToken = deviceTokens[deviceId] as String?;
            final deviceCreatedAt =
                (data['deviceCreatedAt'] as Map<String, dynamic>?) ?? <String, dynamic>{};
            if (!deviceCreatedAt.containsKey(deviceId)) {
              updates['deviceCreatedAt.$deviceId'] = now;
            }
          } else {
            updates['deviceCreatedAt.$deviceId'] = now;
          }
        }

        transaction.set(
          doc,
          updates,
          SetOptions(merge: true),
        );

        return _DeviceTokenSaveResult(previousDeviceToken: previousDeviceToken);
      });

      if (result == null) {
        debugPrint('Stored FCM token metadata for user $userId without device association.');
      } else {
        final previous = result.previousDeviceToken;
        if (previous == null || previous.isEmpty) {
          debugPrint('Created device token entry for user $userId.');
        } else if (previous == token) {
          debugPrint('Device token for user $userId already up to date.');
        } else {
          final previewPrev =
              previous.length > 8 ? '${previous.substring(0, 8)}…' : previous;
          debugPrint('Updated device token for user $userId (was $previewPrev).');
        }
      }
    } catch (error) {
      debugPrint('Failed to store FCM token: $error');
    }
  }


  Future<void> _removeTokenFromFirestore(
    String userId,
    String token, {
    bool removeDeviceAssociation = false,
  }) async {
    try {
      final doc = _firestore.collection(_tokenCollection).doc(userId);
      final updates = <String, dynamic>{
        'tokens': FieldValue.arrayRemove(<String>[token]),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (removeDeviceAssociation) {
        final deviceId = _deviceId;
        if (deviceId != null && deviceId.isNotEmpty) {
          updates['deviceTokens.$deviceId'] = FieldValue.delete();
          updates['devicePlatforms.$deviceId'] = FieldValue.delete();
          updates['deviceUpdatedAt.$deviceId'] = FieldValue.delete();
          updates['deviceCreatedAt.$deviceId'] = FieldValue.delete();
        }
      }
      await doc.set(
        updates,
        SetOptions(merge: true),
      );
      final preview = token.length > 8 ? '${token.substring(0, 8)}…' : token;
      debugPrint('Removed stale FCM token for $userId (preview: $preview)');
    } catch (error) {
      debugPrint('Failed to remove FCM token: $error');
    }
  }

  Future<void> _ensureDeviceId() async {
    if (_deviceId != null && _deviceId!.isNotEmpty) {
      return;
    }
    _preferences ??= await SharedPreferences.getInstance();
    final stored = _preferences?.getString(_deviceIdPrefsKey);
    if (stored != null && stored.isNotEmpty) {
      _deviceId = stored;
      return;
    }
    final generated = _generateDeviceId();
    await _preferences?.setString(_deviceIdPrefsKey, generated);
    _deviceId = generated;
  }

  String _generateDeviceId() {
    final random = math.Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch.toRadixString(16);
    final randomBytes = List<int>.generate(6, (_) => random.nextInt(16));
    final randomPart = randomBytes.map((value) => value.toRadixString(16)).join();
    return 'device-$timestamp-$randomPart';
  }

  Future<void> _restoreDeviceToken(String userId) async {
    if (_deviceTokenRestored) {
      return;
    }
    final deviceId = _deviceId;
    if (deviceId == null || deviceId.isEmpty) {
      return;
    }

    try {
      final snapshot =
          await _firestore.collection(_tokenCollection).doc(userId).get();
      final data = snapshot.data();
      if (data != null) {
        final deviceTokens = data['deviceTokens'];
        if (deviceTokens is Map<String, dynamic>) {
          final storedToken = deviceTokens[deviceId];
          if (storedToken is String && storedToken.isNotEmpty) {
            _lastKnownToken = storedToken;
            final preview =
                storedToken.length > 8 ? '${storedToken.substring(0, 8)}…' : storedToken;
            debugPrint('Restored stored FCM token for $userId (preview: $preview)');
          } else {
            debugPrint('No stored FCM token found for device $deviceId belonging to $userId.');
          }
        } else {
          debugPrint('Device token map missing for user $userId while restoring token.');
        }
      } else {
        debugPrint('No token document found for user $userId while restoring device token.');
      }
      _deviceTokenRestored = true;
    } catch (error) {
      debugPrint('Failed to restore device token: $error');
    }
  }

  Future<List<String>> _fetchTokensForUsers(List<String> userIds) async {
    if (userIds.isEmpty) {
      return <String>[];
    }

    final results = <String>{};
    for (var index = 0; index < userIds.length; index += _firestoreBatchLimit) {
      final end = math.min(index + _firestoreBatchLimit, userIds.length);
      final batch = userIds.sublist(index, end);
      try {
        final snapshot = await _firestore
            .collection(_tokenCollection)
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final dynamic tokens = data['tokens'];
          if (tokens is Iterable) {
            results.addAll(
              tokens
                  .whereType<String>()
                  .map((token) => token.trim())
                  .where((token) => token.isNotEmpty),
            );
          }
          final deviceTokens = data['deviceTokens'];
          if (deviceTokens is Map<String, dynamic>) {
            results.addAll(
              deviceTokens.values
                  .whereType<String>()
                  .map((token) => token.trim())
                  .where((token) => token.isNotEmpty),
            );
          }
        }
      } catch (error) {
        debugPrint('Failed to fetch tokens for users: $error');
      }
    }

    if (results.isEmpty) {
      debugPrint('No FCM tokens found for userIds: $userIds');
    } else {
      final preview = results
          .map((token) => token.length > 8 ? '${token.substring(0, 8)}…' : token)
          .take(3)
          .join(', ');
      debugPrint(
        'Fetched ${results.length} FCM tokens for userIds $userIds (preview: $preview)',
      );
    }

    return results.toList();
  }

  Future<void> _initializePushNotifications() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    FirebaseMessaging.onBackgroundMessage(messagingBackgroundHandler);

    final status = settings.authorizationStatus;
    debugPrint('FirebaseMessaging.requestPermission completed with status $status');
    if (status == AuthorizationStatus.denied ||
        status == AuthorizationStatus.notDetermined) {
      _pushPermissionGranted = false;
      debugPrint('Push permission denied. Tokens will not be requested.');
      return;
    }

    _pushPermissionGranted = true;

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('Foreground notification presentation options configured.');

    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription =
        _messaging.onTokenRefresh.listen(_handleNewToken, onError: (Object error) {
      debugPrint('Failed to refresh FCM token: $error');
    });
    debugPrint('Subscribed to FCM token refresh events.');

    final currentToken = _lastKnownToken;
    if (currentToken != null && currentToken.isNotEmpty) {
      final preview =
          currentToken.length > 8 ? '${currentToken.substring(0, 8)}…' : currentToken;
      debugPrint('Current device token snapshot after subscription: $preview');
    }

    _foregroundMessageSubscription?.cancel();
    _foregroundMessageSubscription =
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    _messageOpenedAppSubscription?.cancel();
    _messageOpenedAppSubscription =
        FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    debugPrint('LISTENERS: onMessage + onMessageOpenedApp attached');
  }

  Future<void> _setupLocalNotifications() async {
    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsDarwin = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) {
          return;
        }

        try {
          final data =
              Map<String, dynamic>.from(jsonDecode(payload) as Map<String, dynamic>);
          _openConversationFromPayload(data);
        } catch (_) {
          // Ignore invalid payloads.
        }
      },
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(messagingAndroidChannel);
    await androidPlugin?.requestNotificationsPermission();

    final iosPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint(
      'FOREGROUND: received ${message.messageId ?? 'unknown'} data=${message.data}',
    );
    final model = MessageModel.fromRemoteMessage(message);
    _messageStreamController.add(model);
    _showForegroundNotification(message);
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    final payload = <String, dynamic>{
      ...message.data,
      if (message.notification?.title != null)
        'title': message.notification!.title,
      if (message.notification?.body != null)
        'body': message.notification!.body,
      if (message.messageId != null) 'messageId': message.messageId,
      if (!message.data.containsKey('conversationId') &&
          message.data['conversation_id'] != null)
        'conversationId': message.data['conversation_id'],
    };

    _openConversationFromPayload(payload);
  }

  Future<void> _handleInitialMessage() async {
    if (!_pushPermissionGranted) {
      return;
    }
    try {
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }
    } catch (error) {
      debugPrint('Failed to handle initial push notification: $error');
    }
  }

  void _openConversationFromPayload(Map<String, dynamic> data) {
    final conversationId =
        (data['conversationId'] ?? data['conversation_id'])?.toString();
    if (conversationId == null || conversationId.isEmpty) {
      return;
    }

    Future<void>.microtask(() {
      Get.toNamed(
        _messagingRoute,
        parameters: <String, String>{
          'conversationId': conversationId,
        },
        arguments: data,
      );
    });
  }

  /// Send a data-only payload so platform handlers always execute and exclude
  /// the sender's current device token to avoid self-notifications.
  Future<void> _sendPushNotification(
    MessageModel message,
    List<ConversationParticipant> participants,
  ) async {
    if (_pushClient == null || participants.isEmpty) {
      debugPrint('PUSH: no client/participants');
      return;
    }

    final recipientIds = <String>{};
    for (final participant in participants) {
      final primaryId =
          (participant.userId.isNotEmpty ? participant.userId : participant.id)
              .trim();
      final alternateId = participant.id.trim();

      if (primaryId.isNotEmpty && primaryId != message.senderId) {
        recipientIds.add(primaryId);
      }

      if (alternateId.isNotEmpty && alternateId != message.senderId) {
        recipientIds.add(alternateId);
      }
    }

    if (recipientIds.isEmpty) {
      debugPrint('PUSH: no recipientIds (after filtering sender)');
      return;
    }

    try {
      debugPrint('PUSH: recipientIds resolved=$recipientIds');
      final tokens = await _fetchTokensForUsers(recipientIds.toList());
      debugPrint('PUSH: token count before filter=${tokens.length}');

      final currentToken = _lastKnownToken?.trim();
      final filteredTokens = tokens
          .map((token) => token.trim())
          .where((token) => token.isNotEmpty)
          .where((token) => token != currentToken)
          .toSet()
          .toList();

      debugPrint(
        'PUSH: token count after filter=${filteredTokens.length} (current excluded=${currentToken != null})',
      );

      if (filteredTokens.isEmpty) {
        debugPrint('PUSH: no tokens to send (none or only sender token)');
        return;
      }

      final payload = <String, dynamic>{
        'priority': 'high',
        'registration_ids': filteredTokens,
        'data': <String, dynamic>{
          'conversationId': message.conversationId,
          'conversation_id': message.conversationId,
          'messageId': message.id,
          'senderId': message.senderId,
          'senderName': message.senderName,
          'content': message.content,
          'sentAt': message.sentAt.toIso8601String(),
          'title': message.senderName,
          'body': message.content,
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        },
        'content_available': true,
        'mutable_content': true,
      };

      debugPrint('PUSH: sending to ${filteredTokens.length} device(s)');
      final response = await _pushClient!.post<dynamic>(
        '/fcm/send',
        data: payload,
      );
      debugPrint('PUSH: FCM response (${response.statusCode}): ${response.data}');

      final responseData = response.data;
      if (responseData is Map && responseData['results'] is List) {
        final results = (responseData['results'] as List).cast<Map?>();
        for (var index = 0; index < results.length && index < filteredTokens.length; index++) {
          final result = results[index];
          final error = (result?['error'] as String?)?.trim();
          if (error != null && error.isNotEmpty) {
            final token = filteredTokens[index];
            final prefix = token.length > 8 ? '${token.substring(0, 8)}…' : token;
            debugPrint('PUSH: token error "$error" for $prefix');
          }
        }
      }
    } on DioException catch (error) {
      debugPrint('Failed to send FCM push: ${error.message ?? error.error}');
    } catch (error) {
      debugPrint('Failed to send FCM push: $error');
    }
  }

  @visibleForTesting
  Future<void> ensureTokenForUserForTesting(String userId) =>
      _ensureTokenForUser(userId);

  @visibleForTesting
  Future<void> registerTokenForUserForTesting(String userId, String token) =>
      _registerTokenForUser(userId, token);

  @visibleForTesting
  Future<void> saveTokenToFirestoreForTesting(String userId, String token) =>
      _saveTokenToFirestore(userId, token);

  @visibleForTesting
  Future<List<String>> fetchTokensForUsersForTesting(List<String> userIds) =>
      _fetchTokensForUsers(userIds);

  @visibleForTesting
  void debugSetPushPermissionGranted(bool granted) {
    _pushPermissionGranted = granted;
  }

  @visibleForTesting
  void debugSetDeviceId(String? deviceId) {
    _deviceId = deviceId;
    _deviceTokenRestored = false;
  }

  @visibleForTesting
  String? get debugLastKnownToken => _lastKnownToken;

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;

    await _localNotifications.show(
      notification?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
      notification?.title ?? data['title'] ?? 'New message',
      notification?.body ?? data['content'] ?? data['text'] ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          messagingAndroidChannel.id,
          messagingAndroidChannel.name,
          channelDescription: messagingAndroidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: const DefaultStyleInformation(true, true),
        ),
        iOS: messagingDarwinNotificationDetails,
      ),
      payload: jsonEncode(<String, dynamic>{
        ...data,
        if (!data.containsKey('conversationId') &&
            data['conversation_id'] != null)
          'conversationId': data['conversation_id'],
      }),
    );
  }

  @override
  void onClose() {
    _tokenRefreshSubscription?.cancel();
    _authSubscription?.cancel();
    _foregroundMessageSubscription?.cancel();
    _messageOpenedAppSubscription?.cancel();
    _messageStreamController.close();
    super.onClose();
  }
}

class _ChildInfo {
  _ChildInfo({required this.name, required this.classId});

  final String name;
  final String? classId;
}
