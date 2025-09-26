import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart' hide Response;

import '../../../app/config/app_config.dart';
import '../../../data/models/message_model.dart';
import 'messaging_push_handler.dart';

class MessagingService extends GetxService {
  MessagingService({
    Dio? dio,
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
  })  : _providedDio = dio,
        _messaging = messaging ?? FirebaseMessaging.instance,
        _localNotifications =
            localNotifications ?? FlutterLocalNotificationsPlugin();

  final Dio? _providedDio;
  late final Dio _dio;
  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;

  final StreamController<MessageModel> _messageStreamController =
      StreamController<MessageModel>.broadcast();

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    'messaging_channel',
    'Messaging notifications',
    description: 'Notifications for new chat messages.',
    importance: Importance.high,
  );

  static const String _messagingRoute = '/messaging';

  Stream<MessageModel> get messageStream => _messageStreamController.stream;

  Future<MessagingService> init() async {
    _dio = _providedDio ??
        Dio(
          BaseOptions(
            baseUrl: AppConfig.apiBaseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            receiveDataWhenStatusError: true,
            headers: <String, dynamic>{
              'Content-Type': 'application/json',
              if (AppConfig.apiKey.isNotEmpty) 'x-api-key': AppConfig.apiKey,
            },
          ),
        );

    _dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true),
    );

    await _setupLocalNotifications();
    await _initializePushNotifications();

    return this;
  }

  Future<List<MessageModel>> fetchMessages(String conversationId) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/conversations/$conversationId/messages',
      );

      final dynamic body = response.data;
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

  Future<MessageModel> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String content,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
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
        return message;
      }

      throw Exception('Unexpected response when sending message.');
    } on DioException catch (error) {
      final message = error.message ?? 'Unknown error';
      throw Exception('Failed to send message: $message');
    }
  }

  Future<void> _initializePushNotifications() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    FirebaseMessaging.onBackgroundMessage(messagingBackgroundHandler);

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return;
    }

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  Future<void> _setupLocalNotifications() async {
    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
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
    _messageStreamController.close();
    super.onClose();
  }
}
