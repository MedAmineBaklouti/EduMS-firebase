import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../models/edu_chat_exception.dart';
import '../models/edu_chat_message.dart';
import '../models/edu_chat_proxy_response.dart';

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
      'title': 'Educational Assistant',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
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
    await chatRef.set(
      {'updatedAt': FieldValue.serverTimestamp()},
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
    if (idToken.isEmpty) {
      throw const EduChatException(
        'Unable to retrieve ID token',
        type: EduChatErrorType.unauthenticated,
      );
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
        throw const EduChatException(
          'Network error',
          type: EduChatErrorType.network,
        );
      }

      throw EduChatException(
        error.message ?? 'Unknown error',
        type: EduChatErrorType.unknown,
      );
    } catch (error) {
      if (error is EduChatException) {
        rethrow;
      }
      throw EduChatException(
        error.toString(),
        type: EduChatErrorType.unknown,
      );
    }
  }
}
