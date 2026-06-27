import '../../models/report/report_upload_result.dart';
import '../../models/report/uploaded_report.dart';

abstract class ReportMetadataService {
  Future<void> saveUploadedReport({
    required ReportUploadResult uploadResult,
    required String topic,
    String? userId,
  });

  Future<List<UploadedReport>> fetchUploadedReports({
    required String userId,
    int limit = 20,
  });
}

class NoOpReportMetadataService implements ReportMetadataService {
  const NoOpReportMetadataService();

  @override
  Future<void> saveUploadedReport({
    required ReportUploadResult uploadResult,
    required String topic,
    String? userId,
  }) async {}

  @override
  Future<List<UploadedReport>> fetchUploadedReports({
    required String userId,
    int limit = 20,
  }) async {
    return const [];
  }
}
