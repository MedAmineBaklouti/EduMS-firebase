import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/auth_service.dart';
import '../../../data/models/message_model.dart';
import '../services/messaging_service.dart';

class MessagingController extends GetxController {
  MessagingController();

  final MessagingService _messagingService = Get.find();
  final AuthService _authService = Get.find();

  final RxList<MessageModel> messages = <MessageModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSending = false.obs;
  final RxnString error = RxnString();

  final TextEditingController composerController = TextEditingController();

  StreamSubscription<MessageModel>? _messageSubscription;
  late final String conversationId;

  @override
  void onInit() {
    super.onInit();
    conversationId = _resolveConversationId();
    _subscribeToIncomingMessages();
    _loadInitialMessages();
  }

  @override
  void onClose() {
    _messageSubscription?.cancel();
    composerController.dispose();
    super.onClose();
  }

  String _resolveConversationId() {
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

    return 'general';
  }

  Future<void> _loadInitialMessages() async {
    try {
      isLoading.value = true;
      error.value = null;
      final items = await _messagingService.fetchMessages(conversationId);
      items.sort((a, b) => a.sentAt.compareTo(b.sentAt));
      messages.assignAll(items);
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  void _subscribeToIncomingMessages() {
    _messageSubscription = _messagingService.messageStream.listen((message) {
      if (message.conversationId != conversationId) {
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
    });
  }

  Future<void> refreshMessages() async {
    await _loadInitialMessages();
  }

  Future<void> sendCurrentMessage() async {
    final content = composerController.text.trim();
    if (content.isEmpty) {
      return;
    }

    final user = _authService.currentUser;
    if (user == null) {
      error.value = 'You must be signed in to send messages.';
      return;
    }

    try {
      isSending.value = true;
      error.value = null;
      await _messagingService.sendMessage(
        conversationId: conversationId,
        senderId: user.uid,
        senderName: user.displayName ?? user.email ?? 'User',
        content: content,
      );
      composerController.clear();
    } catch (e) {
      error.value = e.toString();
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
}
