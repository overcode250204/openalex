import '../../models/auth/app_user.dart';

abstract interface class AppAnalyticsService {
  static const String googleAuthMethod = 'google';

  Future<void> logLogin({required AppUser user, required String method});

  Future<void> logLogout({required AppUser? user, required String method});

  Future<void> clearUser();

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
  });
  Future<void> logViewKeyword({required String keyword});
  Future<void> logViewPublication({
    required String publicationTitle,
    required int? publicationYear,
  });

  /// Fires when a user selects and views a journal.
  Future<void> logViewJournal({
    required String journalName,
    required String journalId,
    int? worksCount,
    int? citedByCount,
  });

  /// Fires when a user successfully exports a PDF / Markdown trend report.
  Future<void> logExportPdf({
    required String topic,
    required int publicationCount,
  });
}
