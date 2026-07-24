import '../../models/admin/admin_dashboard_stats.dart';
import '../../models/admin/admin_user_summary.dart';
import '../../models/report/uploaded_report.dart';

typedef AdminUsersPage = ({List<AdminUserSummary> users, String? nextPageToken});
typedef AdminReportsPage = ({List<UploadedReport> reports, String? nextCursor});

abstract interface class AdminService {
  Future<AdminUsersPage> listUsers({String? pageToken});

  Future<void> setUserDisabled({required String uid, required bool disabled});

  Future<void> setUserRole({required String uid, required bool isAdmin});

  Future<({int? maxJournalsDisplayed, int? maxKeywordsDisplayed})>
  getRemoteConfigValues();

  Future<void> updateRemoteConfigValues({
    int? maxJournalsDisplayed,
    int? maxKeywordsDisplayed,
  });

  Future<void> sendBroadcastNotification({
    required String title,
    required String body,
  });

  Future<AdminReportsPage> listAllReports({int limit = 20, String? cursor});

  Future<AdminDashboardStats> getDashboardStats();
}
