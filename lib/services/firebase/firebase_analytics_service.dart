import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

import '../../models/auth/app_user.dart';
import '../analytics/app_analytics_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAnalyticsService implements AppAnalyticsService {
  FirebaseAnalyticsService({
    FirebaseAnalytics? analytics,
    FirebaseAuth? firebaseAuth,
  }) : _analytics = analytics ?? FirebaseAnalytics.instance,
       _auth = firebaseAuth ?? FirebaseAuth.instance;

  static const String googleMethod = 'google';

  final FirebaseAnalytics _analytics;
  final FirebaseAuth _auth;

  Future<void>? _enableCollectionFuture;
  AppUser? _currentUser;

  AppUser? get _activeUser {
    final firebaseUser = _auth.currentUser;

    if (firebaseUser != null) {
      return AppUser.fromFirebaseUser(firebaseUser);
    }

    return _currentUser;
  }

  @override
  Future<void> logLogin({required AppUser user, required String method}) async {
    await _safely(() async {
      await _ensureCollectionEnabled();

      _currentUser = user;

      // Firebase Analytics chỉ gắn UID, không gửi email/name.
      await _analytics.setUserId(id: user.uid);

      await _analytics.logLogin(
        loginMethod: method,
        parameters: {'auth_provider': method},
      );

      debugPrint('''
[Analytics] Login logged successfully
  UID: ${user.uid}
  Name: ${user.displayName ?? 'Unknown'}
  Email: ${user.email ?? 'No email'}
  Provider: $method
''');
    });
  }

  @override
  Future<void> logLogout({
    required AppUser? user,
    required String method,
  }) async {
    await _safely(() async {
      await _ensureCollectionEnabled();
      await _analytics.logEvent(
        name: 'logout',
        parameters: {'auth_provider': method, 'had_user': user == null ? 0 : 1},
      );
    });
  }

  @override
  Future<void> clearUser() async {
    await _safely(() async {
      await _ensureCollectionEnabled();

      await _analytics.setUserId(id: null);
      _currentUser = null;
    });
  }

  @override
  Future<void> logSearchTopic(String keyword) async {
    final cleanKeyword = keyword.trim();
    if (cleanKeyword.isEmpty) return;

    await _safely(() async {
      await _ensureCollectionEnabled();

      await _analytics.logEvent(
        name: 'search_topic',
        parameters: {'keyword': cleanKeyword},
      );

      debugPrint('''
[Analytics] search_topic logged
  User UID: ${_activeUser?.uid ?? 'anonymous'}
  Keyword: $cleanKeyword
''');
    });
  }

  @override
  Future<void> logViewPublication({
    required String publicationTitle,
    required int? publicationYear,
  }) async {
    final cleanTitle = publicationTitle.trim();
    if (cleanTitle.isEmpty || publicationYear == null) return;

    await _safely(() async {
      await _ensureCollectionEnabled();

      await _analytics.logEvent(
        name: 'view_publication',
        parameters: {
          'publication_title': cleanTitle,
          'publication_year': publicationYear,
        },
      );

      debugPrint('''
[Analytics] view_publication logged
  User UID: ${_activeUser?.uid ?? 'anonymous'}
  Publication: $cleanTitle
  Year: $publicationYear
''');
    });
  }

  Future<void> _ensureCollectionEnabled() {
    return _enableCollectionFuture ??= _analytics.setAnalyticsCollectionEnabled(
      true,
    );
  }

  Future<void> _safely(Future<void> Function() action) async {
    try {
      await action();
    } catch (error, stackTrace) {
      debugPrint('Firebase Analytics unavailable: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
