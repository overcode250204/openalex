import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/models/firebase/app_push_notification.dart';

void main() {
  test('maps RemoteMessage notification payload into app notification', () {
    final receivedAt = DateTime(2026, 6, 25, 10, 30);
    final message = RemoteMessage.fromMap({
      'messageId': 'message-1',
      'sentTime': receivedAt.millisecondsSinceEpoch,
      'notification': {
        'title': 'Highly cited publication alert',
        'body': 'A paper in your topic is gaining citations.',
      },
      'data': {'topic': 'AI', 'count': 5},
    });

    final notification = AppPushNotification.fromRemoteMessage(
      message,
      source: PushNotificationSource.foreground,
    );

    expect(notification.id, 'message-1');
    expect(notification.title, 'Highly cited publication alert');
    expect(notification.body, 'A paper in your topic is gaining citations.');
    expect(notification.data, {'topic': 'AI', 'count': '5'});
    expect(notification.source, PushNotificationSource.foreground);
    expect(notification.receivedAt, receivedAt);
    expect(notification.type, AppPushNotificationType.citation);
  });

  test(
    'uses data fallback values when notification title/body are missing',
    () {
      final message = RemoteMessage.fromMap({
        'messageId': 'message-2',
        'data': {
          'title': 'New trending research topic',
          'body': 'Quantum AI is trending this week.',
        },
      });

      final notification = AppPushNotification.fromRemoteMessage(
        message,
        source: PushNotificationSource.background,
      );

      expect(notification.title, 'New trending research topic');
      expect(notification.body, 'Quantum AI is trending this week.');
      expect(notification.source, PushNotificationSource.background);
      expect(notification.type, AppPushNotificationType.trend);
    },
  );

  test('round-trips json for background notification storage', () {
    final notification = AppPushNotification(
      id: 'message-3',
      title: 'Research trend updates',
      body: 'New activity detected.',
      data: const {'topic': 'robotics'},
      source: PushNotificationSource.background,
      receivedAt: DateTime(2026, 6, 25, 11),
      type: AppPushNotificationType.trend,
    );

    final restored = AppPushNotification.fromJson(notification.toJson());

    expect(restored.id, notification.id);
    expect(restored.title, notification.title);
    expect(restored.body, notification.body);
    expect(restored.data, notification.data);
    expect(restored.source, notification.source);
    expect(restored.receivedAt, notification.receivedAt);
    expect(restored.type, notification.type);
  });

  test('infers type correctly from data and content', () {
    final trendMsg = AppPushNotification.fromRemoteMessage(
      const RemoteMessage(data: {'type': 'trend'}),
      source: PushNotificationSource.foreground,
    );
    expect(trendMsg.type, AppPushNotificationType.trend);

    final citationMsg = AppPushNotification.fromRemoteMessage(
      const RemoteMessage(data: {'type': 'citation'}),
      source: PushNotificationSource.foreground,
    );
    expect(citationMsg.type, AppPushNotificationType.citation);

    final updateMsg = AppPushNotification.fromRemoteMessage(
      const RemoteMessage(data: {'type': 'update'}),
      source: PushNotificationSource.foreground,
    );
    expect(updateMsg.type, AppPushNotificationType.researchUpdate);

    final contentTrendMsg = AppPushNotification.fromRemoteMessage(
      RemoteMessage.fromMap({
        'notification': {'title': 'What is trending?'},
      }),
      source: PushNotificationSource.foreground,
    );
    expect(contentTrendMsg.type, AppPushNotificationType.trend);
  });
}
