class ReportStorageConfig {
  final String accessKeyId;
  final String secretAccessKey;
  final String region;
  final String bucket;
  final String? publicBaseUrl;
  final String? sessionToken;
  final String? endpointHost;

  const ReportStorageConfig({
    required this.accessKeyId,
    required this.secretAccessKey,
    required this.region,
    required this.bucket,
    this.publicBaseUrl,
    this.sessionToken,
    this.endpointHost,
  });

  factory ReportStorageConfig.fromEnv(Map<String, String> env) {
    return ReportStorageConfig(
      accessKeyId: env['AWS_ACCESS_KEY_ID'] ?? '',
      secretAccessKey: env['AWS_SECRET_ACCESS_KEY'] ?? '',
      region: env['AWS_REGION'] ?? '',
      bucket: env['AWS_S3_BUCKET'] ?? '',
      publicBaseUrl: _blankToNull(env['AWS_S3_PUBLIC_BASE_URL']),
      sessionToken: _blankToNull(env['AWS_SESSION_TOKEN']),
      endpointHost: _blankToNull(env['AWS_S3_ENDPOINT_HOST']),
    );
  }

  bool get isConfigured {
    return accessKeyId.trim().isNotEmpty &&
        secretAccessKey.trim().isNotEmpty &&
        region.trim().isNotEmpty &&
        bucket.trim().isNotEmpty;
  }

  void validate() {
    if (isConfigured) return;

    final missing = <String>[
      if (accessKeyId.trim().isEmpty) 'AWS_ACCESS_KEY_ID',
      if (secretAccessKey.trim().isEmpty) 'AWS_SECRET_ACCESS_KEY',
      if (region.trim().isEmpty) 'AWS_REGION',
      if (bucket.trim().isEmpty) 'AWS_S3_BUCKET',
    ];

    throw StateError(
      'Missing report storage configuration: ${missing.join(', ')}',
    );
  }

  String get resolvedEndpointHost {
    final customHost = endpointHost?.trim();
    if (customHost != null && customHost.isNotEmpty) {
      return customHost;
    }

    return region == 'us-east-1'
        ? '$bucket.s3.amazonaws.com'
        : '$bucket.s3.$region.amazonaws.com';
  }

  String get resolvedPublicBaseUrl {
    final customBaseUrl = publicBaseUrl?.trim();
    if (customBaseUrl != null && customBaseUrl.isNotEmpty) {
      return customBaseUrl.replaceAll(RegExp(r'/+$'), '');
    }

    return 'https://$resolvedEndpointHost';
  }

  static String? _blankToNull(String? value) {
    final normalized = value?.trim();

    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    return normalized;
  }
}
