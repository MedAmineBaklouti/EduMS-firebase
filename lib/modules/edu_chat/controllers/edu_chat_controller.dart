import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/services/auth_service.dart';
import '../models/edu_chat_exception.dart';
import '../models/edu_chat_message.dart';
import '../models/edu_chat_proxy_response.dart';
import '../services/edu_chat_service.dart';

class EduChatController extends GetxController {
  EduChatController({EduChatService? service, AuthService? authService})
      : _service = service ?? Get.find<EduChatService>(),
        _authService = authService ?? Get.find<AuthService>();

  final EduChatService _service;
  final AuthService _authService;

  final RxList<EduChatMessage> messages = <EduChatMessage>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isSending = false.obs;
  final RxnString loadError = RxnString();
  final RxString inputText = ''.obs;

  final TextEditingController composerController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  StreamSubscription<List<EduChatMessage>>? _messagesSubscription;
  String? _chatId;

  String? get currentUserId => _authService.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    composerController.addListener(() {
      inputText.value = composerController.text;
    });
    ever<List<EduChatMessage>>(messages, (_) => _scrollToBottom());
    Future.microtask(() => _initializeChat());
  }

  Future<void> _initializeChat() async {
    isLoading.value = true;
    loadError.value = null;

    final userId = currentUserId;
    if (userId == null) {
      isLoading.value = false;
      loadError.value = 'edu_chat_error_not_authenticated'.tr;
      return;
    }

    try {
      final chatId = await _service.ensureChatThread();
      _chatId = chatId;
      _messagesSubscription?.cancel();
      _messagesSubscription = _service.watchMessages(chatId).listen(
        (event) {
          messages.assignAll(event);
          isLoading.value = false;
        },
        onError: (error) {
          loadError.value = 'edu_chat_error_generic'.tr;
          isLoading.value = false;
        },
      );
    } on EduChatException catch (error) {
      _handleInitializationError(error);
    } catch (_) {
      loadError.value = 'edu_chat_error_generic'.tr;
    } finally {
      isLoading.value = false;
    }
  }

  void _handleInitializationError(EduChatException error) {
    switch (error.type) {
      case EduChatErrorType.unauthenticated:
        loadError.value = 'edu_chat_error_not_authenticated'.tr;
        break;
      case EduChatErrorType.network:
        loadError.value = 'edu_chat_error_network'.tr;
        break;
      case EduChatErrorType.rateLimited:
        loadError.value = 'edu_chat_error_rate_limited'.tr;
        break;
      default:
        loadError.value = 'edu_chat_error_generic'.tr;
    }
  }

  Future<void> retry() async {
    await _initializeChat();
  }

  Future<void> sendMessage() async {
    final chatId = _chatId;
    if (chatId == null) {
      await _initializeChat();
      if (_chatId == null) {
        return;
      }
    }

    final text = composerController.text.trim();
    if (text.isEmpty || isSending.value) {
      return;
    }

    composerController.clear();
    inputText.value = '';

    final targetChatId = _chatId!;

    try {
      isSending.value = true;
      await _service.addUserMessage(chatId: targetChatId, content: text);

      final EduChatProxyResponse response =
          await _service.requestEducationalAssistant(prompt: text);

      if (response.isEmpty) {
        await _service.addSystemMessage(
          chatId: targetChatId,
          content: 'edu_chat_system_error_message'.tr,
        );
        Get.snackbar(
          'edu_chat_title'.tr,
          'edu_chat_error_generic'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      await _service.addModelMessage(chatId: targetChatId, response: response);

      if (response.refused == true) {
        Get.snackbar('edu_chat_title'.tr, response.text,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 4));
      }
    } on EduChatException catch (error) {
      await _handleSendError(error, targetChatId);
    } catch (error) {
      await _service.addSystemMessage(
        chatId: targetChatId,
        content: 'edu_chat_system_error_message'.tr,
      );
      Get.snackbar(
        'edu_chat_title'.tr,
        'edu_chat_error_generic'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSending.value = false;
    }
  }

  Future<void> sendSuggestion(String suggestion) async {
    if (isSending.value) {
      return;
    }
    if (loadError.value != null) {
      return;
    }
    composerController
      ..text = suggestion
      ..selection = TextSelection.collapsed(offset: suggestion.length);
    inputText.value = suggestion;
    await sendMessage();
  }

  Future<void> _handleSendError(
    EduChatException error,
    String chatId,
  ) async {
    String message;
    String systemMessage;

    switch (error.type) {
      case EduChatErrorType.rateLimited:
        message = 'edu_chat_error_rate_limited'.tr;
        systemMessage = 'edu_chat_rate_limited_message'.tr;
        break;
      case EduChatErrorType.network:
        message = 'edu_chat_error_network'.tr;
        systemMessage = 'edu_chat_system_error_message'.tr;
        break;
      case EduChatErrorType.unauthenticated:
        message = 'edu_chat_error_not_authenticated'.tr;
        systemMessage = 'edu_chat_system_error_message'.tr;
        break;
      default:
        message = 'edu_chat_error_generic'.tr;
        systemMessage = 'edu_chat_system_error_message'.tr;
    }

    await _service.addSystemMessage(chatId: chatId, content: systemMessage);
    Get.snackbar(
      'edu_chat_title'.tr,
      message,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar(
      'edu_chat_title'.tr,
      'edu_chat_copy_toast'.tr,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  void _scrollToBottom() {
    if (!scrollController.hasClients) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) {
        return;
      }
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void onClose() {
    _messagesSubscription?.cancel();
    composerController.dispose();
    scrollController.dispose();
    super.onClose();
  }
}
