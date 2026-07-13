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

  Future<void> logViewJournal({required String journalName});

  Future<void> logViewPublication({
    required String publicationTitle,
    required int? publicationYear,
  });

  Future<void> logExportPdf({
    required String topic,
    required int publicationCount,
  });

  /// Fires when a generated dashboard PDF is uploaded to report storage.
  Future<void> logPdfExport({
    required String topic,
    required String exportType,
    required String provider,
    required String bucket,
    required String fileName,
    required int sizeBytes,
    required int hasUploadedLink,
  });
}
