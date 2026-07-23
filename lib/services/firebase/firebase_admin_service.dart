import 'package:cloud_functions/cloud_functions.dart';

import '../../models/admin/admin_dashboard_stats.dart';
import '../../models/admin/admin_user_summary.dart';
import '../../models/report/uploaded_report.dart';
import '../admin/admin_service.dart';

class FirebaseAdminService implements AdminService {
  FirebaseAdminService({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  @override
  Future<AdminUsersPage> listUsers({String? pageToken}) async {
    final result = await _functions.httpsCallable('adminListUsers').call({
      if (pageToken != null) 'pageToken': pageToken,
    });
    final data = Map<String, dynamic>.from(result.data as Map);
    final users = (data['users'] as List)
        .map((e) => AdminUserSummary.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return (users: users, nextPageToken: data['nextPageToken'] as String?);
  }

  @override
  Future<void> setUserDisabled({
    required String uid,
    required bool disabled,
  }) async {
    await _functions.httpsCallable('adminSetUserDisabled').call({
      'uid': uid,
      'disabled': disabled,
    });
  }

  @override
  Future<void> setUserRole({
    required String uid,
    required bool isAdmin,
  }) async {
    await _functions.httpsCallable('adminSetUserRole').call({
      'uid': uid,
      'role': isAdmin ? 'admin' : 'user',
    });
  }

  @override
  Future<({int? maxJournalsDisplayed, int? maxKeywordsDisplayed})>
  getRemoteConfigValues() async {
    final result = await _functions
        .httpsCallable('adminGetRemoteConfigValues')
        .call();
    final data = Map<String, dynamic>.from(result.data as Map);
    return (
      maxJournalsDisplayed: (data['maxJournalsDisplayed'] as num?)?.toInt(),
      maxKeywordsDisplayed: (data['maxKeywordsDisplayed'] as num?)?.toInt(),
    );
  }

  @override
  Future<void> updateRemoteConfigValues({
    int? maxJournalsDisplayed,
    int? maxKeywordsDisplayed,
  }) async {
    await _functions.httpsCallable('adminUpdateRemoteConfigValues').call({
      if (maxJournalsDisplayed != null)
        'maxJournalsDisplayed': maxJournalsDisplayed,
      if (maxKeywordsDisplayed != null)
        'maxKeywordsDisplayed': maxKeywordsDisplayed,
    });
  }

  @override
  Future<void> sendBroadcastNotification({
    required String title,
    required String body,
  }) async {
    await _functions.httpsCallable('adminSendBroadcastNotification').call({
      'title': title,
      'body': body,
    });
  }

  @override
  Future<AdminReportsPage> listAllReports({
    int limit = 20,
    String? cursor,
  }) async {
    final result = await _functions.httpsCallable('adminListAllReports').call(
      {'limit': limit, if (cursor != null) 'cursor': cursor},
    );
    final data = Map<String, dynamic>.from(result.data as Map);
    final reports = (data['reports'] as List)
        .map((e) => _reportFromJson(Map<String, dynamic>.from(e)))
        .toList();
    return (reports: reports, nextCursor: data['nextCursor'] as String?);
  }

  @override
  Future<AdminDashboardStats> getDashboardStats() async {
    final result = await _functions
        .httpsCallable('adminGetDashboardStats')
        .call();
    return AdminDashboardStats.fromJson(
      Map<String, dynamic>.from(result.data as Map),
    );
  }

  UploadedReport _reportFromJson(Map<String, dynamic> json) {
    final uploadedAtRaw = json['uploadedAt'] as String?;
    return UploadedReport(
      id: json['id'] as String,
      userId: json['userId'] as String?,
      topic: json['topic'] as String? ?? '',
      provider: json['provider'] as String? ?? '',
      bucket: json['bucket'] as String? ?? '',
      objectKey: json['objectKey'] as String? ?? '',
      fileName: json['fileName'] as String? ?? '',
      downloadUrl: json['downloadUrl'] as String? ?? '',
      sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
      uploadedAt: uploadedAtRaw != null
          ? (DateTime.tryParse(uploadedAtRaw) ?? DateTime.fromMillisecondsSinceEpoch(0))
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
