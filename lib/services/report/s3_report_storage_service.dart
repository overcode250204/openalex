import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../../models/report/report_storage_config.dart';
import '../../models/report/report_upload_result.dart';
import 'report_storage_service.dart';

class S3ReportStorageService implements ReportStorageService {
  static const providerName = 's3';

  final ReportStorageConfig _config;
  final http.Client _client;

  const S3ReportStorageService({
    required ReportStorageConfig config,
    required http.Client client,
  }) : _config = config,
       _client = client;

  @override
  Future<ReportUploadResult> uploadReport({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
    required String topic,
    DateTime? uploadedAt,
  }) async {
    _config.validate();

    final timestamp = (uploadedAt ?? DateTime.now()).toUtc();
    final objectKey = _buildObjectKey(
      topic: topic,
      fileName: fileName,
      uploadedAt: timestamp,
    );
    final path = _encodedObjectPath(objectKey);
    final uri = Uri.https(_config.resolvedEndpointHost, path);
    final payloadHash = _sha256Hex(bytes);
    final headers = _signedHeaders(
      method: 'PUT',
      uri: uri,
      payloadHash: payloadHash,
      contentType: contentType,
      uploadedAt: timestamp,
    );

    final response = await _client.put(uri, headers: headers, body: bytes);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw S3ReportStorageException(
        statusCode: response.statusCode,
        message: response.body.isEmpty ? response.reasonPhrase : response.body,
      );
    }

    return ReportUploadResult(
      provider: providerName,
      bucket: _config.bucket,
      objectKey: objectKey,
      fileName: fileName,
      downloadUrl: _buildDownloadUrl(objectKey),
      sizeBytes: bytes.length,
      uploadedAt: timestamp,
    );
  }

  Map<String, String> _signedHeaders({
    required String method,
    required Uri uri,
    required String payloadHash,
    required String contentType,
    required DateTime uploadedAt,
  }) {
    final amzDate = _amzDate(uploadedAt);
    final dateStamp = _dateStamp(uploadedAt);
    final headers = <String, String>{
      'content-type': contentType,
      'host': uri.host,
      'x-amz-content-sha256': payloadHash,
      'x-amz-date': amzDate,
      if (_config.sessionToken != null)
        'x-amz-security-token': _config.sessionToken!,
    };
    final signedHeaderNames = headers.keys.toList()..sort();
    final signedHeaders = signedHeaderNames.join(';');
    final canonicalHeaders = signedHeaderNames
        .map((name) => '$name:${headers[name]!.trim()}\n')
        .join();
    final canonicalRequest = [
      method,
      uri.path,
      '',
      canonicalHeaders,
      signedHeaders,
      payloadHash,
    ].join('\n');
    final credentialScope = '$dateStamp/${_config.region}/s3/aws4_request';
    final stringToSign = [
      'AWS4-HMAC-SHA256',
      amzDate,
      credentialScope,
      _sha256Hex(utf8.encode(canonicalRequest)),
    ].join('\n');
    final signingKey = _signingKey(dateStamp);
    final signature = _bytesToHex(
      Hmac(sha256, signingKey).convert(utf8.encode(stringToSign)).bytes,
    );

    return {
      'Content-Type': contentType,
      'Host': uri.host,
      'X-Amz-Content-Sha256': payloadHash,
      'X-Amz-Date': amzDate,
      if (_config.sessionToken != null)
        'X-Amz-Security-Token': _config.sessionToken!,
      'Authorization':
          'AWS4-HMAC-SHA256 '
          'Credential=${_config.accessKeyId}/$credentialScope, '
          'SignedHeaders=$signedHeaders, '
          'Signature=$signature',
    };
  }

  List<int> _signingKey(String dateStamp) {
    final dateKey = _hmac(
      utf8.encode('AWS4${_config.secretAccessKey}'),
      dateStamp,
    );
    final dateRegionKey = _hmac(dateKey, _config.region);
    final dateRegionServiceKey = _hmac(dateRegionKey, 's3');

    return _hmac(dateRegionServiceKey, 'aws4_request');
  }

  String _buildDownloadUrl(String objectKey) {
    final baseUrl = _config.resolvedPublicBaseUrl;
    final path = _encodedObjectPath(objectKey);

    return path.startsWith('/') ? '$baseUrl$path' : '$baseUrl/$path';
  }

  static String _buildObjectKey({
    required String topic,
    required String fileName,
    required DateTime uploadedAt,
  }) {
    final safeTopic = _slugify(topic, fallback: 'topic');
    final safeFileName = _sanitizeFileName(fileName);
    final timestamp = _compactTimestamp(uploadedAt);

    return 'reports/$safeTopic/$timestamp-$safeFileName';
  }

  static String _encodedObjectPath(String objectKey) {
    return Uri(pathSegments: objectKey.split('/')).path;
  }

  static String _sanitizeFileName(String value) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9._-]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');

    return normalized.isEmpty ? 'report.pdf' : normalized;
  }

  static String _slugify(String value, {required String fallback}) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');

    return normalized.isEmpty ? fallback : normalized;
  }

  static String _amzDate(DateTime value) {
    final utc = value.toUtc();

    return '${_dateStamp(utc)}T'
        '${_twoDigits(utc.hour)}'
        '${_twoDigits(utc.minute)}'
        '${_twoDigits(utc.second)}Z';
  }

  static String _dateStamp(DateTime value) {
    final utc = value.toUtc();

    return '${utc.year}'
        '${_twoDigits(utc.month)}'
        '${_twoDigits(utc.day)}';
  }

  static String _compactTimestamp(DateTime value) {
    final utc = value.toUtc();

    return '${utc.year}'
        '${_twoDigits(utc.month)}'
        '${_twoDigits(utc.day)}-'
        '${_twoDigits(utc.hour)}'
        '${_twoDigits(utc.minute)}'
        '${_twoDigits(utc.second)}';
  }

  static String _twoDigits(int number) => number.toString().padLeft(2, '0');

  static List<int> _hmac(List<int> key, String value) {
    return Hmac(sha256, key).convert(utf8.encode(value)).bytes;
  }

  static String _sha256Hex(List<int> bytes) {
    return _bytesToHex(sha256.convert(bytes).bytes);
  }

  static String _bytesToHex(List<int> bytes) {
    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }
}

class S3ReportStorageException implements Exception {
  final int statusCode;
  final String? message;

  const S3ReportStorageException({
    required this.statusCode,
    required this.message,
  });

  @override
  String toString() {
    final details = message?.trim();

    if (details == null || details.isEmpty) {
      return 'S3ReportStorageException: HTTP $statusCode';
    }

    return 'S3ReportStorageException: HTTP $statusCode - $details';
  }
}
