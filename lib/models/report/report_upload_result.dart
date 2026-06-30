class ReportUploadResult {
  final String provider;
  final String bucket;
  final String objectKey;
  final String fileName;
  final String downloadUrl;
  final int sizeBytes;
  final DateTime uploadedAt;

  const ReportUploadResult({
    required this.provider,
    required this.bucket,
    required this.objectKey,
    required this.fileName,
    required this.downloadUrl,
    required this.sizeBytes,
    required this.uploadedAt,
  });
}
