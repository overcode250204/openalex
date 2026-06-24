import '../../models/auth/app_user.dart';

abstract interface class AppAnalyticsService {
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
}
