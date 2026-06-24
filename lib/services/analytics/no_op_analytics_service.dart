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
  Future<void> logSearchTopic(String keyword) async {}

  @override
  Future<void> logViewPublication({
    required String publicationTitle,
    required int? publicationYear,
  }) async {}
}
