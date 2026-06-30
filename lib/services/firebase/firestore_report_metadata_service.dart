import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/report/report_upload_result.dart';
import '../../models/report/uploaded_report.dart';
import '../report/report_metadata_service.dart';

class FirestoreReportMetadataService implements ReportMetadataService {
  static const collectionName = 'uploaded_pdf_reports';

  final FirebaseFirestore _firestore;

  const FirestoreReportMetadataService({required FirebaseFirestore firestore})
    : _firestore = firestore;

  @override
  Future<void> saveUploadedReport({
    required ReportUploadResult uploadResult,
    required String topic,
    String? userId,
  }) async {
    await _firestore.collection(collectionName).add({
      'userId': userId,
      'topic': topic,
      'provider': uploadResult.provider,
      'bucket': uploadResult.bucket,
      'objectKey': uploadResult.objectKey,
      'fileName': uploadResult.fileName,
      'downloadUrl': uploadResult.downloadUrl,
      'sizeBytes': uploadResult.sizeBytes,
      'uploadedAt': Timestamp.fromDate(uploadResult.uploadedAt.toUtc()),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<List<UploadedReport>> fetchUploadedReports({
    required String userId,
    int limit = 20,
  }) async {
    final snapshot = await _firestore
        .collection(collectionName)
        .where('userId', isEqualTo: userId)
        .limit(limit)
        .get();
    final reports = snapshot.docs
        .map((document) => _mapDocument(document))
        .whereType<UploadedReport>()
        .toList();

    reports.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
    return reports;
  }

  UploadedReport? _mapDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final downloadUrl = _stringValue(data['downloadUrl']);
    if (downloadUrl.isEmpty) return null;

    return UploadedReport(
      id: document.id,
      userId: _nullableStringValue(data['userId']),
      topic: _stringValue(data['topic'], fallback: 'Unknown topic'),
      provider: _stringValue(data['provider'], fallback: 'unknown'),
      bucket: _stringValue(data['bucket']),
      objectKey: _stringValue(data['objectKey']),
      fileName: _stringValue(data['fileName'], fallback: 'report.pdf'),
      downloadUrl: downloadUrl,
      sizeBytes: _intValue(data['sizeBytes']),
      uploadedAt: _dateTimeValue(data['uploadedAt']),
    );
  }

  static String _stringValue(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? fallback : text;
  }

  static String? _nullableStringValue(Object? value) {
    final text = _stringValue(value);
    return text.isEmpty ? null : text;
  }

  static int _intValue(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime _dateTimeValue(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
