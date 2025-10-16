// fcm_v1_service.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;

import 'messaging_notification_constants.dart';

enum FCMv1SendStatus {
  success,
  invalidToken,
  failed,
}

class FCMv1Service {
  FCMv1Service({
    required String projectId,
    required String clientEmail,
    required String clientId,
    required String privateKey,
    required String privateKeyId,
    Dio? httpClient,
  })  : _projectId = projectId,
        _credentials = auth.ServiceAccountCredentials.fromJson({
          'type': 'service_account',
          'project_id': projectId,
          'private_key_id': privateKeyId,
          'private_key': privateKey,
          'client_email': clientEmail,
          'client_id': clientId,
          'token_uri': 'https://oauth2.googleapis.com/token',
        }),
        _httpClient = httpClient ??
            Dio(
              BaseOptions(
                baseUrl: 'https://fcm.googleapis.com',
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                headers: const <String, dynamic>{
                  'Content-Type': 'application/json',
                },
              ),
            );

  final String _projectId;
  final auth.ServiceAccountCredentials _credentials;
  final Dio _httpClient;

  static const List<String> _scopes = <String>[
    'https://www.googleapis.com/auth/firebase.messaging',
  ];

  Future<String?> getAccessToken() async {
    final client = http.Client();
    try {
      final accessCredentials =
      await auth.obtainAccessCredentialsViaServiceAccount(
        _credentials,
        _scopes,
        client,
      );
      debugPrint(
        '🔐 Obtained FCM access token expiring at '
            '${accessCredentials.accessToken.expiry}',
      );
      return accessCredentials.accessToken.data;
    } catch (error, stackTrace) {
      debugPrint('❌ Failed to obtain FCM access token: $error');
      debugPrint('$stackTrace');
      return null;
    } finally {
      client.close();
    }
  }

  Future<FCMv1SendStatus> sendMessage({
    required String token,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    final accessToken = await getAccessToken();
    if (accessToken == null) {
      return FCMv1SendStatus.failed;
    }
    return sendMessageWithAccessToken(
      token: token,
      title: title,
      body: body,
      data: data,
      accessToken: accessToken,
    );
  }

  Future<FCMv1SendStatus> sendMessageWithAccessToken({
    required String token,
    required String title,
    required String body,
    required Map<String, dynamic> data,
    required String accessToken,
  }) async {
    // Ensure all data values are strings (FCM requirement)
    final enrichedData = <String, dynamic>{
      ...data,
      'title': data['title'] ?? title,
      'body': data['body'] ?? body,
    }.map((k, v) => MapEntry(k, '$v'));

    final payload = _buildFcmV1Payload(
      token: token,
      title: title,
      body: body,
      data: enrichedData,
      channelId: messagingNotificationChannelId,
    );

    try {
      final response = await _httpClient.post<dynamic>(
        '/v1/projects/$_projectId/messages:send',
        data: payload,
        options: Options(
          headers: <String, dynamic>{
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      debugPrint('✅ FCM v1 response (${response.statusCode}): ${response.data}');
      return FCMv1SendStatus.success;
    } on DioException catch (error, stackTrace) {
      final status = error.response?.statusCode;
      final errorStatus = _extractErrorStatus(error.response?.data);
      if (status != null) {
        debugPrint('❌ FCM v1 error ($status): ${error.response?.data}');
      } else {
        debugPrint('❌ FCM v1 network error: ${error.message}');
      }
      debugPrint('$stackTrace');
      if (errorStatus == 'UNREGISTERED' || errorStatus == 'NOT_FOUND') {
        return FCMv1SendStatus.invalidToken;
      }
      return FCMv1SendStatus.failed;
    } catch (error, stackTrace) {
      debugPrint('❌ Unexpected error sending FCM v1 message: $error');
      debugPrint('$stackTrace');
      return FCMv1SendStatus.failed;
    }
  }

  // ---- Helpers ----

  Map<String, dynamic> _buildFcmV1Payload({
    required String token,
    required String title,
    required String body,
    required Map<String, String> data,
    required String channelId,
  }) {
    final conversationId = data['conversationId'];

    return {
      'message': {
        'token': token,

        // Top-level notification ONLY holds title/body
        'notification': <String, dynamic>{
          'title': title,
          'body': body,
        },

        // Custom key–values must be strings
        'data': data,

        // Android options live under "android"
        'android': {
          // MUST be uppercase in HTTP v1
          'priority': 'HIGH',
          'notification': {
            // MUST be snake_case here (not channelId / not under message.notification)
            'channel_id': channelId,
            'sound': 'default',
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            if (conversationId != null && conversationId.isNotEmpty)
              'tag': messagingNotificationTagForConversation(conversationId),
            // Optional extras:
            // 'notification_count': 1,
            // 'tag': 'message_${data['conversationId']}',
          },
        },

        // iOS/APNs (kept from your original file)
        'apns': {
          'headers': {
            'apns-priority': '10',
          },
          'payload': {
            'aps': {
              'alert': {
                'title': title,
                'body': body,
              },
              'sound': 'default',
              'content-available': 1,
              'mutable-content': 1,
            },
          },
        },
      },
    };
  }

  static String? _extractErrorStatus(dynamic errorData) {
    if (errorData is Map<String, dynamic>) {
      final error = errorData['error'];
      if (error is Map<String, dynamic>) {
        final status = error['status'];
        if (status is String && status.isNotEmpty) {
          return status;
        }
        final message = error['message'];
        if (message is String) {
          if (message.contains('UNREGISTERED')) return 'UNREGISTERED';
          if (message.contains('not found')) return 'NOT_FOUND';
        }
      }
    }
    return null;
  }
}
