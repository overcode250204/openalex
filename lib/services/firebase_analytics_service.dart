import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class FirebaseAnalyticsService {
  FirebaseAnalyticsService({FirebaseAnalytics? analytics})
    : _analytics = analytics ?? FirebaseAnalytics.instance;

  @visibleForTesting
  FirebaseAnalyticsService.testing() : _analytics = null;

  final FirebaseAnalytics? _analytics;

  /// Event: search_topic
  Future<void> logSearchTopic(String keyword) async {
    final cleanKeyword = keyword.trim();

    if (cleanKeyword.isEmpty) {
      return;
    }

    try {
      await _analytics!.logEvent(
        name: 'search_topic',
        parameters: {'keyword': cleanKeyword},
      );
    } catch (_) {
      // Firebase Analytics lỗi không được làm hỏng chức năng chính.
    }
  }

  /// Event: view_publication
  Future<void> logViewPublication({
    required String publicationTitle,
    required int? publicationYear,
  }) async {
    final cleanTitle = publicationTitle.trim();

    // Ticket requires both title and year.
    if (cleanTitle.isEmpty || publicationYear == null) {
      return;
    }

    try {
      await _analytics!.logEvent(
        name: 'view_publication',
        parameters: {
          'publication_title': cleanTitle,
          'publication_year': publicationYear,
        },
      );
    } catch (_) {
      // Analytics must not break Publication Detail.
    }
  }
}
