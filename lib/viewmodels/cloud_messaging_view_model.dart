import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/firebase/app_push_notification.dart';
import '../services/firebase/cloud_messaging_service.dart';

class CloudMessagingViewModel extends ChangeNotifier {
  CloudMessagingViewModel(this._service);

  final CloudMessagingService _service;

  StreamSubscription<AppPushNotification>? _foregroundSubscription;
  StreamSubscription<AppPushNotification>? _openedAppSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;

  CloudMessagingPermissionStatus _permissionStatus =
      CloudMessagingPermissionStatus.notDetermined;
  String? _token;
  final List<AppPushNotification> _notifications = [];
  bool _isInitializing = false;
  bool _isRequestingPermission = false;
  bool _hasInitialized = false;
  String? _errorMessage;

  CloudMessagingPermissionStatus get permissionStatus => _permissionStatus;

  String? get token => _token;

  List<AppPushNotification> get notifications =>
      List.unmodifiable(_notifications);

  bool get isInitializing => _isInitializing;

  bool get isRequestingPermission => _isRequestingPermission;

  bool get hasInitialized => _hasInitialized;

  String? get errorMessage => _errorMessage;

  bool get canReceiveNotifications =>
      _permissionStatus == CloudMessagingPermissionStatus.authorized ||
      _permissionStatus == CloudMessagingPermissionStatus.provisional;

  Future<void> initialize() async {
    if (_isInitializing || _hasInitialized) return;

    _isInitializing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final snapshot = await _service.initialize();
      _permissionStatus = snapshot.permissionStatus;
      _token = snapshot.token;
      _replaceNotifications([
        if (snapshot.initialNotification != null) snapshot.initialNotification!,
        ...snapshot.backgroundNotifications,
      ]);
      _listenToStreams();
      _hasInitialized = true;
    } catch (_) {
      _errorMessage = 'Unable to initialize push notifications.';
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> requestPermission() async {
    if (_isRequestingPermission) return;

    _isRequestingPermission = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _permissionStatus = await _service.requestPermission();
      _token = await _service.getToken();
    } catch (_) {
      _errorMessage = 'Unable to request notification permission.';
    } finally {
      _isRequestingPermission = false;
      notifyListeners();
    }
  }

  void addNotification(AppPushNotification notification) {
    _upsertNotification(notification);
    notifyListeners();
  }

  void clearNotifications() {
    _notifications.clear();
    notifyListeners();
  }

  void _listenToStreams() {
    _foregroundSubscription ??= _service.foregroundNotifications.listen(
      addNotification,
      onError: (_) {
        _errorMessage = 'Unable to receive foreground notifications.';
        notifyListeners();
      },
    );

    _openedAppSubscription ??= _service.openedAppNotifications.listen(
      addNotification,
      onError: (_) {
        _errorMessage = 'Unable to receive opened notification events.';
        notifyListeners();
      },
    );

    _tokenRefreshSubscription ??= _service.tokenRefreshes.listen((token) {
      _token = token;
      notifyListeners();
    });
  }

  void _replaceNotifications(List<AppPushNotification> notifications) {
    _notifications.clear();
    for (final notification in notifications) {
      _upsertNotification(notification);
    }
  }

  void _upsertNotification(AppPushNotification notification) {
    _notifications.removeWhere((item) => item.id == notification.id);
    _notifications.insert(0, notification);
    if (_notifications.length > 20) {
      _notifications.removeRange(20, _notifications.length);
    }
  }

  @override
  void dispose() {
    _foregroundSubscription?.cancel();
    _openedAppSubscription?.cancel();
    _tokenRefreshSubscription?.cancel();
    super.dispose();
  }
}
