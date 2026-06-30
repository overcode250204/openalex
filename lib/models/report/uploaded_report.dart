class UploadedReport {
  final String id;
  final String? userId;
  final String topic;
  final String provider;
  final String bucket;
  final String objectKey;
  final String fileName;
  final String downloadUrl;
  final int sizeBytes;
  final DateTime uploadedAt;

  const UploadedReport({
    required this.id,
    required this.userId,
    required this.topic,
    required this.provider,
    required this.bucket,
    required this.objectKey,
    required this.fileName,
    required this.downloadUrl,
    required this.sizeBytes,
    required this.uploadedAt,
  });
}
