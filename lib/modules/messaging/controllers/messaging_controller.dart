import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/database_service.dart';
import '../../../data/models/child_model.dart';
import '../../../data/models/conversation_model.dart';
import '../../../data/models/message_model.dart';
import '../../../data/models/parent_model.dart';
import '../../../data/models/school_class_model.dart';
import '../../../data/models/teacher_model.dart';
import '../services/messaging_service.dart';

class MessagingRecipient {
  final String id;
  final String name;
  final String role;
  final String? subtitle;

  const MessagingRecipient({
    required this.id,
    required this.name,
    required this.role,
    this.subtitle,
  });
}

class MessagingController extends GetxController {
  MessagingController()
      : _messagingService = Get.find(),
        _databaseService = Get.find(),
        _authService = Get.find(),
        _prefs = Get.find();

  final MessagingService _messagingService;
  final DatabaseService _databaseService;
  final AuthService _authService;
  final SharedPreferences _prefs;

  final RxList<ConversationModel> conversations = <ConversationModel>[].obs;
  final RxList<MessageModel> messages = <MessageModel>[].obs;
  final RxList<MessagingRecipient> recipients = <MessagingRecipient>[].obs;
  final Rxn<MessagingRecipient> selectedRecipient = Rxn<MessagingRecipient>();
  final Rxn<ConversationModel> selectedConversation = Rxn<ConversationModel>();

  final RxBool isLoading = true.obs;
  final RxBool isRecipientsLoading = false.obs;
  final RxBool isSending = false.obs;

  final TextEditingController messageController = TextEditingController();
  final ScrollController messageScrollController = ScrollController();
  final RxString draftText = ''.obs;

  final RxString currentUserName = ''.obs;
  final RxnString currentRole = RxnString();

  StreamSubscription<List<ConversationModel>>? _conversationSubscription;
  StreamSubscription<List<MessageModel>>? _messageSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<String>? _tokenSubscription;

  String? _currentToken;
  String? get currentUserId => _authService.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    messageController.addListener(_handleDraftChanged);
    _initialize();
  }

  @override
  void onClose() {
    messageController.removeListener(_handleDraftChanged);
    messageController.dispose();
    messageScrollController.dispose();
    _conversationSubscription?.cancel();
    _messageSubscription?.cancel();
    _foregroundSubscription?.cancel();
    _tokenSubscription?.cancel();
    super.onClose();
  }

  Future<void> _initialize() async {
    final user = _authService.currentUser;
    if (user == null) {
      isLoading.value = false;
      return;
    }

    currentRole.value = _prefs.getString('userRole');
    await _loadCurrentProfile();
    await _registerForPushNotifications();

    _conversationSubscription = _messagingService
        .streamConversations(user.uid)
        .listen(_handleConversationUpdate);

    await loadRecipients();
    isLoading.value = false;
  }

  void _handleDraftChanged() {
    draftText.value = messageController.text;
  }

  void _handleConversationUpdate(List<ConversationModel> items) {
    conversations.assignAll(items);
    final current = selectedConversation.value;
    if (current != null) {
      final match = items.firstWhereOrNull((element) => element.id == current.id);
      if (match != null) {
        selectedConversation.value = match;
      }
    }
  }

  Future<void> _loadCurrentProfile() async {
    final uid = currentUserId;
    if (uid == null) {
      return;
    }

    final role = currentRole.value;
    try {
      if (role == 'admin') {
        final doc = await _databaseService.firestore.collection('admins').doc(uid).get();
        if (doc.exists) {
          currentUserName.value = doc.data()?['name'] as String? ?? currentUserName.value;
        }
      } else if (role == 'teacher') {
        final doc = await _databaseService.firestore.collection('teachers').doc(uid).get();
        if (doc.exists) {
          final teacher = TeacherModel.fromDoc(doc);
          currentUserName.value = teacher.name;
        }
      } else if (role == 'parent') {
        final doc = await _databaseService.firestore.collection('parents').doc(uid).get();
        if (doc.exists) {
          final parent = ParentModel.fromDoc(doc);
          currentUserName.value = parent.name;
        }
      }
    } catch (_) {
      // Swallow and keep fallback values
    }

    if (currentUserName.value.isEmpty) {
      currentUserName.value = _authService.currentUser?.email ?? 'User';
    }
  }

  Map<String, dynamic> get _currentUserDetails => <String, dynamic>{
        'name': currentUserName.value,
        'role': currentRole.value ?? 'user',
      };

  Future<void> _registerForPushNotifications() async {
    final uid = currentUserId;
    if (uid == null) {
      return;
    }

    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return;
    }

    final token = await messaging.getToken();
    if (token != null) {
      _currentToken = token;
      await _messagingService.saveDeviceToken(uid, token);
    }

    _tokenSubscription = messaging.onTokenRefresh.listen((newToken) async {
      final previous = _currentToken;
      _currentToken = newToken;
      await _messagingService.saveDeviceToken(uid, newToken);
      if (previous != null && previous != newToken) {
        await _messagingService.removeDeviceToken(uid, previous);
      }
    });

    _foregroundSubscription = FirebaseMessaging.onMessage.listen((message) {
      final title = message.notification?.title ?? message.data['title'] as String?;
      final body = message.notification?.body ?? message.data['body'] as String?;
      if (title != null || body != null) {
        Get.snackbar(
          title ?? 'New message',
          body ?? '',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4),
        );
      }

      final conversationId = message.data['conversationId'] as String?;
      final uid = currentUserId;
      if (conversationId != null && uid != null) {
        _messagingService.markConversationRead(conversationId, uid);
      }
    });
  }

  Future<void> loadRecipients() async {
    final uid = currentUserId;
    if (uid == null) {
      return;
    }

    isRecipientsLoading.value = true;
    try {
      final role = currentRole.value;
      List<MessagingRecipient> items = <MessagingRecipient>[];
      if (role == 'admin') {
        items = await _loadAdminRecipients(uid);
      } else if (role == 'teacher') {
        items = await _loadTeacherRecipients(uid);
      } else if (role == 'parent') {
        items = await _loadParentRecipients(uid);
      }
      recipients.assignAll(items);
      final currentSelection = selectedRecipient.value;
      if (currentSelection != null) {
        selectedRecipient.value = recipients
            .firstWhereOrNull((item) => item.id == currentSelection.id);
      }
    } catch (error) {
      Get.snackbar(
        'Messaging contacts',
        'Unable to load contacts: $error',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isRecipientsLoading.value = false;
    }
  }

  Future<List<MessagingRecipient>> _loadAdminRecipients(String currentUid) async {
    final parentsSnap = await _databaseService.firestore.collection('parents').get();
    final teachersSnap = await _databaseService.firestore.collection('teachers').get();
    final adminsSnap = await _databaseService.firestore.collection('admins').get();

    final recipients = <MessagingRecipient>[];
    recipients.addAll(parentsSnap.docs.map((doc) {
      final parent = ParentModel.fromDoc(doc);
      return MessagingRecipient(
        id: parent.id,
        name: parent.name,
        role: 'parent',
        subtitle: parent.email,
      );
    }));

    recipients.addAll(teachersSnap.docs.map((doc) {
      final teacher = TeacherModel.fromDoc(doc);
      return MessagingRecipient(
        id: teacher.id,
        name: teacher.name,
        role: 'teacher',
        subtitle: teacher.email,
      );
    }));

    recipients.addAll(adminsSnap.docs.where((doc) => doc.id != currentUid).map((doc) {
      final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
      final name = data['name'] as String? ?? 'Administrator';
      final email = data['email'] as String? ?? '';
      return MessagingRecipient(
        id: doc.id,
        name: name,
        role: 'admin',
        subtitle: email.isEmpty ? 'Administrator' : email,
      );
    }));

    return recipients
        .sorted((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Future<List<MessagingRecipient>> _loadTeacherRecipients(String teacherId) async {
    final classesSnap = await _databaseService.firestore.collection('classes').get();
    final classModels = classesSnap.docs
        .map(SchoolClassModel.fromDoc)
        .where((item) => item.teacherSubjects.values.contains(teacherId))
        .toList();

    if (classModels.isEmpty) {
      return <MessagingRecipient>[];
    }

    final childIds = classModels.expand((c) => c.childIds).toSet().toList();
    final childDocs = await _fetchDocsByIds('children', childIds);
    final children = childDocs.map(ChildModel.fromDoc).toList();

    final parentIds = children.map((child) => child.parentId).toSet().toList();
    final parentDocs = await _fetchDocsByIds('parents', parentIds);
    final parentModels = parentDocs.map(ParentModel.fromDoc).toList();

    final Map<String, List<String>> parentChildMap = <String, List<String>>{};
    for (final child in children) {
      parentChildMap.putIfAbsent(child.parentId, () => <String>[]).add(child.name);
    }

    final recipients = parentModels.map((parent) {
      final childNames = parentChildMap[parent.id] ?? <String>[];
      final subtitle = childNames.isEmpty
          ? 'Parent'
          : 'Parent of ${childNames.join(', ')}';
      return MessagingRecipient(
        id: parent.id,
        name: parent.name,
        role: 'parent',
        subtitle: subtitle,
      );
    }).toList();

    return recipients
        .sorted((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Future<List<MessagingRecipient>> _loadParentRecipients(String parentId) async {
    final childrenSnap = await _databaseService.firestore
        .collection('children')
        .where('parentId', isEqualTo: parentId)
        .get();
    final children = childrenSnap.docs.map(ChildModel.fromDoc).toList();
    if (children.isEmpty) {
      return <MessagingRecipient>[];
    }

    final classIds = children.map((child) => child.classId).toSet().toList();
    final classDocs = await _fetchDocsByIds('classes', classIds);
    final classModels = classDocs.map(SchoolClassModel.fromDoc).toList();

    final teacherIds = classModels
        .expand((schoolClass) => schoolClass.teacherSubjects.values)
        .toSet()
        .toList();
    final teacherDocs = await _fetchDocsByIds('teachers', teacherIds);
    final teacherModels = teacherDocs.map(TeacherModel.fromDoc).toList();

    final Map<String, Set<String>> teacherChildMap = <String, Set<String>>{};
    final Map<String, Set<String>> teacherClassMap = <String, Set<String>>{};

    for (final classModel in classModels) {
      final childNames = children
          .where((child) => child.classId == classModel.id)
          .map((child) => child.name)
          .toSet();
      for (final teacherId in classModel.teacherSubjects.values) {
        teacherChildMap.putIfAbsent(teacherId, () => <String>{}).addAll(childNames);
        teacherClassMap.putIfAbsent(teacherId, () => <String>{}).add(classModel.name);
      }
    }

    final recipients = teacherModels.map((teacher) {
      final childNames = teacherChildMap[teacher.id] ?? <String>{};
      final classNames = teacherClassMap[teacher.id] ?? <String>{};
      String subtitle = 'Teacher';
      if (childNames.isNotEmpty) {
        subtitle = 'Teaches ${childNames.join(', ')}';
      }
      if (classNames.isNotEmpty) {
        subtitle = '$subtitle · ${classNames.join(', ')}';
      }
      return MessagingRecipient(
        id: teacher.id,
        name: teacher.name,
        role: 'teacher',
        subtitle: subtitle,
      );
    }).toList();

    return recipients
        .sorted((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _fetchDocsByIds(
    String collection,
    List<String> ids,
  ) async {
    final uniqueIds = ids.where((id) => id.isNotEmpty).toSet().toList();
    if (uniqueIds.isEmpty) {
      return <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    }

    const chunkSize = 10;
    final List<QueryDocumentSnapshot<Map<String, dynamic>>> results = <
        QueryDocumentSnapshot<Map<String, dynamic>>>[];
    for (var i = 0; i < uniqueIds.length; i += chunkSize) {
      final chunk = uniqueIds.sublist(i, min(i + chunkSize, uniqueIds.length));
      final snapshot = await _databaseService.firestore
          .collection(collection)
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      results.addAll(snapshot.docs);
    }
    return results;
  }

  MessagingRecipient? _recipientFromConversation(ConversationModel conversation) {
    final uid = currentUserId;
    if (uid == null) {
      return null;
    }

    final otherId = conversation.participants.firstWhereOrNull((id) => id != uid);
    if (otherId == null) {
      return null;
    }

    final existing = recipients.firstWhereOrNull((recipient) => recipient.id == otherId);
    if (existing != null) {
      return existing;
    }

    final details = conversation.participantDetails[otherId] as Map<String, dynamic>?;
    if (details == null) {
      return null;
    }

    return MessagingRecipient(
      id: otherId,
      name: details['name'] as String? ?? 'Contact',
      role: details['role'] as String? ?? 'user',
      subtitle: details['subtitle'] as String?,
    );
  }

  MessagingRecipient? recipientForConversation(ConversationModel conversation) {
    return _recipientFromConversation(conversation);
  }

  bool hasUnreadMessages(ConversationModel conversation) {
    final uid = currentUserId;
    if (uid == null) {
      return false;
    }
    return conversation.unreadBy.contains(uid);
  }

  Future<void> openConversation(ConversationModel conversation) async {
    selectedConversation.value = conversation;
    selectedRecipient.value = _recipientFromConversation(conversation);
    _messageSubscription?.cancel();
    _messageSubscription = _messagingService
        .streamMessages(conversation.id)
        .listen((items) {
      messages.assignAll(items);
      Future.delayed(const Duration(milliseconds: 120), () {
        if (messageScrollController.hasClients) {
          messageScrollController.animateTo(
            messageScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOut,
          );
        }
      });
    });

    final uid = currentUserId;
    if (uid != null) {
      await _messagingService.markConversationRead(conversation.id, uid);
    }
  }

  Future<void> selectRecipient(MessagingRecipient? recipient) async {
    selectedRecipient.value = recipient;
    if (recipient == null) {
      return;
    }

    final uid = currentUserId;
    if (uid == null) {
      return;
    }

    final conversation = await _messagingService.getOrCreateConversation(
      currentUserId: uid,
      currentUserDetails: _currentUserDetails,
      otherUserId: recipient.id,
      otherUserDetails: <String, dynamic>{
        'name': recipient.name,
        'role': recipient.role,
        if (recipient.subtitle != null) 'subtitle': recipient.subtitle,
      },
    );
    await openConversation(conversation);
  }

  Future<void> sendCurrentMessage() async {
    final uid = currentUserId;
    final recipient = selectedRecipient.value;
    var conversation = selectedConversation.value;
    final text = messageController.text.trim();

    if (uid == null || recipient == null || text.isEmpty) {
      return;
    }

    isSending.value = true;
    try {
      if (conversation == null ||
          !conversation.participants.contains(recipient.id)) {
        conversation = await _messagingService.getOrCreateConversation(
          currentUserId: uid,
          currentUserDetails: _currentUserDetails,
          otherUserId: recipient.id,
          otherUserDetails: <String, dynamic>{
            'name': recipient.name,
            'role': recipient.role,
            if (recipient.subtitle != null) 'subtitle': recipient.subtitle,
          },
        );
        selectedConversation.value = conversation;
      }

      final updatedDetails =
          Map<String, dynamic>.from(conversation.participantDetails);
      updatedDetails[uid] = _currentUserDetails;
      updatedDetails[recipient.id] = <String, dynamic>{
        'name': recipient.name,
        'role': recipient.role,
        if (recipient.subtitle != null) 'subtitle': recipient.subtitle,
      };

      await _messagingService.sendMessage(
        conversation: conversation,
        senderId: uid,
        senderName: currentUserName.value,
        senderRole: currentRole.value ?? 'user',
        text: text,
        participantDetails: updatedDetails,
      );
      messageController.clear();
      draftText.value = '';
    } catch (error) {
      Get.snackbar(
        'Send message failed',
        error.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSending.value = false;
    }
  }
}
