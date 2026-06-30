import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openalex/models/report/report_storage_config.dart';
import 'package:openalex/services/report/s3_report_storage_service.dart';

void main() {
  group('S3ReportStorageService', () {
    test('uploads report bytes using a signed S3 PUT request', () async {
      late http.Request capturedRequest;
      final service = S3ReportStorageService(
        config: _config(),
        client: MockClient((request) async {
          capturedRequest = request;

          return http.Response('', 200);
        }),
      );

      final result = await service.uploadReport(
        bytes: Uint8List.fromList([1, 2, 3]),
        fileName: 'Trend Report AI.pdf',
        contentType: 'application/pdf',
        topic: 'Artificial Intelligence',
        uploadedAt: DateTime.utc(2026, 6, 25, 14, 20, 30),
      );

      expect(capturedRequest.method, 'PUT');
      expect(
        capturedRequest.url.toString(),
        'https://journal-reports.s3.ap-southeast-1.amazonaws.com/'
        'reports/artificial-intelligence/'
        '20260625-142030-trend-report-ai.pdf',
      );
      expect(capturedRequest.headers['Content-Type'], 'application/pdf');
      expect(capturedRequest.headers['X-Amz-Date'], '20260625T142030Z');
      expect(
        capturedRequest.headers['Authorization'],
        startsWith('AWS4-HMAC-SHA256'),
      );
      expect(
        capturedRequest.headers['Authorization'],
        contains(
          'Credential=AKIA_TEST/20260625/ap-southeast-1/s3/aws4_request',
        ),
      );
      expect(
        capturedRequest.headers['Authorization'],
        contains(
          'SignedHeaders=content-type;host;x-amz-content-sha256;x-amz-date',
        ),
      );
      expect(result.provider, 's3');
      expect(result.bucket, 'journal-reports');
      expect(
        result.objectKey,
        'reports/artificial-intelligence/20260625-142030-trend-report-ai.pdf',
      );
      expect(
        result.downloadUrl,
        'https://journal-reports.s3.ap-southeast-1.amazonaws.com/'
        'reports/artificial-intelligence/'
        '20260625-142030-trend-report-ai.pdf',
      );
      expect(result.sizeBytes, 3);
    });

    test(
      'derives download URL when public base URL is not configured',
      () async {
        final service = S3ReportStorageService(
          config: const ReportStorageConfig(
            accessKeyId: 'AKIA_TEST',
            secretAccessKey: 'secret',
            region: 'ap-southeast-1',
            bucket: 'journal-reports',
          ),
          client: MockClient((request) async => http.Response('', 200)),
        );

        final result = await service.uploadReport(
          bytes: Uint8List.fromList([1, 2, 3]),
          fileName: 'report.pdf',
          contentType: 'application/pdf',
          topic: 'AI',
          uploadedAt: DateTime.utc(2026, 6, 25),
        );

        expect(
          result.downloadUrl,
          'https://journal-reports.s3.ap-southeast-1.amazonaws.com/'
          'reports/ai/20260625-000000-report.pdf',
        );
      },
    );

    test('throws a domain exception when S3 rejects the upload', () async {
      final service = S3ReportStorageService(
        config: _config(),
        client: MockClient((request) async {
          return http.Response('AccessDenied', 403);
        }),
      );

      await expectLater(
        service.uploadReport(
          bytes: Uint8List.fromList([1, 2, 3]),
          fileName: 'report.pdf',
          contentType: 'application/pdf',
          topic: 'AI',
          uploadedAt: DateTime.utc(2026, 6, 25),
        ),
        throwsA(
          isA<S3ReportStorageException>().having(
            (error) => error.statusCode,
            'statusCode',
            403,
          ),
        ),
      );
    });

    test('validates storage config before uploading', () async {
      final service = S3ReportStorageService(
        config: ReportStorageConfig.fromEnv(const {}),
        client: MockClient((request) async => http.Response('', 200)),
      );

      await expectLater(
        service.uploadReport(
          bytes: Uint8List.fromList([1, 2, 3]),
          fileName: 'report.pdf',
          contentType: 'application/pdf',
          topic: 'AI',
        ),
        throwsStateError,
      );
    });
  });
}

ReportStorageConfig _config() {
  return const ReportStorageConfig(
    accessKeyId: 'AKIA_TEST',
    secretAccessKey: 'secret',
    region: 'ap-southeast-1',
    bucket: 'journal-reports',
    publicBaseUrl: 'https://journal-reports.s3.ap-southeast-1.amazonaws.com',
  );
}
