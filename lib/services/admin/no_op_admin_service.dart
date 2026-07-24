import '../../models/admin/admin_dashboard_stats.dart';
import '../../models/admin/admin_user_summary.dart';
import '../../models/report/uploaded_report.dart';
import 'admin_service.dart';

class NoOpAdminService implements AdminService {
  const NoOpAdminService();

  @override
  Future<AdminUsersPage> listUsers({String? pageToken}) async {
    return (users: const <AdminUserSummary>[], nextPageToken: null);
  }

  @override
  Future<void> setUserDisabled({
    required String uid,
    required bool disabled,
  }) async {}

  @override
  Future<void> setUserRole({
    required String uid,
    required bool isAdmin,
  }) async {}

  @override
  Future<({int? maxJournalsDisplayed, int? maxKeywordsDisplayed})>
  getRemoteConfigValues() async {
    return (maxJournalsDisplayed: null, maxKeywordsDisplayed: null);
  }

  @override
  Future<void> updateRemoteConfigValues({
    int? maxJournalsDisplayed,
    int? maxKeywordsDisplayed,
  }) async {}

  @override
  Future<void> sendBroadcastNotification({
    required String title,
    required String body,
  }) async {}

  @override
  Future<AdminReportsPage> listAllReports({
    int limit = 20,
    String? cursor,
  }) async {
    return (reports: const <UploadedReport>[], nextCursor: null);
  }

  @override
  Future<AdminDashboardStats> getDashboardStats() async {
    return const AdminDashboardStats(
      totalUsers: 0,
      totalAdmins: 0,
      totalReports: 0,
    );
  }
}
