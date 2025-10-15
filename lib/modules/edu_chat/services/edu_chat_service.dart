import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';

import '../models/edu_chat_exception.dart';
import '../models/edu_chat_message.dart';
import '../models/edu_chat_proxy_response.dart';
import '../models/edu_chat_thread.dart';

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

  static const List<String> _denylist = <String>[
    'messi',
    'ronaldo',
    'celebrity',
    'gossip',
    'movie',
    'series',
    'tiktok',
    'instagram',
    'politics',
    'adult',
    'league',
  ];

  // List of possible models to try
  final List<String> _possibleModels = [
    'gemini-2.0-flash-exp', // Most likely for free tier
    'gemini-1.5-flash',
    'gemini-1.5-pro',
    'gemini-pro',
    'gemini-1.0-pro',
  ];

  String? _cachedWorkingModel;

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

    final chatsRef =
    _userChatsCollection(user.uid).orderBy('updatedAt', descending: true);
    final snapshot = await chatsRef.limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.id;
    }

    final docRef = _userChatsCollection(user.uid).doc();
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
    if (user == null) return const Stream.empty();

    return _userChatsCollection(user.uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => EduChatThread.fromSnapshot(doc)).toList());
  }

  Stream<List<EduChatMessage>> watchMessages(String chatId) {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    final messagesRef =
    _userChatsCollection(user.uid).doc(chatId).collection('messages');
    return messagesRef
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => EduChatMessage.fromSnapshot(doc)).toList());
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
        if (snapshot.docs.isEmpty) break;

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
      throw EduChatException(error.message ?? error.code, type: type);
    } catch (error) {
      throw EduChatException(error.toString(), type: EduChatErrorType.unknown);
    }
  }

  Future<String> _findWorkingModel() async {
    // If we already found a working model, use it
    if (_cachedWorkingModel != null) {
      return _cachedWorkingModel!;
    }

    final apiKey = dotenv.env['GEMINI_API_KEY']?.trim();
    if (apiKey == null || apiKey.isEmpty) {
      throw const EduChatException(
        'Gemini API key is not configured',
        type: EduChatErrorType.unknown,
      );
    }

    const bool _debugGemini = true;

    // Simple test request to check if a model works
    final testBody = {
      "contents": [
        {
          "parts": [
            {"text": "Hello"}
          ]
        }
      ]
    };

    for (final model in _possibleModels) {
      try {
        final url = 'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey';

        if (_debugGemini) {
          print('🔍 Testing model: $model');
        }

        final response = await _dio.post<Map<String, dynamic>>(
          url,
          data: testBody,
          options: Options(
            headers: {"Content-Type": "application/json"},
          ),
        );

        if (response.statusCode == 200) {
          if (_debugGemini) {
            print('✅ Found working model: $model');
          }
          _cachedWorkingModel = model;
          return model;
        }
      } on DioException catch (e) {
        if (_debugGemini) {
          print('❌ Model $model failed: ${e.response?.statusCode}');
        }
        continue; // Try next model
      } catch (e) {
        if (_debugGemini) {
          print('❌ Model $model error: $e');
        }
        continue; // Try next model
      }
    }

    throw const EduChatException(
      'No working Gemini model found. Please check your API key and available models.',
      type: EduChatErrorType.invalidResponse,
    );
  }

  Future<EduChatProxyResponse> requestEducationalAssistant({
    required String prompt,
  }) async {
    // Enable debug logging
    const bool _debugGemini = true;

    final user = _auth.currentUser;
    if (user == null) {
      throw const EduChatException(
        'User not authenticated',
        type: EduChatErrorType.unauthenticated,
      );
    }

    final apiKey = dotenv.env['GEMINI_API_KEY']?.trim();
    if (apiKey == null || apiKey.isEmpty) {
      throw const EduChatException(
        'Gemini API key is not configured',
        type: EduChatErrorType.unknown,
      );
    }

    if (_debugGemini) {
      print('🔑 API Key present: ${apiKey.isNotEmpty}');
    }

    final sanitizedPrompt = prompt.trim();
    if (sanitizedPrompt.isEmpty) {
      return const EduChatProxyResponse(text: '');
    }

    // Client educational gate (quick denylist)
    final lower = sanitizedPrompt.toLowerCase();
    if (_denylist.any((t) => lower.contains(t))) {
      return const EduChatProxyResponse(
        text: 'Sorry, I can only help with educational topics. Try questions about math, science, history, languages, programming, exam prep, study skills, etc.',
        model: 'policy-refusal',
        refused: true,
      );
    }

    try {
      // Find a working model
      final model = await _findWorkingModel();
      final url = 'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey';

      if (_debugGemini) {
        print('🚀 Sending request to: $url');
        print('📝 Prompt: $sanitizedPrompt');
      }

      final body = {
        "contents": [
          {
            "parts": [
              {
                "text": sanitizedPrompt
              }
            ]
          }
        ]
      };

      if (_debugGemini) {
        print('📦 Request body: ${body.toString()}');
      }

      final response = await _dio.post<Map<String, dynamic>>(
        url,
        data: body,
        options: Options(
          headers: {
            "Content-Type": "application/json",
          },
        ),
      );

      if (_debugGemini) {
        print('✅ Response status: ${response.statusCode}');
        print('📦 Response data: ${response.data}');
      }

      final data = response.data;
      if (data == null) {
        throw const EduChatException(
          'Empty response from Gemini API',
          type: EduChatErrorType.invalidResponse,
        );
      }

      // Check for errors in response
      if (data['error'] != null) {
        final error = data['error'];
        throw EduChatException(
          error['message'] ?? 'Gemini API error',
          type: EduChatErrorType.invalidResponse,
        );
      }

      final candidates = data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        throw const EduChatException(
          'No candidates in response',
          type: EduChatErrorType.invalidResponse,
        );
      }

      final firstCandidate = candidates.first as Map<String, dynamic>;
      final content = firstCandidate['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List?;

      if (parts == null || parts.isEmpty) {
        throw const EduChatException(
          'No content parts in response',
          type: EduChatErrorType.invalidResponse,
        );
      }

      // Extract text from parts
      final textParts = parts
          .whereType<Map<String, dynamic>>()
          .map((part) => part['text'] as String?)
          .where((text) => text != null && text.isNotEmpty)
          .join('\n');

      if (textParts.isEmpty) {
        throw const EduChatException(
          'Empty response text',
          type: EduChatErrorType.invalidResponse,
        );
      }

      // Extract token count from usageMetadata if available
      int? tokens;
      final usageMetadata = data['usageMetadata'] as Map<String, dynamic>?;
      if (usageMetadata != null) {
        final totalTokens = usageMetadata['totalTokenCount'];
        if (totalTokens is int) {
          tokens = totalTokens;
        }
      }

      return EduChatProxyResponse(
        text: textParts,
        model: data['modelVersion'] as String? ?? model,
        tokens: tokens,
        refused: false,
      );

    } on DioException catch (e) {
      if (_debugGemini) {
        print('❌ DioException: ${e.type}');
        print('📡 Response: ${e.response?.data}');
        print('🔧 Error: ${e.message}');
      }

      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final errorData = e.response!.data;

        if (_debugGemini) {
          print('📊 Status code: $statusCode');
          print('📄 Error response: $errorData');
        }

        if (statusCode == 400) {
          throw const EduChatException(
            'Bad request - check API key and parameters',
            type: EduChatErrorType.invalidResponse,
          );
        } else if (statusCode == 403) {
          throw const EduChatException(
            'API key invalid or insufficient permissions',
            type: EduChatErrorType.unauthenticated,
          );
        } else if (statusCode == 404) {
          // Clear cached model and retry
          _cachedWorkingModel = null;
          throw const EduChatException(
            'Model not found - will retry with different model',
            type: EduChatErrorType.invalidResponse,
          );
        } else if (statusCode == 429) {
          throw const EduChatException(
            'Rate limited',
            type: EduChatErrorType.rateLimited,
          );
        }
      }

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw const EduChatException(
          'Network error - check your internet connection',
          type: EduChatErrorType.network,
        );
      }

      throw EduChatException(
        e.message ?? 'Network request failed',
        type: EduChatErrorType.network,
      );
    } catch (e, stackTrace) {
      if (_debugGemini) {
        print('❌ Unexpected error: $e');
        print('📋 Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  String _buildMessagePreview(String content) {
    final sanitized = content.trim();
    if (sanitized.length <= 60) return sanitized;
    return '${sanitized.substring(0, 57)}...';
  }
}