import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> messagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  log('Received background message ${message.messageId}: ${message.data}');
}
