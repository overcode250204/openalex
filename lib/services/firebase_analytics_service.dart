import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

import '../models/auth/app_user.dart';

abstract interface class AppAnalyticsService {
  Future<void> logLogin({required AppUser user, required String method});

  Future<void> logLogout({required AppUser? user, required String method});

  Future<void> clearUser();
}

class FirebaseAnalyticsService implements AppAnalyticsService {
  FirebaseAnalyticsService({FirebaseAnalytics? analytics})
    : _analytics = analytics ?? FirebaseAnalytics.instance;

  static const String googleMethod = 'google';

  final FirebaseAnalytics _analytics;
  Future<void>? _enableCollectionFuture;

  @override
  Future<void> logLogin({required AppUser user, required String method}) async {
    await _ensureCollectionEnabled();
    await _analytics.setUserId(id: user.uid);
    await _analytics.logLogin(
      loginMethod: method,
      parameters: {'auth_provider': method},
    );

    debugPrint('Firebase Analytics event logged: login');
  }

  @override
  Future<void> logLogout({
    required AppUser? user,
    required String method,
  }) async {
    await _ensureCollectionEnabled();
    await _analytics.logEvent(
      name: 'logout',
      parameters: {'auth_provider': method, 'had_user': user == null ? 0 : 1},
    );

    debugPrint('Firebase Analytics event logged: logout');
  }

  @override
  Future<void> clearUser() async {
    await _ensureCollectionEnabled();
    await _analytics.setUserId(id: null);
  }

  Future<void> _ensureCollectionEnabled() {
    return _enableCollectionFuture ??= _analytics.setAnalyticsCollectionEnabled(
      true,
    );
  }
}

class NoOpAnalyticsService implements AppAnalyticsService {
  const NoOpAnalyticsService();

  @override
  Future<void> logLogin({
    required AppUser user,
    required String method,
  }) async {}

  @override
  Future<void> logLogout({
    required AppUser? user,
    required String method,
  }) async {}

  @override
  Future<void> clearUser() async {}
}
