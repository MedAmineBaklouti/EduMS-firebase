import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../../../app/routes/app_pages.dart';
import '../models/edu_chat_message.dart';
import '../services/edu_chat_service.dart';

class EduChatController extends GetxController {
  EduChatController(this._service);

  static const systemIntroMessage =
      'Ask me about educational topics only… Try math, science, history, languages, programming, study skills, exam prep, and more.';
  static const _networkIssueMessage =
      'Network issue, please try again.';
  static const _genericErrorMessage =
      'Something went wrong. Please try again later.';

  final EduChatService _service;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final RxList<EduChatMessage> messages = <EduChatMessage>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isSending = false.obs;
  final RxnString errorMessage = RxnString();

  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  StreamSubscription<List<EduChatMessage>>? _messagesSub;
  String? _chatId;

  String? get chatId => _chatId;

  @override
  void onInit() {
    super.onInit();
    _loadChat();
  }

  Future<void> reloadChat() async {
    await _loadChat(reset: true);
  }

  Future<void> _loadChat({bool reset = false}) async {
    if (reset) {
      isLoading.value = true;
      errorMessage.value = null;
      await _messagesSub?.cancel();
      messages.clear();
    }
    final user = _auth.currentUser;
    if (user == null) {
      _redirectToLogin();
      return;
    }

    try {
      final chat = await _service.ensureChatThread(user.uid);
      _chatId = chat;
      _subscribeToMessages(user.uid, chat);
    } catch (error, stackTrace) {
      Get.log('EduChat initialization failed: $error');
      Get.log(stackTrace.toString());
      errorMessage.value = _genericErrorMessage;
    } finally {
      isLoading.value = false;
    }
  }

  void _subscribeToMessages(String uid, String chatId) {
    _messagesSub?.cancel();
    _messagesSub = _service
        .watchMessages(uid: uid, chatId: chatId)
        .listen(messages.assignAll, onError: (Object error) {
      Get.log('EduChat message stream error: $error');
      errorMessage.value = _genericErrorMessage;
    });
  }

  Future<void> sendMessage() async {
    if (isSending.value) {
      return;
    }
    final text = textController.text.trim();
    if (text.isEmpty) {
      return;
    }
    final user = _auth.currentUser;
    final chat = _chatId;
    if (user == null || chat == null) {
      _redirectToLogin();
      return;
    }

    textController.clear();
    isSending.value = true;
    try {
      final response = await _service.sendMessage(
        uid: user.uid,
        chatId: chat,
        message: text,
      );

      if (response.throttled) {
        Get.snackbar(
          'Educational Assistant',
          response.text,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4),
        );
      } else if (response.refused && response.text.isNotEmpty) {
        Get.snackbar(
          'Educational Assistant',
          response.text,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4),
        );
      }

      if (!response.persisted && response.text.isNotEmpty) {
        await _service.addSystemMessage(
          uid: user.uid,
          chatId: chat,
          content: response.text,
        );
      }
    } on FirebaseFunctionsException catch (error) {
      Get.log('EduChat send message error: $error');
      Get.snackbar(
        'Educational Assistant',
        _networkIssueMessage,
        snackPosition: SnackPosition.BOTTOM,
      );
      await _addLocalErrorMessage(_networkIssueMessage);
    } catch (error, stackTrace) {
      Get.log('EduChat unexpected error: $error');
      Get.log(stackTrace.toString());
      Get.snackbar(
        'Educational Assistant',
        _genericErrorMessage,
        snackPosition: SnackPosition.BOTTOM,
      );
      await _addLocalErrorMessage(_genericErrorMessage);
    } finally {
      isSending.value = false;
    }
  }

  Future<void> _addLocalErrorMessage(String message) async {
    final user = _auth.currentUser;
    final chat = _chatId;
    if (user == null || chat == null) {
      return;
    }
    await _service.addSystemMessage(
      uid: user.uid,
      chatId: chat,
      content: message,
    );
  }

  void _redirectToLogin() {
    Get.offAllNamed(AppPages.LOGIN);
  }

  @override
  void onClose() {
    _messagesSub?.cancel();
    textController.dispose();
    scrollController.dispose();
    super.onClose();
  }
}
