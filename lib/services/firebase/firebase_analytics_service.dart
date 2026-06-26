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
  Future<void> logSearchTopic(
    String keyword, {
    int? resultCount,
    String? searchSource,
    String? topicId,
    int? hasValidTopic,
    int? filterYearFrom,
    int? filterYearTo,
    int? openAccessOnly,
    String? sortOption,
  }) async {
    final cleanKeyword = keyword.trim();
    if (cleanKeyword.isEmpty) return;

    await _safely(() async {
      await _ensureCollectionEnabled();

      final parameters = <String, Object>{
        'keyword': _analyticsString(cleanKeyword),
      };
      if (resultCount != null) parameters['result_count'] = resultCount;
      if (searchSource != null) {
        parameters['search_source'] = _analyticsString(searchSource);
      }
      if (topicId != null) parameters['topic_id'] = _analyticsString(topicId);
      if (hasValidTopic != null) {
        parameters['has_valid_topic'] = hasValidTopic;
      }
      if (filterYearFrom != null) {
        parameters['filter_year_from'] = filterYearFrom;
      }
      if (filterYearTo != null) parameters['filter_year_to'] = filterYearTo;
      if (openAccessOnly != null) {
        parameters['open_access_only'] = openAccessOnly;
      }
      if (sortOption != null) {
        parameters['sort_option'] = _analyticsString(sortOption);
      }

      await _analytics.logEvent(name: 'search_topic', parameters: parameters);

      debugPrint('''
[Analytics] search_topic logged
  User UID: ${_activeUser?.uid ?? 'anonymous'}
  Keyword: $cleanKeyword
  Source: ${searchSource ?? 'unknown'}
  Results: ${resultCount ?? 'unknown'}
''');
    });
  }

  @override
  Future<void> logViewPublication({
    required String publicationTitle,
    required int? publicationYear,
  }) async {
    final cleanTitle = publicationTitle.trim();
    if (cleanTitle.isEmpty) return;

    await _safely(() async {
      await _ensureCollectionEnabled();

      final parameters = <String, Object>{
        'publication_title': _analyticsString(cleanTitle),
      };
      if (publicationYear != null) {
        parameters['publication_year'] = publicationYear;
      }

      await _analytics.logEvent(
        name: 'view_publication',
        parameters: parameters,
      );

      debugPrint('''
[Analytics] view_publication logged
  User UID: ${_activeUser?.uid ?? 'anonymous'}
  Publication: $cleanTitle
  Year: $publicationYear
''');
    });
  }

  @override
  Future<void> logViewKeyword({required String keyword}) async {
    final cleanKeyword = keyword.trim();
    if (cleanKeyword.isEmpty) return;

    await _safely(() async {
      await _ensureCollectionEnabled();

      final user = _activeUser;

      await _analytics.logEvent(
        name: 'view_keyword',
        parameters: {'keyword': _analyticsString(cleanKeyword)},
      );

      debugPrint('''
[Analytics] view_keyword logged
  Viewer UID: ${user?.uid ?? 'anonymous'}
  Keyword: $cleanKeyword
''');
    });
  }

  @override
  Future<void> logPdfExport({
    required String topic,
    required String exportType,
    required String provider,
    required String bucket,
    required String fileName,
    required int sizeBytes,
    required int hasUploadedLink,
  }) async {
    final cleanTopic = topic.trim();
    if (cleanTopic.isEmpty) return;

    await _safely(() async {
      await _ensureCollectionEnabled();

      final parameters = <String, Object>{
        'topic': _analyticsString(cleanTopic),
        'export_type': _analyticsString(exportType),
        'provider': _analyticsString(provider),
        'bucket': _analyticsString(bucket),
        'file_name': _analyticsString(fileName),
        'size_bytes': sizeBytes,
        'has_uploaded_link': hasUploadedLink,
      };

      await _analytics.logEvent(name: 'pdf_export', parameters: parameters);

      debugPrint('''
[Analytics] pdf_export logged
  User UID: ${_activeUser?.uid ?? 'anonymous'}
  Topic: $cleanTopic
  Export type: $exportType
  Provider: $provider
  File: $fileName
  Size bytes: $sizeBytes
''');
    });
  }

  Future<void> _ensureCollectionEnabled() {
    return _enableCollectionFuture ??= _analytics.setAnalyticsCollectionEnabled(
      true,
    );
  }

  String _analyticsString(String value) {
    final normalized = value.trim();
    if (normalized.length <= 100) {
      return normalized;
    }
    return normalized.substring(0, 100);
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
