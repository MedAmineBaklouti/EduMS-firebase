import 'dart:convert';
import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'messaging_notification_channel.dart';

final FlutterLocalNotificationsPlugin _backgroundNotifications =
    FlutterLocalNotificationsPlugin();

bool _backgroundNotificationsInitialized = false;

@pragma('vm:entry-point')
Future<void> messagingBackgroundHandler(RemoteMessage message) async {
  log('Background message handler invoked: id=${message.messageId}, data=${message.data}');

  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }

  if (!_backgroundNotificationsInitialized) {
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _backgroundNotifications.initialize(initializationSettings);

    final androidPlugin = _backgroundNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(messagingAndroidChannel);

    _backgroundNotificationsInitialized = true;
  }

  final notification = message.notification;
  final data = message.data;

  await _backgroundNotifications.show(
    notification?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
    notification?.title ?? data['title'] ?? 'New message',
    notification?.body ?? data['content'] ?? data['text'] ?? '',
    NotificationDetails(
      android: AndroidNotificationDetails(
        messagingAndroidChannel.id,
        messagingAndroidChannel.name,
        channelDescription: messagingAndroidChannel.description,
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: const DefaultStyleInformation(true, true),
      ),
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
