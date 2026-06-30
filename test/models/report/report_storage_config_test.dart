import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/models/report/report_storage_config.dart';

void main() {
  group('ReportStorageConfig', () {
    test('reads S3 configuration from env values', () {
      final config = ReportStorageConfig.fromEnv(const {
        'AWS_ACCESS_KEY_ID': 'access-key',
        'AWS_SECRET_ACCESS_KEY': 'secret-key',
        'AWS_REGION': 'ap-southeast-1',
        'AWS_S3_BUCKET': 'journal-reports',
      });

      expect(config.isConfigured, isTrue);
      expect(config.accessKeyId, 'access-key');
      expect(config.secretAccessKey, 'secret-key');
      expect(config.region, 'ap-southeast-1');
      expect(config.bucket, 'journal-reports');
      expect(config.publicBaseUrl, isNull);
      expect(
        config.resolvedEndpointHost,
        'journal-reports.s3.ap-southeast-1.amazonaws.com',
      );
      expect(
        config.resolvedPublicBaseUrl,
        'https://journal-reports.s3.ap-southeast-1.amazonaws.com',
      );
    });

    test('reports missing required values during validation', () {
      final config = ReportStorageConfig.fromEnv(const {
        'AWS_REGION': 'ap-southeast-1',
      });

      expect(config.isConfigured, isFalse);
      expect(
        config.validate,
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('AWS_ACCESS_KEY_ID'),
          ),
        ),
      );
    });

    test('uses custom endpoint host when provided', () {
      final config = ReportStorageConfig.fromEnv(const {
        'AWS_ACCESS_KEY_ID': 'access-key',
        'AWS_SECRET_ACCESS_KEY': 'secret-key',
        'AWS_REGION': 'auto',
        'AWS_S3_BUCKET': 'journal-reports',
        'AWS_S3_PUBLIC_BASE_URL': 'https://cdn.example.com',
        'AWS_S3_ENDPOINT_HOST': 'account-id.r2.cloudflarestorage.com',
      });

      expect(
        config.resolvedEndpointHost,
        'account-id.r2.cloudflarestorage.com',
      );
      expect(config.resolvedPublicBaseUrl, 'https://cdn.example.com');
    });
  });
}
