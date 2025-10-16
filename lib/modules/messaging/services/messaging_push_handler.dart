import 'dart:convert';
import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'messaging_notification_channel.dart';
import 'messaging_notification_constants.dart';

final FlutterLocalNotificationsPlugin _backgroundNotifications =
    FlutterLocalNotificationsPlugin();

bool _backgroundNotificationsInitialized = false;

@pragma('vm:entry-point')
Future<void> messagingBackgroundHandler(RemoteMessage message) async {
  log('BG HANDLER: id=${message.messageId} data=${message.data}');

  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }

  if (!_backgroundNotificationsInitialized) {
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings(messagingNotificationIcon),
      iOS: DarwinInitializationSettings(),
    );

    await _backgroundNotifications.initialize(initializationSettings);

    final androidPlugin = _backgroundNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(messagingAndroidChannel);

    _backgroundNotificationsInitialized = true;
  }

  final data = message.data;
  final notification = message.notification;
  final conversationId =
      (data['conversationId'] ?? data['conversation_id'])?.toString() ?? '';

  final senderName =
      (data['senderName'] ?? data['sender_name'])?.toString().trim();

  final title = notification?.title ??
      data['title'] ??
      (senderName?.isNotEmpty == true ? senderName : 'New message');
  final body = notification?.body ??
      data['body'] ??
      data['content'] ??
      data['text'] ??
      '';

  final notificationId = conversationId.isNotEmpty
      ? messagingNotificationIdForConversation(conversationId)
      : (message.messageId?.hashCode ??
          notification?.hashCode ??
          DateTime.now().millisecondsSinceEpoch);

  final androidDetails = AndroidNotificationDetails(
    messagingAndroidChannel.id,
    messagingAndroidChannel.name,
    channelDescription: messagingAndroidChannel.description,
    importance: Importance.high,
    priority: Priority.high,
    icon: messagingNotificationIcon,
    tag: conversationId.isNotEmpty
        ? messagingNotificationTagForConversation(conversationId)
        : null,
    styleInformation: BigTextStyleInformation(
      body,
      contentTitle: title,
      htmlFormatBigText: false,
      htmlFormatContentTitle: false,
    ),
  );

  await _backgroundNotifications.show(
    notificationId,
    title,
    body,
    NotificationDetails(
      android: androidDetails,
      iOS: messagingDarwinNotificationDetails,
    ),
    payload: jsonEncode(<String, dynamic>{
      ...data,
      if (!data.containsKey('conversationId') &&
          data['conversation_id'] != null)
        'conversationId': data['conversation_id'],
    }),
  );

  log('Received background message ${message.messageId}: ${message.data}');
}
