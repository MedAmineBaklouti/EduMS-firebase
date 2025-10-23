import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:edums/modules/auth/service/auth_service.dart';
import '../models/edu_chat_exception.dart';
import '../models/edu_chat_message.dart';
import '../models/edu_chat_proxy_response.dart';
import '../models/edu_chat_thread.dart';
import '../services/edu_chat_service.dart';

enum EduChatViewMode {
  threadList,
  threadConversation,
}

class EduChatController extends GetxController {
  EduChatController({EduChatService? service, AuthService? authService})
      : _service = service ?? Get.find<EduChatService>(),
        _authService = authService ?? Get.find<AuthService>();

  final EduChatService _service;
  final AuthService _authService;

  final RxList<EduChatMessage> messages = <EduChatMessage>[].obs;
  final RxList<EduChatThread> threads = <EduChatThread>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isSending = false.obs;
  final RxBool isAwaitingResponse = false.obs;
  final RxBool isDraftingNewThread = false.obs;
  final RxnString loadError = RxnString();
  final RxString inputText = ''.obs;
  final RxnString activeThreadId = RxnString();
  final Rx<EduChatViewMode> activeView = EduChatViewMode.threadList.obs;

  final TextEditingController composerController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  StreamSubscription<List<EduChatMessage>>? _messagesSubscription;
  StreamSubscription<List<EduChatThread>>? _threadsSubscription;
  String? _chatId;

  String? get currentUserId => _authService.currentUser?.uid;
  EduChatThread? get activeThread {
    final id = activeThreadId.value;
    if (id == null) {
      return null;
    }
    return threads.firstWhereOrNull((thread) => thread.id == id);
  }

  String resolveThreadTitle(EduChatThread thread) {
    final title = thread.title?.trim();
    if (title != null && title.isNotEmpty) {
      return title;
    }
    final index = threads.indexWhere((item) => item.id == thread.id);
    final displayIndex = index >= 0 ? index + 1 : threads.length + 1;
    return 'edu_chat_conversation_default_title'
        .trParams({'index': '$displayIndex'});
  }

  String? formatThreadUpdatedAt(EduChatThread thread) {
    final timestamp = thread.updatedAt ?? thread.createdAt;
    if (timestamp == null) {
      return null;
    }
    final localeTag = Get.locale?.toLanguageTag();
    final formatter = DateFormat.yMMMd(localeTag).add_jm();
    return formatter.format(timestamp.toLocal());
  }

  void showThreadList() {
    activeView.value = EduChatViewMode.threadList;
    _messagesSubscription?.cancel();
    _messagesSubscription = null;
    _chatId = null;
    activeThreadId.value = null;
    messages.clear();
    composerController.clear();
    inputText.value = '';
    isLoading.value = false;
    isDraftingNewThread.value = false;
    isAwaitingResponse.value = false;
  }

  @override
  void onInit() {
    super.onInit();
    composerController.addListener(() {
      inputText.value = composerController.text;
    });
    ever<List<EduChatMessage>>(messages, (_) => _scrollToBottom());
    Future.microtask(() => _startWatchingThreads());
  }

  Future<void> _startWatchingThreads() async {
    isLoading.value = true;
    loadError.value = null;

    final userId = currentUserId;
    if (userId == null) {
      isLoading.value = false;
      loadError.value = 'edu_chat_error_not_authenticated'.tr;
      return;
    }

    try {
      _threadsSubscription?.cancel();
      _threadsSubscription = _service.watchChatThreads().listen(
            (items) async {
          threads.assignAll(items);
          loadError.value = null;

          if (items.isEmpty) {
            if (activeView.value == EduChatViewMode.threadConversation &&
                !isDraftingNewThread.value) {
              showThreadList();
            } else {
              isLoading.value = false;
            }
            return;
          }

          final current = activeThreadId.value;
          if (current != null) {
            final exists =
            items.any((thread) => thread.id == current);
            if (!exists) {
              showThreadList();
            } else if (_chatId == null &&
                activeView.value == EduChatViewMode.threadConversation) {
              await _subscribeToMessages(current);
              return;
            }
          }

          if (activeView.value == EduChatViewMode.threadList) {
            isLoading.value = false;
          }
        },
        onError: (error) {
          print('❌ Threads subscription error: $error');
          loadError.value = 'edu_chat_error_generic'.tr;
          if (activeView.value == EduChatViewMode.threadList) {
            isLoading.value = false;
          }
        },
        cancelOnError: false,
      );
    } on EduChatException catch (error) {
      print('❌ Thread initialization error: ${error.message}');
      _handleInitializationError(error);
      isLoading.value = false;
    } catch (error, stackTrace) {
      print('❌ Unexpected thread error: $error');
      print('📋 Stack trace: $stackTrace');
      loadError.value = 'edu_chat_error_generic'.tr;
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
    print('🔄 Retrying initialization...');
    await _startWatchingThreads();
  }

  Future<void> sendMessage() async {
    if (!await _ensureActiveThread()) {
      print('❌ No active thread available');
      return;
    }

    final text = composerController.text.trim();
    if (text.isEmpty || isSending.value) {
      print('❌ Cannot send - empty text or already sending');
      return;
    }

    composerController.clear();
    inputText.value = '';

    final targetChatId = _chatId!;

    try {
      isSending.value = true;
      isAwaitingResponse.value = true;
      print('💾 Saving user message to Firestore...');
      await _service.addUserMessage(chatId: targetChatId, content: text);

      print('🔄 Sending request to Gemini...');
      final EduChatProxyResponse response =
      await _service.requestEducationalAssistant(prompt: text);
      print('✅ Gemini response received: ${response.text}');

      if (response.isEmpty) {
        print('❌ Empty response from Gemini');
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

      print('💾 Saving model response to Firestore...');
      await _service.addModelMessage(chatId: targetChatId, response: response);

      if (response.refused == true) {
        print('⚠️ Model refused to answer, message stored without snackbar');
      }
    } on EduChatException catch (error) {
      print('❌ EduChatException: ${error.type} - ${error.message}');
      await _handleSendError(error, targetChatId);
    } catch (error, stackTrace) {
      print('❌ Unexpected error in sendMessage: $error');
      print('📋 Stack trace: $stackTrace');
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
      isAwaitingResponse.value = false;
    }
  }

  Future<void> sendSuggestion(String suggestion) async {
    if (isSending.value) {
      print('❌ Already sending, ignoring suggestion');
      return;
    }
    if (loadError.value != null) {
      print('❌ Load error present, ignoring suggestion');
      return;
    }
    print('💡 Using suggestion: $suggestion');
    composerController
      ..text = suggestion
      ..selection = TextSelection.collapsed(offset: suggestion.length);
    inputText.value = suggestion;
    await sendMessage();
  }

  Future<void> startNewChat() async {
    if (isDraftingNewThread.value) {
      activeView.value = EduChatViewMode.threadConversation;
      return;
    }

    print('🆕 Preparing new chat draft...');
    isDraftingNewThread.value = true;
    activeView.value = EduChatViewMode.threadConversation;
    _messagesSubscription?.cancel();
    _messagesSubscription = null;
    _chatId = null;
    activeThreadId.value = null;
    messages.clear();
    composerController.clear();
    inputText.value = '';
    isLoading.value = false;
    loadError.value = null;
    isAwaitingResponse.value = false;
  }

  Future<bool> deleteThread(EduChatThread thread) async {
    final threadId = thread.id;
    final wasActive = activeThreadId.value == threadId;
    final index = threads.indexWhere((item) => item.id == threadId);
    EduChatThread? removedThread;
    if (index >= 0) {
      removedThread = threads.removeAt(index);
    }

    try {
      print('🗑️ Deleting thread: $threadId');
      await _service.deleteChatThread(threadId);
      if (wasActive) {
        showThreadList();
      }
      Get.snackbar(
        'edu_chat_title'.tr,
        'edu_chat_delete_success'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } on EduChatException catch (error) {
      print('❌ Error deleting thread: ${error.message}');
      _restoreThreadAfterDeletionFailure(
        removedThread: removedThread,
        index: index,
        wasActive: wasActive,
      );
      _showThreadDeletionError(error);
    } catch (error, stackTrace) {
      print('❌ Unexpected error deleting thread: $error');
      print('📋 Stack trace: $stackTrace');
      _restoreThreadAfterDeletionFailure(
        removedThread: removedThread,
        index: index,
        wasActive: wasActive,
      );
      _showThreadDeletionError();
    }

    return false;
  }

  Future<void> selectThread(String chatId) async {
    print('🎯 Selecting thread: $chatId');
    await _selectThread(chatId);
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

  Future<String?> _createInitialThread({bool activate = true}) async {
    try {
      print('🆕 Creating initial thread...');
      final chatId = await _service.createChatThread();
      if (activate) {
        await _selectThread(chatId, force: true);
      }
      return chatId;
    } on EduChatException catch (error) {
      print('❌ Error creating initial thread: ${error.message}');
      _handleInitializationError(error);
      isLoading.value = false;
    } catch (error, stackTrace) {
      print('❌ Unexpected error creating initial thread: $error');
      print('📋 Stack trace: $stackTrace');
      loadError.value = 'edu_chat_error_generic'.tr;
      isLoading.value = false;
    }
    return null;
  }

  Future<void> _selectThread(String chatId, {bool force = false}) async {
    if (!force && _chatId == chatId) {
      print('ℹ️ Thread already selected: $chatId');
      return;
    }

    _chatId = chatId;
    activeThreadId.value = chatId;
    activeView.value = EduChatViewMode.threadConversation;
    isDraftingNewThread.value = false;
    isAwaitingResponse.value = false;
    await _subscribeToMessages(chatId);
  }

  Future<void> _subscribeToMessages(String chatId) async {
    isLoading.value = true;
    loadError.value = null;
    messages.clear();
    isAwaitingResponse.value = false;

    _messagesSubscription?.cancel();
    _messagesSubscription = _service.watchMessages(chatId).listen(
          (event) {
        print('📨 Received ${event.length} messages');
        messages.assignAll(event);
        isLoading.value = false;
      },
      onError: (error) {
        print('❌ Messages subscription error: $error');
        loadError.value = 'edu_chat_error_generic'.tr;
        isLoading.value = false;
      },
      cancelOnError: false,
    );
  }

  Future<bool> _ensureActiveThread() async {
    if (_chatId != null) {
      return true;
    }

    if (isDraftingNewThread.value) {
      await _createInitialThread();
      return _chatId != null;
    }

    final currentDraftId = activeThreadId.value;
    if (currentDraftId != null) {
      await _selectThread(currentDraftId, force: true);
      return _chatId != null;
    }

    if (threads.isNotEmpty) {
      await _selectThread(threads.first.id, force: true);
      return _chatId != null;
    }

    await _createInitialThread();
    return _chatId != null;
  }

  void _showThreadError([EduChatException? error]) {
    String message = 'edu_chat_error_generic'.tr;
    if (error != null) {
      switch (error.type) {
        case EduChatErrorType.unauthenticated:
          message = 'edu_chat_error_not_authenticated'.tr;
          break;
        case EduChatErrorType.network:
          message = 'edu_chat_error_network'.tr;
          break;
        case EduChatErrorType.rateLimited:
          message = 'edu_chat_error_rate_limited'.tr;
          break;
        default:
          message = 'edu_chat_error_generic'.tr;
      }
    }

    Get.snackbar(
      'edu_chat_title'.tr,
      message,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _showThreadDeletionError([EduChatException? error]) {
    String message = 'edu_chat_delete_error'.tr;
    if (error != null) {
      switch (error.type) {
        case EduChatErrorType.unauthenticated:
          message = 'edu_chat_error_not_authenticated'.tr;
          break;
        case EduChatErrorType.network:
          message = 'edu_chat_error_network'.tr;
          break;
        default:
          message = 'edu_chat_delete_error'.tr;
      }
    }

    Get.snackbar(
      'edu_chat_title'.tr,
      message,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _restoreThreadAfterDeletionFailure({
    EduChatThread? removedThread,
    required int index,
    required bool wasActive,
  }) {
    if (removedThread != null) {
      final targetIndex =
      index >= 0 && index <= threads.length ? index : threads.length;
      threads.insert(targetIndex, removedThread);
    } else {
      threads.refresh();
    }

    if (wasActive) {
      activeThreadId.value = removedThread?.id ?? activeThreadId.value;
      if (removedThread != null) {
        activeView.value = EduChatViewMode.threadConversation;
      }
    }
  }

  @override
  void onClose() {
    _messagesSubscription?.cancel();
    _threadsSubscription?.cancel();
    composerController.dispose();
    scrollController.dispose();
    super.onClose();
  }
}