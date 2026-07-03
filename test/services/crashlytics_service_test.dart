import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/services/firebase/crashlytics_service.dart';

class _RecordedError {
  const _RecordedError({
    required this.error,
    required this.stackTrace,
    required this.reason,
    required this.information,
    required this.fatal,
  });

  final Object error;
  final StackTrace? stackTrace;
  final String? reason;
  final List<Object> information;
  final bool fatal;
}

class _FakeCrashlyticsClient implements CrashlyticsClient {
  bool? collectionEnabled;
  var crashCount = 0;
  final recordedErrors = <_RecordedError>[];
  final recordedFlutterErrors = <FlutterErrorDetails>[];

  @override
  Future<void> setCrashlyticsCollectionEnabled(bool enabled) async {
    collectionEnabled = enabled;
  }

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    Iterable<Object> information = const [],
    bool fatal = false,
  }) async {
    recordedErrors.add(
      _RecordedError(
        error: error,
        stackTrace: stackTrace,
        reason: reason,
        information: information.toList(),
        fatal: fatal,
      ),
    );
  }

  @override
  Future<void> recordFlutterFatalError(FlutterErrorDetails details) async {
    recordedFlutterErrors.add(details);
  }

  @override
  Future<void> crash() async {
    crashCount++;
  }
}

void main() {
  group('FirebaseCrashlyticsService', () {
    test('initialization enables Crashlytics collection', () async {
      final client = _FakeCrashlyticsClient();
      final service = FirebaseCrashlyticsService(
        client: client,
        isSupported: true,
        installGlobalHandlers: false,
      );

      await service.initialize();

      expect(service.isInitialized, isTrue);
      expect(client.collectionEnabled, isTrue);
    });

    test('handled errors can be recorded', () async {
      final client = _FakeCrashlyticsClient();
      final service = FirebaseCrashlyticsService(
        client: client,
        isSupported: true,
        installGlobalHandlers: false,
      );
      final error = StateError('handled failure');
      final stackTrace = StackTrace.current;

      await service.recordError(
        error,
        stackTrace,
        reason: 'search_topic failed',
        information: const ['topic=AI'],
      );

      expect(service.isInitialized, isTrue);
      expect(client.recordedErrors, hasLength(1));
      expect(client.recordedErrors.single.error, same(error));
      expect(client.recordedErrors.single.stackTrace, same(stackTrace));
      expect(client.recordedErrors.single.reason, 'search_topic failed');
      expect(client.recordedErrors.single.information, ['topic=AI']);
      expect(client.recordedErrors.single.fatal, isFalse);
    });

    test(
      'demo handled exception records a non-fatal Crashlytics event',
      () async {
        final client = _FakeCrashlyticsClient();
        final service = FirebaseCrashlyticsService(
          client: client,
          isSupported: true,
          installGlobalHandlers: false,
        );

        await service.recordDemoHandledException();

        expect(client.recordedErrors, hasLength(1));
        expect(client.recordedErrors.single.error, isA<StateError>());
        expect(
          client.recordedErrors.single.reason,
          'Developer demo: handled exception button',
        );
        expect(
          client.recordedErrors.single.information,
          contains('action=record_handled_exception'),
        );
        expect(client.recordedErrors.single.fatal, isFalse);
      },
    );

    test(
      'demo test crash records fatal evidence then triggers crash',
      () async {
        final client = _FakeCrashlyticsClient();
        final service = FirebaseCrashlyticsService(
          client: client,
          isSupported: true,
          installGlobalHandlers: false,
        );

        await service.triggerDemoCrash();

        expect(client.recordedErrors, hasLength(1));
        expect(client.recordedErrors.single.error, isA<StateError>());
        expect(
          client.recordedErrors.single.reason,
          'Developer demo: test crash button',
        );
        expect(
          client.recordedErrors.single.information,
          contains('action=test_crash'),
        );
        expect(client.recordedErrors.single.fatal, isTrue);
        expect(client.crashCount, 1);
      },
    );

    test('unsupported platforms initialize as a safe no-op', () async {
      final client = _FakeCrashlyticsClient();
      final service = FirebaseCrashlyticsService(
        client: client,
        isSupported: false,
        installGlobalHandlers: false,
      );

      await service.initialize();
      await service.recordError(StateError('ignored'), StackTrace.current);

      expect(service.isInitialized, isTrue);
      expect(client.collectionEnabled, isNull);
      expect(client.recordedErrors, isEmpty);
    });
  });
}
