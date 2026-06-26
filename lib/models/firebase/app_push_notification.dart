import 'package:firebase_messaging/firebase_messaging.dart';

enum PushNotificationSource { foreground, background, openedApp, initial }

enum AppPushNotificationType { trend, citation, researchUpdate, generic }

class AppPushNotification {
  const AppPushNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.data,
    required this.source,
    required this.receivedAt,
    this.type = AppPushNotificationType.generic,
  });

  final String id;
  final String title;
  final String body;
  final Map<String, String> data;
  final PushNotificationSource source;
  final DateTime receivedAt;
  final AppPushNotificationType type;

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

    final title = _cleanValue(notification?.title) ?? fallbackTitle;
    final body = _cleanValue(notification?.body) ?? fallbackBody;

    return AppPushNotification(
      id:
          message.messageId ??
          data['id'] ??
          '${source.name}-${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      body: body,
      data: data,
      source: source,
      receivedAt: receivedAt ?? message.sentTime ?? DateTime.now(),
      type: _inferType(title, body, data),
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
      type: AppPushNotificationType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => AppPushNotificationType.generic,
      ),
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
      'type': type.name,
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
      type: type,
    );
  }

  static String? _cleanValue(String? value) {
    final clean = value?.trim();
    if (clean == null || clean.isEmpty) return null;
    return clean;
  }

  static AppPushNotificationType _inferType(
    String title,
    String body,
    Map<String, String> data,
  ) {
    final typeStr = data['type']?.toLowerCase();
    if (typeStr == 'trend') return AppPushNotificationType.trend;
    if (typeStr == 'citation') return AppPushNotificationType.citation;
    if (typeStr == 'update') return AppPushNotificationType.researchUpdate;

    final content = '$title $body'.toLowerCase();
    if (content.contains('trend')) return AppPushNotificationType.trend;
    if (content.contains('cite') || content.contains('citation')) {
      return AppPushNotificationType.citation;
    }
    if (content.contains('update')) return AppPushNotificationType.researchUpdate;

    return AppPushNotificationType.generic;
  }
}
