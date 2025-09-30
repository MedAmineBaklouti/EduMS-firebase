import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const AndroidNotificationChannel messagingAndroidChannel = AndroidNotificationChannel(
  'messaging_channel',
  'Messaging notifications',
  description: 'Notifications for new chat messages.',
  importance: Importance.high,
);

const DarwinNotificationDetails messagingDarwinNotificationDetails = DarwinNotificationDetails(
  presentAlert: true,
  presentBadge: true,
  presentSound: true,
);
