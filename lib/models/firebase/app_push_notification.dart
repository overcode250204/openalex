import 'package:firebase_messaging/firebase_messaging.dart';

enum PushNotificationSource { foreground, background, openedApp, initial }

class AppPushNotification {
  const AppPushNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.data,
    required this.source,
    required this.receivedAt,
  });

  final String id;
  final String title;
  final String body;
  final Map<String, String> data;
  final PushNotificationSource source;
  final DateTime receivedAt;

  factory AppPushNotification.fromRemoteMessage(
    RemoteMessage message, {
    required PushNotificationSource source,
    DateTime? receivedAt,
  }) {
    final notification = message.notification;
    final data = message.data.map(
      (key, value) => MapEntry(key, value.toString()),
    );
    final fallbackTitle = data['title'] ?? 'Research notification';
    final fallbackBody = data['body'] ?? 'Open the app to view details.';

    return AppPushNotification(
      id:
          message.messageId ??
          data['id'] ??
          '${source.name}-${DateTime.now().microsecondsSinceEpoch}',
      title: _cleanValue(notification?.title) ?? fallbackTitle,
      body: _cleanValue(notification?.body) ?? fallbackBody,
      data: data,
      source: source,
      receivedAt: receivedAt ?? message.sentTime ?? DateTime.now(),
    );
  }

  factory AppPushNotification.fromJson(Map<String, Object?> json) {
    return AppPushNotification(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Research notification',
      body: json['body']?.toString() ?? 'Open the app to view details.',
      data: (json['data'] as Map<Object?, Object?>? ?? const {}).map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      ),
      source: PushNotificationSource.values.firstWhere(
        (source) => source.name == json['source'],
        orElse: () => PushNotificationSource.background,
      ),
      receivedAt:
          DateTime.tryParse(json['receivedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'data': data,
      'source': source.name,
      'receivedAt': receivedAt.toIso8601String(),
    };
  }

  AppPushNotification copyWith({
    PushNotificationSource? source,
    DateTime? receivedAt,
  }) {
    return AppPushNotification(
      id: id,
      title: title,
      body: body,
      data: data,
      source: source ?? this.source,
      receivedAt: receivedAt ?? this.receivedAt,
    );
  }

  static String? _cleanValue(String? value) {
    final clean = value?.trim();
    if (clean == null || clean.isEmpty) return null;
    return clean;
  }
}
