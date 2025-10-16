import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

import 'package:edums/modules/auth/service/auth_service.dart';
import 'package:edums/modules/messaging/services/messaging_service.dart';

class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

class MockAuthService extends Mock implements AuthService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Get.testMode = true;

  group('MessagingService token lifecycle', () {
    late FakeFirebaseFirestore firestore;
    late MockFirebaseMessaging messaging;
    late MockAuthService authService;
    late MessagingService service;
    late List<String> logs;
    late void Function(String?, {int? wrapWidth}) originalDebugPrint;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      messaging = MockFirebaseMessaging();
      authService = MockAuthService();
      when(() => authService.user).thenReturn(Rx<User?>(null));
      when(() => authService.currentUser).thenReturn(null);
      service = MessagingService(
        messaging: messaging,
        firestore: firestore,
        authService: authService,
        pushClient: null,
      );
      service.debugSetPushPermissionGranted(true);
      service.debugSetDeviceId('device-test-1');

      logs = <String>[];
      originalDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) {
          logs.add(message);
        }
      };
    });

    tearDown(() {
      debugPrint = originalDebugPrint;
    });

    test('requests, stores, refreshes and fetches device tokens', () async {
      when(() => messaging.getToken())
          .thenAnswer((_) async => 'token-abc123456789');

      await service.ensureTokenForUserForTesting('user-1');

      final doc = await firestore.collection('userPushTokens').doc('user-1').get();
      final data = doc.data();
      expect(data, isNotNull);
      expect(data!['tokens'], contains('token-abc123456789'));
      expect(
        (data['deviceTokens'] as Map<String, dynamic>)['device-test-1'],
        equals('token-abc123456789'),
      );
      expect(
        (data['devicePlatforms'] as Map<String, dynamic>)['device-test-1'],
        equals(defaultTargetPlatform.name),
      );
      expect(data['updatedAt'], isA<Timestamp>());
      expect(
        (data['deviceUpdatedAt'] as Map<String, dynamic>)['device-test-1'],
        isNotNull,
      );
      expect(
        (data['deviceCreatedAt'] as Map<String, dynamic>)['device-test-1'],
        isNotNull,
      );
      expect(service.debugLastKnownToken, 'token-abc123456789');

      await service.registerTokenForUserForTesting('user-1', 'token-xyz987654321');

      final updatedDoc =
          await firestore.collection('userPushTokens').doc('user-1').get();
      final updatedData = updatedDoc.data();
      expect(updatedData, isNotNull);
      final tokensList =
          List<String>.from(updatedData!['tokens'] as List<dynamic>);
      expect(tokensList, contains('token-xyz987654321'));
      expect(tokensList, isNot(contains('token-abc123456789')));
      expect(
        (updatedData['deviceTokens'] as Map<String, dynamic>)['device-test-1'],
        equals('token-xyz987654321'),
      );

      final fetched = await service.fetchTokensForUsersForTesting(['user-1']);
      expect(fetched, contains('token-xyz987654321'));
      expect(fetched, isNot(contains('token-abc123456789')));

      expect(
        logs.any((message) =>
            message.contains('FirebaseMessaging.getToken for user-1 returned')),
        isTrue,
      );
      expect(
        logs.any((message) =>
            message.contains('Registering new FCM token for user-1')),
        isTrue,
      );
      expect(
        logs.any((message) =>
            message.contains('Updated device token for user user-1') ||
            message.contains('Device token for user user-1 already up to date.')),
        isTrue,
      );
      expect(
        logs.any((message) =>
            message.contains('Removed stale FCM token for user-1')),
        isTrue,
      );

      // Emit captured logs to make debugging easier when reviewing test output.
      // ignore: avoid_print
      print('Captured messaging logs:\n${logs.join('\n')}');
    });
  });
}
