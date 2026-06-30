import 'dart:typed_data';

import '../../models/report/report_upload_result.dart';

abstract class ReportStorageService {
  Future<ReportUploadResult> uploadReport({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
    required String topic,
    DateTime? uploadedAt,
  });
}
