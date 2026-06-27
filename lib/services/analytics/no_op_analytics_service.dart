import '../../models/auth/app_user.dart';
import 'app_analytics_service.dart';

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
  }) async {}

  @override
  Future<void> logViewKeyword({required String keyword}) async {}

  @override
  Future<void> logViewPublication({
    required String publicationTitle,
    required int? publicationYear,
  }) async {}

  @override
  Future<void> logPdfExport({
    required String topic,
    required String exportType,
    required String provider,
    required String bucket,
    required String fileName,
    required int sizeBytes,
    required int hasUploadedLink,
  }) async {}
}
