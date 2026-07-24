import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../models/admin/admin_dashboard_stats.dart';
import '../../models/admin/admin_user_summary.dart';
import '../../models/report/uploaded_report.dart';
import '../admin/admin_service.dart';
import 'admin_api_exception.dart';

/// Talks to admin_server (a standalone Node/Express backend hosted outside
/// Firebase) instead of Cloud Functions, so the admin dashboard works
/// without the project being on the Blaze plan. Same AdminService contract
/// and the same server-side admin_roles/{uid} check happens on the server —
/// this class is purely a transport swap.
class HttpAdminService implements AdminService {
  HttpAdminService({required String baseUrl, http.Client? client})
    : _baseUrl = baseUrl.endsWith('/')
          ? baseUrl.substring(0, baseUrl.length - 1)
          : baseUrl,
      _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;

  Future<Map<String, dynamic>> _post(
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw const AdminApiException('unauthenticated', 'Sign-in required.');
    }
    final token = await user.getIdToken();

    final response = await _client.post(
      Uri.parse('$_baseUrl/admin/$path'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body ?? const {}),
    );

    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 400) {
      final error = decoded['error'] as Map<String, dynamic>?;
      throw AdminApiException(
        error?['code'] as String? ?? 'unknown',
        error?['message'] as String? ?? 'Request failed.',
      );
    }

    return decoded;
  }

  @override
  Future<AdminUsersPage> listUsers({String? pageToken}) async {
    final data = await _post('listUsers', {
      if (pageToken != null) 'pageToken': pageToken,
    });
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
    await _post('setUserDisabled', {'uid': uid, 'disabled': disabled});
  }

  @override
  Future<void> setUserRole({
    required String uid,
    required bool isAdmin,
  }) async {
    await _post('setUserRole', {'uid': uid, 'role': isAdmin ? 'admin' : 'user'});
  }

  @override
  Future<({int? maxJournalsDisplayed, int? maxKeywordsDisplayed})>
  getRemoteConfigValues() async {
    final data = await _post('getRemoteConfigValues');
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
    await _post('updateRemoteConfigValues', {
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
    await _post('sendBroadcastNotification', {'title': title, 'body': body});
  }

  @override
  Future<AdminReportsPage> listAllReports({
    int limit = 20,
    String? cursor,
  }) async {
    final data = await _post('listAllReports', {
      'limit': limit,
      if (cursor != null) 'cursor': cursor,
    });
    final reports = (data['reports'] as List)
        .map((e) => _reportFromJson(Map<String, dynamic>.from(e)))
        .toList();
    return (reports: reports, nextCursor: data['nextCursor'] as String?);
  }

  @override
  Future<AdminDashboardStats> getDashboardStats() async {
    final data = await _post('getDashboardStats');
    return AdminDashboardStats.fromJson(data);
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
          ? (DateTime.tryParse(uploadedAtRaw) ??
                DateTime.fromMillisecondsSinceEpoch(0))
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
