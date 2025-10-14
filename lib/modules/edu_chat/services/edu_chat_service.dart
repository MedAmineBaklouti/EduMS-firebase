import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../models/edu_chat_exception.dart';
import '../models/edu_chat_message.dart';
import '../models/edu_chat_proxy_response.dart';
import '../models/edu_chat_thread.dart';

const String kEduChatProxyUrl = String.fromEnvironment(
  'EDU_CHAT_PROXY_URL',
  defaultValue: 'https://your-proxy-endpoint.example.com/edu-chat',
);

class EduChatService extends GetxService {
  EduChatService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 30),
                responseType: ResponseType.json,
              ),
            );

  final Dio _dio;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get _proxyUrl => kEduChatProxyUrl;
  bool get _isProxyConfigured =>
      _proxyUrl.isNotEmpty &&
      !_proxyUrl.contains('your-proxy-endpoint.example.com');

  CollectionReference<Map<String, dynamic>> _userChatsCollection(String uid) {
    return _firestore.collection('users').doc(uid).collection('eduChats');
  }

  Future<String> ensureChatThread() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const EduChatException(
        'User not authenticated',
        type: EduChatErrorType.unauthenticated,
      );
    }

    final chatsRef = _userChatsCollection(user.uid);
    final snapshot = await chatsRef.orderBy('updatedAt', descending: true).limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.id;
    }

    final docRef = chatsRef.doc();
    await docRef.set({
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Future<String> createChatThread({String? title}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const EduChatException(
        'User not authenticated',
        type: EduChatErrorType.unauthenticated,
      );
    }

    final docRef = _userChatsCollection(user.uid).doc();
    final sanitizedTitle = title?.trim();
    await docRef.set({
      if (sanitizedTitle?.isNotEmpty == true) 'title': sanitizedTitle,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Stream<List<EduChatThread>> watchChatThreads() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return _userChatsCollection(user.uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EduChatThread.fromSnapshot(doc))
            .toList());
  }

  Stream<List<EduChatMessage>> watchMessages(String chatId) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    final messagesRef =
        _userChatsCollection(user.uid).doc(chatId).collection('messages');
    return messagesRef
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EduChatMessage.fromSnapshot(doc))
            .toList());
  }

  Future<void> addUserMessage({
    required String chatId,
    required String content,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const EduChatException(
        'User not authenticated',
        type: EduChatErrorType.unauthenticated,
      );
    }

    final message = {
      'role': 'user',
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
    };

    final chatRef = _userChatsCollection(user.uid).doc(chatId);
    await chatRef.collection('messages').add(message);
    final preview = _buildMessagePreview(content);

    await chatRef.set(
      {
        'updatedAt': FieldValue.serverTimestamp(),
        if (preview.isNotEmpty) 'title': preview,
      },
      SetOptions(merge: true),
    );
  }

  Future<void> addModelMessage({
    required String chatId,
    required EduChatProxyResponse response,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const EduChatException(
        'User not authenticated',
        type: EduChatErrorType.unauthenticated,
      );
    }

    final message = {
      'role': 'model',
      'content': response.text,
      if (response.model != null) 'model': response.model,
      if (response.tokens != null) 'tokens': response.tokens,
      if (response.refused != null) 'refused': response.refused,
      'createdAt': FieldValue.serverTimestamp(),
    };

    final chatRef = _userChatsCollection(user.uid).doc(chatId);
    await chatRef.collection('messages').add(message);
    await chatRef.set(
      {
        'updatedAt': FieldValue.serverTimestamp(),
        if (response.model != null) 'lastModel': response.model,
      },
      SetOptions(merge: true),
    );
  }

  Future<void> addSystemMessage({
    required String chatId,
    required String content,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const EduChatException(
        'User not authenticated',
        type: EduChatErrorType.unauthenticated,
      );
    }

    final chatRef = _userChatsCollection(user.uid).doc(chatId);
    await chatRef.collection('messages').add({
      'role': 'system',
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await chatRef.set(
      {'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  Future<void> deleteChatThread(String chatId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const EduChatException(
        'User not authenticated',
        type: EduChatErrorType.unauthenticated,
      );
    }

    final chatRef = _userChatsCollection(user.uid).doc(chatId);
    final messagesRef = chatRef.collection('messages');

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

      await chatRef.delete();
    } on FirebaseException catch (error) {
      final code = error.code.toLowerCase();
      EduChatErrorType type = EduChatErrorType.unknown;
      if (code == 'permission-denied' || code == 'unauthenticated') {
        type = EduChatErrorType.unauthenticated;
      } else if (code == 'unavailable' ||
          code == 'deadline-exceeded' ||
          code == 'cancelled') {
        type = EduChatErrorType.network;
      }
      throw EduChatException(
        error.message ?? error.code,
        type: type,
      );
    } catch (error) {
      throw EduChatException(
        error.toString(),
        type: EduChatErrorType.unknown,
      );
    }
  }

  Future<EduChatProxyResponse> requestEducationalAssistant({
    required String prompt,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const EduChatException(
        'User not authenticated',
        type: EduChatErrorType.unauthenticated,
      );
    }

    final idToken = await user.getIdToken();
    if (idToken!.isEmpty) {
      throw const EduChatException(
        'Unable to retrieve ID token',
        type: EduChatErrorType.unauthenticated,
      );
    }

    if (!_isProxyConfigured) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      return _buildFallbackResponse(prompt);
    }

    try {
      final response = await _dio.post<dynamic>(
        _proxyUrl,
        data: {
          'prompt': prompt,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.data is! Map<String, dynamic>) {
        throw const EduChatException(
          'Invalid response shape',
          type: EduChatErrorType.invalidResponse,
        );
      }

      return EduChatProxyResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      if (error.type == DioExceptionType.badResponse &&
          error.response?.statusCode == 429) {
        throw const EduChatException(
          'Rate limited',
          type: EduChatErrorType.rateLimited,
        );
      }

      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        return _buildFallbackResponse(prompt);
      }

      throw EduChatException(
        error.message ?? 'Unknown error',
        type: EduChatErrorType.unknown,
      );
    } catch (error) {
      if (error is EduChatException) {
        rethrow;
      }
      await Future<void>.delayed(const Duration(milliseconds: 400));
      return _buildFallbackResponse(prompt);
    }
  }

  String _buildMessagePreview(String content) {
    final sanitized = content.trim();
    if (sanitized.length <= 60) {
      return sanitized;
    }
    return '${sanitized.substring(0, 57)}...';
  }

  EduChatProxyResponse _buildFallbackResponse(String prompt) {
    final trimmed = prompt.trim();
    if (trimmed.isEmpty) {
      return const EduChatProxyResponse(text: '');
    }

    final preview = trimmed.length <= 240
        ? trimmed
        : '${trimmed.substring(0, 237)}...';

    final explanation =
        'edu_chat_offline_fallback'.trParams({'preview': preview});

    final tokensEstimate = preview.isEmpty
        ? 0
        : preview.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).length * 4;

    return EduChatProxyResponse(
      text: explanation,
      model: 'demo-offline-assistant',
      tokens: tokensEstimate,
    );
  }
}
