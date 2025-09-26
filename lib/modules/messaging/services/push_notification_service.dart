import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class PushNotificationService {
  PushNotificationService();

  String? get _serverKey => dotenv.env['FCM_SERVER_KEY'];

  Future<void> sendMessageNotification({
    required List<String> tokens,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    if (tokens.isEmpty) {
      return;
    }

    final serverKey = _serverKey;
    if (serverKey == null || serverKey.isEmpty) {
      return;
    }

    final payload = <String, dynamic>{
      'registration_ids': tokens,
      'notification': <String, dynamic>{
        'title': title,
        'body': body,
      },
      'data': data ?? <String, dynamic>{},
    };

    final response = await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverKey',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode >= 400) {
      throw Exception('FCM error ${response.statusCode}: ${response.body}');
    }
  }
}
