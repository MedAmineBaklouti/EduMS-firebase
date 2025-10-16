import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'messaging_notification_constants.dart';

const AndroidNotificationChannel messagingAndroidChannel = AndroidNotificationChannel(
  messagingNotificationChannelId,
  messagingNotificationChannelName,
  description: messagingNotificationChannelDescription,
  importance: Importance.high,
);

const DarwinNotificationDetails messagingDarwinNotificationDetails = DarwinNotificationDetails(
  presentAlert: true,
  presentBadge: true,
  presentSound: true,
);
