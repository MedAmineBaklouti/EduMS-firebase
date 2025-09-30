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

import '../../../app/config/app_config.dart';
import '../../../core/services/auth_service.dart';
import '../../../data/models/conversation_model.dart';
import '../../../data/models/message_model.dart';
import '../../../data/models/messaging_contact.dart';
import 'messaging_push_handler.dart';

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
  String? _lastKnownToken;
  String? _pendingToken;
  String? _lastKnownUserId;
  bool _pushPermissionGranted = false;

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    'messaging_channel',
    'Messaging notifications',
    description: 'Notifications for new chat messages.',
    importance: Importance.high,
  );

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

  static Dio? _createPushClient() {
    final serverKey = AppConfig.fcmServerKey.trim();
    if (serverKey.isEmpty) {
      return null;
    }

    return Dio(
      BaseOptions(
        baseUrl: 'https://fcm.googleapis.com',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: <String, dynamic>{
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
      ),
    );
  }

  Stream<MessageModel> get messageStream => _messageStreamController.stream;

  Future<MessagingService> init() async {
    await _setupLocalNotifications();
    await _initializePushNotifications();
    _authSubscription?.cancel();
    _authSubscription = _authService.user.listen(_handleAuthStateChanged);
    if (_pushPermissionGranted) {
      await _ensureTokenForCurrentUser();
    }

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
      participantIds.addAll(resolvedParticipants.map((participant) => participant.id));

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
                  'name': participant.name,
                  'role': participant.role,
                })
            .toList();
      }

      await conversationRef.set(updateData, SetOptions(merge: true));

      final unreadFieldUpdates = <String, Object>{};
      for (final participant in resolvedParticipants) {
        if (participant.id == senderId || participant.id.isEmpty) {
          continue;
        }
        unreadFieldUpdates['unreadBy.${participant.id}'] =
            FieldValue.increment(1);
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
        if (participantIds.contains(contact.id)) {
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
        ),
        ConversationParticipant(
          id: contact.id,
          name: contact.name,
          role: contact.role,
        ),
      ];

      final docRef =
          _firestore.collection(_conversationsCollection).doc();
      await docRef.set(<String, dynamic>{
        'title': contact.name,
        'lastMessagePreview': '',
        'participantIds': <String>{user.uid, contact.id}.toList(),
        'participants': participants
            .map((participant) => <String, dynamic>{
                  'id': participant.id,
                  'name': participant.name,
                  'role': participant.role,
                })
            .toList(),
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'unreadCount': 0,
        'unreadBy': <String, dynamic>{
          user.uid: 0,
          contact.id: 0,
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
        if (seenIds.contains(contact.id)) {
          return;
        }
        seenIds.add(contact.id);
        contacts.add(contact);
      }

      for (final doc in teachersSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
        final id = doc.id;
        final name = (data['name'] as String?)?.trim();
        final email = (data['email'] as String?)?.trim();
        final displayName = _formatDisplayName(name, email, 'Teacher');
        final teacherClassIds =
            List<String>.from(teacherClassMap[id] ?? <String>{});
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
                  teacherSubjectsByClass[id]?[classId] ?? const <String>{};
              subjectLabels.addAll(subjects);
            }
            final formattedChildren = _formatList(childNames);
            final formattedSubjects = _formatList(subjectLabels);
            if (formattedChildren.isNotEmpty) {
              relationship = formattedSubjects.isNotEmpty
                  ? '$formattedSubjects teacher of $formattedChildren'
                  : 'Teacher of $formattedChildren';
            }
          }
        }
        addContact(MessagingContact(
          id: id,
          name: displayName,
          role: 'teacher',
          classIds: teacherClassIds,
          relationship: relationship,
        ));
      }

      for (final doc in parentsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
        final id = doc.id;
        final name = (data['name'] as String?)?.trim();
        final email = (data['email'] as String?)?.trim();
        final displayName = _formatDisplayName(name, email, 'Parent');
        final parentClassIds =
            List<String>.from(parentClassMap[id] ?? <String>{});
        final parentClassSet = parentClassIds.toSet();
        if (filterClassIds.isNotEmpty &&
            normalizedRole != 'admin' &&
            parentClassSet.isNotEmpty &&
            parentClassSet.intersection(filterClassIds).isEmpty) {
          continue;
        }
        Iterable<_ChildInfo> relevantChildren =
            parentChildren[id] ?? <_ChildInfo>[];
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
            : 'Parent of ${_formatList(childNames)}';
        addContact(MessagingContact(
          id: id,
          name: displayName,
          role: 'parent',
          classIds: parentClassIds,
          relationship: relationship,
        ));
      }

      for (final doc in adminsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
        final id = doc.id;
        final name = (data['name'] as String?)?.trim();
        final email = (data['email'] as String?)?.trim();
        final displayName =
            _formatDisplayName(name, email, 'Administrator');
        addContact(MessagingContact(
          id: id,
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
    if (!_pushPermissionGranted) {
      return;
    }

    final pending = _pendingToken;
    if (pending != null && pending.isNotEmpty) {
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
    if (userId == null || token == null || token.isEmpty) {
      _lastKnownToken = null;
      return;
    }

    await _removeTokenFromFirestore(userId, token);
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
      return;
    }

    try {
      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _registerTokenForUser(userId, token);
      }
    } catch (error) {
      debugPrint('Failed to retrieve FCM token: $error');
    }
  }

  void _handleNewToken(String token) {
    if (token.isEmpty) {
      return;
    }
    _pendingToken = token;
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      return;
    }

    unawaited(_registerTokenForUser(userId, token));
  }

  Future<void> _registerTokenForUser(String userId, String token) async {
    if (token.isEmpty) {
      return;
    }

    try {
      final previousToken = _lastKnownToken;
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
      final doc = _firestore.collection(_tokenCollection).doc(userId);
      await doc.set(
        <String, dynamic>{
          'tokens': FieldValue.arrayUnion(<String>[token]),
          'updatedAt': FieldValue.serverTimestamp(),
          'lastPlatform': defaultTargetPlatform.name,
        },
        SetOptions(merge: true),
      );
    } catch (error) {
      debugPrint('Failed to store FCM token: $error');
    }
  }

  Future<void> _removeTokenFromFirestore(String userId, String token) async {
    try {
      final doc = _firestore.collection(_tokenCollection).doc(userId);
      await doc.set(
        <String, dynamic>{
          'tokens': FieldValue.arrayRemove(<String>[token]),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (error) {
      debugPrint('Failed to remove FCM token: $error');
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
              tokens.whereType<String>().where((token) => token.isNotEmpty),
            );
          }
        }
      } catch (error) {
        debugPrint('Failed to fetch tokens for users: $error');
      }
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
    if (status == AuthorizationStatus.denied ||
        status == AuthorizationStatus.notDetermined) {
      _pushPermissionGranted = false;
      return;
    }

    _pushPermissionGranted = true;

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription =
        _messaging.onTokenRefresh.listen(_handleNewToken, onError: (Object error) {
      debugPrint('Failed to refresh FCM token: $error');
    });

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  Future<void> _setupLocalNotifications() async {
    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');
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
          final data = jsonDecode(payload) as Map<String, dynamic>;
          final conversationId =
              (data['conversationId'] ?? data['conversation_id'])?.toString();
          if (conversationId != null && conversationId.isNotEmpty) {
            Get.toNamed(
              _messagingRoute,
              parameters: <String, String>{
                'conversationId': conversationId,
              },
              arguments: data,
            );
          }
        } catch (_) {
          // Ignore invalid payloads.
        }
      },
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_androidChannel);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final model = MessageModel.fromRemoteMessage(message);
    _messageStreamController.add(model);
    _showForegroundNotification(message);
  }

  Future<void> _sendPushNotification(
    MessageModel message,
    List<ConversationParticipant> participants,
  ) async {
    if (_pushClient == null || participants.isEmpty) {
      return;
    }

    final recipientIds = participants
        .map((participant) => participant.id)
        .where((id) => id.isNotEmpty && id != message.senderId)
        .toSet()
        .toList();

    if (recipientIds.isEmpty) {
      return;
    }

    try {
      final tokens = await _fetchTokensForUsers(recipientIds);
      if (tokens.isEmpty) {
        return;
      }

      await _pushClient!.post<dynamic>(
        '/fcm/send',
        data: <String, dynamic>{
          'registration_ids': tokens,
          'notification': <String, dynamic>{
            'title': message.senderName,
            'body': message.content,
          },
          'data': <String, dynamic>{
            'conversationId': message.conversationId,
            'messageId': message.id,
            'senderId': message.senderId,
            'senderName': message.senderName,
            'content': message.content,
            'sentAt': message.sentAt.toIso8601String(),
          },
        },
      );
    } on DioException catch (error) {
      debugPrint('Failed to send FCM push: ${error.message ?? error.error}');
    } catch (error) {
      debugPrint('Failed to send FCM push: $error');
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;

    await _localNotifications.show(
      notification?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
      notification?.title ?? data['title'] ?? 'New message',
      notification?.body ?? data['content'] ?? data['text'] ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: const DefaultStyleInformation(true, true),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
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
    _messageStreamController.close();
    super.onClose();
  }
}

class _ChildInfo {
  _ChildInfo({required this.name, required this.classId});

  final String name;
  final String? classId;
}
