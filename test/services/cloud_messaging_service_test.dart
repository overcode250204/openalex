import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/models/firebase/app_push_notification.dart';
import 'package:openalex/services/firebase/cloud_messaging_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('FirebaseMessagingBackgroundStore', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('stores and loads background notifications', () async {
      final message = RemoteMessage.fromMap({
        'messageId': 'background-1',
        'notification': {
          'title': 'Research trend updates',
          'body': 'New trend found.',
        },
        'data': {'topic': 'AI'},
      });

      await FirebaseMessagingBackgroundStore.save(
        message,
        receivedAt: DateTime(2026, 6, 25, 12),
      );

      final notifications = await FirebaseMessagingBackgroundStore.load();

      expect(notifications, hasLength(1));
      expect(notifications.single.id, 'background-1');
      expect(notifications.single.title, 'Research trend updates');
      expect(notifications.single.body, 'New trend found.');
      expect(notifications.single.data, {'topic': 'AI'});
      expect(notifications.single.source, PushNotificationSource.background);
    });

    test('keeps only the newest twenty background notifications', () async {
      for (var index = 0; index < 25; index++) {
        await FirebaseMessagingBackgroundStore.save(
          RemoteMessage.fromMap({
            'messageId': 'message-$index',
            'data': {'title': 'Title $index', 'body': 'Body $index'},
          }),
        );
      }

      final notifications = await FirebaseMessagingBackgroundStore.load();

      expect(notifications, hasLength(20));
      expect(notifications.first.id, 'message-24');
      expect(notifications.last.id, 'message-5');
    });
  });
}
