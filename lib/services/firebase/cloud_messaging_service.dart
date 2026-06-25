import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/firebase/app_push_notification.dart';

enum CloudMessagingPermissionStatus {
  authorized,
  provisional,
  denied,
  notDetermined,
  unsupported,
}

class CloudMessagingSnapshot {
  const CloudMessagingSnapshot({
    required this.permissionStatus,
    required this.token,
    required this.backgroundNotifications,
    this.initialNotification,
  });

  final CloudMessagingPermissionStatus permissionStatus;
  final String? token;
  final List<AppPushNotification> backgroundNotifications;
  final AppPushNotification? initialNotification;
}

abstract interface class CloudMessagingService {
  Stream<AppPushNotification> get foregroundNotifications;

  Stream<AppPushNotification> get openedAppNotifications;

  Stream<String> get tokenRefreshes;

  Future<CloudMessagingSnapshot> initialize();

  Future<CloudMessagingPermissionStatus> requestPermission();

  Future<String?> getToken();
}

class NoOpCloudMessagingService implements CloudMessagingService {
  const NoOpCloudMessagingService();

  @override
  Stream<AppPushNotification> get foregroundNotifications =>
      const Stream.empty();

  @override
  Stream<AppPushNotification> get openedAppNotifications =>
      const Stream.empty();

  @override
  Stream<String> get tokenRefreshes => const Stream.empty();

  @override
  Future<CloudMessagingSnapshot> initialize() async {
    return const CloudMessagingSnapshot(
      permissionStatus: CloudMessagingPermissionStatus.unsupported,
      token: null,
      backgroundNotifications: [],
    );
  }

  @override
  Future<CloudMessagingPermissionStatus> requestPermission() async {
    return CloudMessagingPermissionStatus.unsupported;
  }

  @override
  Future<String?> getToken() async => null;
}

class FirebaseCloudMessagingService implements CloudMessagingService {
  FirebaseCloudMessagingService({
    FirebaseMessaging? messaging,
    Stream<RemoteMessage>? foregroundMessages,
    Stream<RemoteMessage>? openedAppMessages,
    Stream<String>? tokenRefreshes,
  }) : _messaging = messaging ?? FirebaseMessaging.instance,
       _foregroundMessages = foregroundMessages ?? FirebaseMessaging.onMessage,
       _openedAppMessages =
           openedAppMessages ?? FirebaseMessaging.onMessageOpenedApp,
       _tokenRefreshes = tokenRefreshes;

  final FirebaseMessaging _messaging;
  final Stream<RemoteMessage> _foregroundMessages;
  final Stream<RemoteMessage> _openedAppMessages;
  final Stream<String>? _tokenRefreshes;

  @override
  Stream<AppPushNotification> get foregroundNotifications =>
      _foregroundMessages.map(
        (message) => AppPushNotification.fromRemoteMessage(
          message,
          source: PushNotificationSource.foreground,
        ),
      );

  @override
  Stream<AppPushNotification> get openedAppNotifications =>
      _openedAppMessages.map(
        (message) => AppPushNotification.fromRemoteMessage(
          message,
          source: PushNotificationSource.openedApp,
        ),
      );

  @override
  Stream<String> get tokenRefreshes =>
      _tokenRefreshes ?? _messaging.onTokenRefresh;

  @override
  Future<CloudMessagingSnapshot> initialize() async {
    final isSupported = await _messaging.isSupported();
    if (!isSupported) {
      return const CloudMessagingSnapshot(
        permissionStatus: CloudMessagingPermissionStatus.unsupported,
        token: null,
        backgroundNotifications: [],
      );
    }

    await _messaging.setAutoInitEnabled(true);
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    final settings = await _messaging.getNotificationSettings();
    final token = await _safeGetToken();
    final initialMessage = await _messaging.getInitialMessage();
    final backgroundNotifications =
        await FirebaseMessagingBackgroundStore.load();

    return CloudMessagingSnapshot(
      permissionStatus: _mapPermission(settings.authorizationStatus),
      token: token,
      backgroundNotifications: backgroundNotifications,
      initialNotification: initialMessage == null
          ? null
          : AppPushNotification.fromRemoteMessage(
              initialMessage,
              source: PushNotificationSource.initial,
            ),
    );
  }

  @override
  Future<CloudMessagingPermissionStatus> requestPermission() async {
    final isSupported = await _messaging.isSupported();
    if (!isSupported) {
      return CloudMessagingPermissionStatus.unsupported;
    }

    final settings = await _messaging.requestPermission();
    return _mapPermission(settings.authorizationStatus);
  }

  @override
  Future<String?> getToken() async {
    final isSupported = await _messaging.isSupported();
    if (!isSupported) return null;
    return _safeGetToken();
  }

  Future<String?> _safeGetToken() async {
    try {
      return await _messaging.getToken();
    } catch (_) {
      return null;
    }
  }

  static CloudMessagingPermissionStatus _mapPermission(
    AuthorizationStatus status,
  ) {
    return switch (status) {
      AuthorizationStatus.authorized =>
        CloudMessagingPermissionStatus.authorized,
      AuthorizationStatus.provisional =>
        CloudMessagingPermissionStatus.provisional,
      AuthorizationStatus.denied => CloudMessagingPermissionStatus.denied,
      AuthorizationStatus.notDetermined =>
        CloudMessagingPermissionStatus.notDetermined,
    };
  }
}

class FirebaseMessagingBackgroundStore {
  const FirebaseMessagingBackgroundStore._();

  static const _storageKey = 'firebase_messaging_background_notifications';
  static const _maxStoredNotifications = 20;

  static Future<void> save(
    RemoteMessage message, {
    DateTime? receivedAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_storageKey) ?? const <String>[];
    final notification = AppPushNotification.fromRemoteMessage(
      message,
      source: PushNotificationSource.background,
      receivedAt: receivedAt,
    );
    final updated = [
      jsonEncode(notification.toJson()),
      ...existing,
    ].take(_maxStoredNotifications).toList();

    await prefs.setStringList(_storageKey, updated);
  }

  static Future<List<AppPushNotification>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedNotifications =
        prefs.getStringList(_storageKey) ?? const <String>[];

    return encodedNotifications
        .map(_decodeNotification)
        .whereType<AppPushNotification>()
        .toList();
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  static AppPushNotification? _decodeNotification(String value) {
    try {
      final json = jsonDecode(value) as Map<String, dynamic>;
      return AppPushNotification.fromJson(json);
    } catch (_) {
      return null;
    }
  }
}
