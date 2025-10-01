import 'dart:async';
import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/auth_service.dart';
import '../../../data/models/conversation_model.dart';
import '../../../data/models/message_model.dart';
import '../../../data/models/messaging_contact.dart';
import '../services/messaging_service.dart';

enum MessagingViewMode {
  conversationList,
  conversationThread,
}

class MessagingController extends GetxController {
  MessagingController();

  final MessagingService _messagingService = Get.find();
  final AuthService _authService = Get.find();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final RxList<MessageModel> messages = <MessageModel>[].obs;
  final RxBool isMessagesLoading = false.obs;
  final RxBool isSending = false.obs;
  final RxnString messageError = RxnString();

  final RxList<ConversationModel> conversations = <ConversationModel>[].obs;
  final RxList<ConversationModel> filteredConversations =
      <ConversationModel>[].obs;
  final RxBool isConversationsLoading = false.obs;
  final RxnString conversationsError = RxnString();

  final Rxn<ConversationModel> activeConversation = Rxn<ConversationModel>();
  final Rx<MessagingViewMode> activeView =
      MessagingViewMode.conversationList.obs;
  final RxBool isContactsLoading = false.obs;
  final RxList<MessagingContact> contacts = <MessagingContact>[].obs;
  final RxnString contactsError = RxnString();

  final TextEditingController composerController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  StreamSubscription<MessageModel>? _messageSubscription;
  StreamSubscription<List<ConversationModel>>? _conversationsSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _conversationMessagesSubscription;
  String? _pendingConversationId;

  @override
  void onInit() {
    super.onInit();
    _pendingConversationId = _resolveConversationId();
    searchController.addListener(_applyConversationFilter);
    _subscribeToIncomingMessages();
    _listenToConversations();
    Future.microtask(() async {
      await _loadConversations();
      await _initializeActiveConversation();
      await _loadContacts();
    });
  }

  @override
  void onClose() {
    _messageSubscription?.cancel();
    _conversationsSubscription?.cancel();
    _conversationMessagesSubscription?.cancel();
    composerController.dispose();
    searchController.dispose();
    super.onClose();
  }

  String? _resolveConversationId() {
    final parameters = Get.parameters;
    final parameterValue = parameters['conversationId'];
    if (parameterValue != null && parameterValue.isNotEmpty) {
      return parameterValue;
    }

    final args = Get.arguments;
    if (args is Map && args['conversationId'] is String) {
      final argumentValue = args['conversationId'] as String;
      if (argumentValue.isNotEmpty) {
        return argumentValue;
      }
    }

    return null;
  }

  Future<void> _initializeActiveConversation() async {
    if (_pendingConversationId == null) {
      return;
    }

    final conversationId = _pendingConversationId!;
    _pendingConversationId = null;
    try {
      final existing = conversations
          .firstWhereOrNull((item) => item.id == conversationId);
      if (existing != null) {
        selectConversation(existing);
        return;
      }

      final fetched =
          await _messagingService.fetchConversation(conversationId);
      if (fetched != null) {
        conversations.add(fetched);
        conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        _applyConversationFilter();
        selectConversation(fetched);
      }
    } catch (error) {
      messageError.value = error.toString();
    }
  }

  Future<void> _loadConversations() async {
    try {
      isConversationsLoading.value = true;
      conversationsError.value = null;
      final items = await _messagingService.fetchConversations();
      conversations.assignAll(items);
      final activeId = activeConversation.value?.id;
      if (activeId != null) {
        final updatedActive =
            conversations.firstWhereOrNull((item) => item.id == activeId);
        if (updatedActive != null) {
          activeConversation.value = updatedActive;
        }
      }
      _applyConversationFilter();
    } catch (error) {
      conversationsError.value = error.toString();
      filteredConversations.clear();
    } finally {
      isConversationsLoading.value = false;
    }
  }

  Future<void> _loadContacts() async {
    final user = _authService.currentUser;
    if (user == null) {
      contacts.clear();
      return;
    }

    final role = _authService.currentRole;
    if (role == null) {
      contacts.clear();
      return;
    }

    try {
      isContactsLoading.value = true;
      contactsError.value = null;
      final classIds = await _resolveClassIds(role, user.uid);
      final results = await _messagingService.fetchAllowedContacts(
        userRole: role,
        userId: user.uid,
        classIds: classIds,
      );
      final filtered = _filterContactsForRole(results, role, classIds);
      contacts.assignAll(filtered);
    } catch (error) {
      contactsError.value = error.toString();
      contacts.clear();
    } finally {
      isContactsLoading.value = false;
    }
  }

  void _subscribeToIncomingMessages() {
    _messageSubscription = _messagingService.messageStream.listen((message) {
      final currentUserId = _authService.currentUser?.uid;
      final existingConversation = conversations
          .firstWhereOrNull((item) => item.id == message.conversationId);

      final isMine = currentUserId != null && message.senderId == currentUserId;
      final shouldIncrementUnread =
          !isMine && activeConversation.value?.id != message.conversationId;

      if (existingConversation != null) {
        final updatedConversation = existingConversation.copyWith(
          lastMessagePreview: message.content,
          updatedAt: message.sentAt,
          unreadCount: shouldIncrementUnread
              ? existingConversation.unreadCount + 1
              : 0,
        );
        _replaceConversation(existingConversation, updatedConversation);
      } else {
        final placeholder = ConversationModel(
          id: message.conversationId,
          title: message.senderName,
          lastMessagePreview: message.content,
          updatedAt: message.sentAt,
          participants: <ConversationParticipant>[],
          unreadCount: shouldIncrementUnread ? 1 : 0,
        );
        conversations.insert(0, placeholder);
        _applyConversationFilter();
      }

      if (activeConversation.value?.id != message.conversationId) {
        return;
      }

      final existingById = messages.any(
        (item) => item.id.isNotEmpty && item.id == message.id,
      );
      if (existingById) {
        return;
      }

      if (message.id.isEmpty) {
        final duplicate = messages.any((item) {
          return item.senderId == message.senderId &&
              item.content == message.content &&
              item.sentAt == message.sentAt;
        });
        if (duplicate) {
          return;
        }
      }

      messages.add(message);
      messages.sort((a, b) => a.sentAt.compareTo(b.sentAt));

      if (!isMine) {
        unawaited(_markConversationAsRead(message.conversationId));
      }
    });
  }

  void _listenToConversations() {
    _conversationsSubscription?.cancel();
    _conversationsSubscription = _messagingService.watchConversations().listen(
      (items) {
        conversationsError.value = null;
        conversations.assignAll(items);
        final activeId = activeConversation.value?.id;
        if (activeId != null) {
          final updatedActive =
              items.firstWhereOrNull((conversation) => conversation.id == activeId);
          if (updatedActive != null) {
            activeConversation.value = updatedActive;
          }
        }
        _applyConversationFilter();
      },
      onError: (error) {
        conversationsError.value = error.toString();
      },
    );
  }

  Future<void> refreshConversations() async {
    await _loadConversations();
  }

  Future<void> refreshMessages() async {
    final conversationId = activeConversation.value?.id;
    if (conversationId == null) {
      return;
    }
    await _loadMessagesForConversation(conversationId);
  }

  Future<void> refreshContacts() async {
    await _loadContacts();
  }

  Future<void> _loadMessagesForConversation(String conversationId) async {
    try {
      isMessagesLoading.value = true;
      messageError.value = null;
      final items = await _messagingService.fetchMessages(conversationId);
      items.sort((a, b) => a.sentAt.compareTo(b.sentAt));
      messages.assignAll(items);
      _listenToConversationMessages(conversationId);
      await _markConversationAsRead(conversationId);
    } catch (error) {
      messageError.value = error.toString();
      messages.clear();
    } finally {
      isMessagesLoading.value = false;
    }
  }

  Future<void> sendCurrentMessage() async {
    final content = composerController.text.trim();
    if (content.isEmpty) {
      return;
    }

    final user = _authService.currentUser;
    if (user == null) {
      messageError.value = 'You must be signed in to send messages.';
      return;
    }

    final conversationId = activeConversation.value?.id;
    if (conversationId == null) {
      messageError.value = 'Select a conversation before sending messages.';
      return;
    }

    try {
      isSending.value = true;
      messageError.value = null;
      final message = await _messagingService.sendMessage(
        conversationId: conversationId,
        senderId: user.uid,
        senderName: user.displayName ?? user.email ?? 'User',
        content: content,
        participants: activeConversation.value?.participants,
      );
      composerController.clear();
      final alreadyExists = messages.any((item) => item.id == message.id);
      if (!alreadyExists) {
        messages
          ..add(message)
          ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
      }
      _updateConversationUnreadLocally(conversationId, 0);
      await refreshConversations();
    } catch (error) {
      messageError.value = error.toString();
    } finally {
      isSending.value = false;
    }
  }

  bool isOwnMessage(MessageModel message) {
    final user = _authService.currentUser;
    if (user == null) {
      return false;
    }
    return message.senderId == user.uid;
  }

  bool get isTeacher =>
      (_authService.currentRole ?? '').toLowerCase() == 'teacher';

  bool get shouldShowAdministrationAction {
    if (!isTeacher) {
      return false;
    }
    return contacts.any((contact) => contact.role.toLowerCase() == 'admin');
  }

  void showConversationListView() {
    activeView.value = MessagingViewMode.conversationList;
  }

  Future<void> startConversationWithAdministration() async {
    final adminContact = contacts.firstWhereOrNull(
      (contact) => contact.role.toLowerCase() == 'admin',
    );
    if (adminContact == null) {
      messageError.value =
          'No administration contact is currently available.';
      return;
    }
    await startConversationWithContact(adminContact);
  }

  void selectConversation(ConversationModel conversation) {
    activeConversation.value = conversation;
    activeView.value = MessagingViewMode.conversationThread;
    _loadMessagesForConversation(conversation.id);
  }

  void clearActiveConversation() {
    activeView.value = MessagingViewMode.conversationList;
    activeConversation.value = null;
    _conversationMessagesSubscription?.cancel();
    _conversationMessagesSubscription = null;
    messages.clear();
    composerController.clear();
    messageError.value = null;
    isMessagesLoading.value = false;
  }

  void _applyConversationFilter() {
    final query = searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      filteredConversations.assignAll(conversations);
      return;
    }

    final results = conversations.where((conversation) {
      final titleMatches = conversation.title.toLowerCase().contains(query);
      final participantMatches = conversation.participants.any(
        (participant) => participant.name.toLowerCase().contains(query),
      );
      final lastMessageMatches =
          conversation.lastMessagePreview.toLowerCase().contains(query);
      return titleMatches || participantMatches || lastMessageMatches;
    }).toList();

    filteredConversations.assignAll(results);
  }

  Future<void> startConversationWithContact(MessagingContact contact) async {
    try {
      isMessagesLoading.value = true;
      messageError.value = null;
      final conversation =
          await _messagingService.ensureConversationWithContact(contact);

      final existingIndex =
          conversations.indexWhere((item) => item.id == conversation.id);
      if (existingIndex >= 0) {
        conversations[existingIndex] = conversation;
      } else {
        conversations.insert(0, conversation);
      }
      _applyConversationFilter();
      selectConversation(conversation);
    } catch (error) {
      messageError.value = error.toString();
    } finally {
      isMessagesLoading.value = false;
    }
  }

  Future<List<String>> _resolveClassIds(String role, String userId) async {
    final normalizedRole = role.toLowerCase();
    if (normalizedRole == 'teacher') {
      final snapshot = await _firestore.collection('classes').get();
      final ids = snapshot.docs.where((doc) {
        final data = doc.data();
        final teacherSubjects =
            (data['teacherSubjects'] as Map<String, dynamic>?) ??
                <String, dynamic>{};
        return teacherSubjects.values.contains(userId);
      }).map((doc) => doc.id);
      return ids.toList();
    }

    if (normalizedRole == 'parent') {
      final snapshot = await _firestore
          .collection('children')
          .where('parentId', isEqualTo: userId)
          .get();
      final ids = snapshot.docs
          .map((doc) => (doc.data()['classId'] as String?) ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
      return ids.toList();
    }

    return <String>[];
  }

  List<MessagingContact> _filterContactsForRole(
    List<MessagingContact> items,
    String role,
    List<String> myClassIds,
  ) {
    switch (role.toLowerCase()) {
      case 'teacher':
        final myClasses = myClassIds.toSet();
        return items.where((contact) {
          final contactRole = contact.role.toLowerCase();
          if (contactRole == 'admin' || contactRole == 'teacher') {
            return true;
          }
          if (contactRole == 'parent') {
            if (myClasses.isEmpty) {
              return false;
            }
            return contact.classIds
                .any((classId) => myClasses.contains(classId));
          }
          return false;
        }).toList();
      case 'parent':
        final myClasses = myClassIds.toSet();
        return items.where((contact) {
          final contactRole = contact.role.toLowerCase();
          if (contactRole == 'admin') {
            return true;
          }
          if (contactRole == 'teacher') {
            if (myClasses.isEmpty) {
              return false;
            }
            return contact.classIds
                .any((classId) => myClasses.contains(classId));
          }
          return false;
        }).toList();
      default:
        return items;
    }
  }

  Future<void> _markConversationAsRead(String conversationId) async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      return;
    }

    final unreadMessages = messages.where((message) {
      return message.senderId != userId && !message.readBy.contains(userId);
    }).toList();

    final messageIds = unreadMessages
        .map((message) => message.id)
        .where((id) => id.isNotEmpty)
        .toList();

    try {
      await _messagingService.markConversationAsRead(
        conversationId: conversationId,
        userId: userId,
        messageIds: messageIds,
      );

      for (final message in unreadMessages) {
        final index = messages.indexOf(message);
        if (index >= 0) {
          final updated = message.copyWith(
            readBy: {...message.readBy, userId},
          );
          messages[index] = updated;
        }
      }

      _updateConversationUnreadLocally(conversationId, 0);
    } catch (error) {
      debugPrint('Failed to update read status: $error');
    }
  }

  void _updateConversationUnreadLocally(
    String conversationId,
    int unreadCount,
  ) {
    final index = conversations.indexWhere((item) => item.id == conversationId);
    if (index >= 0) {
      conversations[index] =
          conversations[index].copyWith(unreadCount: unreadCount);
    }

    final active = activeConversation.value;
    if (active?.id == conversationId) {
      activeConversation.value = active?.copyWith(unreadCount: unreadCount);
    }

    _applyConversationFilter();
  }

  void _replaceConversation(
    ConversationModel original,
    ConversationModel replacement,
  ) {
    final index = conversations.indexOf(original);
    if (index >= 0) {
      conversations[index] = replacement;
    }

    conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    if (activeConversation.value?.id == replacement.id) {
      activeConversation.value = replacement;
    }

    _applyConversationFilter();
  }

  String resolveConversationTitle(ConversationModel conversation) {
    final others = _otherParticipants(conversation);
    if (others.isNotEmpty) {
      final names = others
          .map((participant) {
            final contact = _findContact(
              participant.userId.isNotEmpty
                  ? participant.userId
                  : participant.id,
            );
            final candidate = contact?.name ?? participant.name;
            return _prettifyName(candidate);
          })
          .where((name) => name.isNotEmpty)
          .toList();
      if (names.isNotEmpty) {
        return _formatList(names);
      }
    }
    final fallback = _prettifyName(conversation.title);
    if (fallback.isNotEmpty) {
      return fallback;
    }
    return 'Conversation';
  }

  String? resolveConversationContext(ConversationModel conversation) {
    final others = _otherParticipants(conversation);
    if (others.isEmpty) {
      return null;
    }
    if (others.length == 1) {
      final participant = others.first;
      final contact = _findContact(
        participant.userId.isNotEmpty ? participant.userId : participant.id,
      );
      final relationship = contact?.relationship?.trim();
      if (relationship != null && relationship.isNotEmpty) {
        return relationship;
      }
      final roleLabel = _prettifyRole(participant.role);
      return roleLabel.isEmpty ? null : roleLabel;
    }

    final labels = others
        .map((participant) => _prettifyRole(participant.role))
        .where((label) => label.isNotEmpty)
        .toSet()
        .toList();
    if (labels.isEmpty) {
      return null;
    }
    return _formatList(labels);
  }

  String resolveConversationParticipantsLabel(
    ConversationModel conversation,
  ) {
    final currentUserId = _authService.currentUser?.uid;
    final names = conversation.participants.map((participant) {
      final participantUserId =
          participant.userId.isNotEmpty ? participant.userId : participant.id;
      if (participantUserId == currentUserId) {
        return 'You';
      }
      final contact = _findContact(participantUserId);
      final candidate = contact?.name ?? participant.name;
      return _prettifyName(candidate);
    }).where((name) => name.isNotEmpty).toList();
    return _formatList(names);
  }

  List<ConversationParticipant> _otherParticipants(
    ConversationModel conversation,
  ) {
    final currentUserId = _authService.currentUser?.uid;
    return conversation.participants.where((participant) {
      if (currentUserId == null) {
        return true;
      }
      final participantUserId =
          participant.userId.isNotEmpty ? participant.userId : participant.id;
      return participantUserId != currentUserId;
    }).toList();
  }

  MessagingContact? _findContact(String participantId) {
    return contacts.firstWhereOrNull(
      (contact) =>
          contact.id == participantId || contact.userId == participantId,
    );
  }

  String _prettifyName(String? value) {
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
      return words
          .map((word) =>
              word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
          .join(' ');
    }
    return raw;
  }

  String _prettifyRole(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) {
      return '';
    }
    return raw[0].toUpperCase() + raw.substring(1).toLowerCase();
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

  bool isMessageReadByOthers(MessageModel message) {
    final conversation = activeConversation.value;
    if (conversation == null) {
      return false;
    }

    final others = conversation.participants
        .map((participant) =>
            participant.userId.isNotEmpty ? participant.userId : participant.id)
        .where((id) => id != message.senderId)
        .toSet();

    if (others.isEmpty) {
      return false;
    }

    return others.every(message.readBy.contains);
  }

  bool isMessageUnread(MessageModel message) {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      return false;
    }

    if (message.senderId == userId) {
      return false;
    }

    return !message.readBy.contains(userId);
  }

  void _listenToConversationMessages(String conversationId) {
    _conversationMessagesSubscription?.cancel();
    _conversationMessagesSubscription = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('sentAt')
        .snapshots()
        .listen(
      (snapshot) {
        final mapped = snapshot.docs.map((doc) {
          final data = doc.data();
          final payload = <String, dynamic>{
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
        mapped.sort((a, b) => a.sentAt.compareTo(b.sentAt));
        messageError.value = null;
        messages.assignAll(mapped);
        unawaited(_markConversationAsRead(conversationId));
      },
      onError: (error) {
        messageError.value = 'Failed to load messages: $error';
      },
    );
  }
}
