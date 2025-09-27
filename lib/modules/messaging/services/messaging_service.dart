import 'dart:async';
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
    Dio? dio,
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
    FirebaseFirestore? firestore,
    AuthService? authService,
    Dio? pushClient,
  })  : _providedDio = dio,
        _messaging = messaging ?? FirebaseMessaging.instance,
        _localNotifications =
            localNotifications ?? FlutterLocalNotificationsPlugin(),
        _firestore = firestore ?? FirebaseFirestore.instance,
        _authService = authService ?? Get.find<AuthService>(),
        _pushClient = pushClient ?? _createPushClient();

  final Dio? _providedDio;
  Dio? _dio;
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
  static const List<String> _nestedDataKeys = <String>['data', 'result'];
  static const String _tokenCollection = 'userPushTokens';
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
    final baseUrl = AppConfig.apiBaseUrl.trim();

    if (_providedDio != null) {
      _dio = _providedDio;
    } else if (baseUrl.isNotEmpty) {
      _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          receiveDataWhenStatusError: true,
          headers: <String, dynamic>{
            'Content-Type': 'application/json',
            if (AppConfig.apiKey.isNotEmpty) 'x-api-key': AppConfig.apiKey,
          },
        ),
      );
    } else {
      _dio = null;
    }

    _dio?.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true),
    );

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
    final dio = _requireApiClient();
    try {
      final Response<dynamic> response = await dio.get<dynamic>(
        '/conversations/$conversationId/messages',
      );

      final dynamic body = _unwrapData(response.data);
      if (body == null) {
        return <MessageModel>[];
      }

      List<dynamic>? items;
      if (body is List) {
        items = body;
      } else if (body is Map<String, dynamic>) {
        final dynamic nested = body['items'] ?? body['messages'];
        if (nested is List) {
          items = nested;
        } else if (body.containsKey('id')) {
          items = <dynamic>[body];
        }
      }

      if (items == null) {
        throw Exception('Unexpected response shape when fetching messages.');
      }

      final results = items
          .whereType<Map<String, dynamic>>()
          .map(MessageModel.fromJson)
          .toList();
      results.sort((a, b) => a.sentAt.compareTo(b.sentAt));
      return results;
    } on DioException catch (error) {
      final message = error.message ?? 'Unknown error';
      throw Exception('Failed to load messages: $message');
    }
  }

  Future<List<ConversationModel>> fetchConversations() async {
    final dio = _requireApiClient();
    try {
      final Response<dynamic> response = await dio.get<dynamic>(
        '/conversations',
      );

      final dynamic body = _unwrapData(response.data);
      if (body == null) {
        return <ConversationModel>[];
      }

      List<dynamic>? items;
      if (body is List) {
        items = body;
      } else if (body is Map<String, dynamic>) {
        final dynamic nested = body['items'] ?? body['conversations'];
        if (nested is List) {
          items = nested;
        }
      }

      if (items == null) {
        throw Exception('Unexpected response when fetching conversations.');
      }

      final conversations = items
          .whereType<Map<String, dynamic>>()
          .map(ConversationModel.fromJson)
          .toList();
      conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return conversations;
    } on DioException catch (error) {
      final message = error.message ?? 'Unknown error';
      throw Exception('Failed to load conversations: $message');
    }
  }

  Future<ConversationModel?> fetchConversation(String conversationId) async {
    final dio = _requireApiClient();
    try {
      final Response<dynamic> response = await dio.get<dynamic>(
        '/conversations/$conversationId',
      );

      final dynamic body = _unwrapData(response.data);
      if (body is Map<String, dynamic>) {
        return ConversationModel.fromJson(body);
      }

      return null;
    } on DioException catch (error) {
      final message = error.message ?? 'Unknown error';
      throw Exception('Failed to load conversation: $message');
    }
  }

  Future<MessageModel> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String content,
    List<ConversationParticipant>? participants,
  }) async {
    final dio = _requireApiClient();
    try {
      final Response<dynamic> response = await dio.post<dynamic>(
        '/conversations/$conversationId/messages',
        data: <String, dynamic>{
          'senderId': senderId,
          'senderName': senderName,
          'content': content,
        },
      );

      final dynamic body = response.data;
      if (body is Map<String, dynamic>) {
        final message = MessageModel.fromJson(body);
        _messageStreamController.add(message);
        if (participants != null && participants.isNotEmpty) {
          unawaited(_sendPushNotification(message, participants));
        }
        return message;
      }

      throw Exception('Unexpected response when sending message.');
    } on DioException catch (error) {
      final message = error.message ?? 'Unknown error';
      throw Exception('Failed to send message: $message');
    }
  }

  Future<ConversationModel> ensureConversationWithContact(String contactId) async {
    final dio = _requireApiClient();
    try {
      final Response<dynamic> response = await dio.post<dynamic>(
        '/conversations',
        data: <String, dynamic>{
          'participantIds': <String>[contactId],
        },
      );

      final dynamic body = response.data;
      if (body is Map<String, dynamic>) {
        final conversation = ConversationModel.fromJson(body);
        return conversation;
      }

      throw Exception('Unexpected response when starting conversation.');
    } on DioException catch (error) {
      final message = error.message ?? 'Unknown error';
      throw Exception('Failed to start conversation: $message');
    }
  }

  Future<List<MessagingContact>> fetchAllowedContacts({
    required String userRole,
    required String userId,
    List<String>? classIds,
  }) async {
    final dio = _requireApiClient();
    try {
      final Response<dynamic> response = await dio.get<dynamic>(
        '/messaging/contacts',
        queryParameters: <String, dynamic>{
          'role': userRole,
          'userId': userId,
          if (classIds != null && classIds.isNotEmpty) 'classIds': classIds,
        },
      );

      final dynamic body = _unwrapData(response.data);
      if (body == null) {
        return <MessagingContact>[];
      }

      List<dynamic>? items;
      if (body is List) {
        items = body;
      } else if (body is Map<String, dynamic>) {
        final dynamic nested = body['items'] ?? body['contacts'];
        if (nested is List) {
          items = nested;
        }
      }

      if (items == null) {
        throw Exception('Unexpected response when fetching contacts.');
      }

      return items
          .whereType<Map<String, dynamic>>()
          .map(MessagingContact.fromJson)
          .toList();
    } on DioException catch (error) {
      final message = error.message ?? 'Unknown error';
      throw Exception('Failed to load contacts: $message');
    }
  }

  Dio _requireApiClient() {
    final dio = _dio;
    if (dio != null) {
      return dio;
    }

    throw StateError(
      'Messaging API is not configured. Backend-dependent messaging features are disabled because API_URL is empty.',
    );
  }

  dynamic _unwrapData(dynamic body) {
    if (body is Map<String, dynamic>) {
      for (final key in _nestedDataKeys) {
        if (body.containsKey(key)) {
          final dynamic value = body[key];
          if (value != null) {
            return _unwrapData(value);
          }
        }
      }
    }
    return body;
  }

  void _handleAuthStateChanged(User? user) {
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
