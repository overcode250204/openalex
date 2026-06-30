import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

abstract interface class AppCrashlyticsService {
  Future<void> initialize();

  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    Iterable<Object> information,
    bool fatal,
  });

  Future<void> recordDemoHandledException();
  Future<void> triggerDemoCrash();

  bool get isInitialized;
}

abstract interface class CrashlyticsClient {
  Future<void> setCrashlyticsCollectionEnabled(bool enabled);

  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    Iterable<Object> information,
    bool fatal,
  });

  Future<void> recordFlutterFatalError(FlutterErrorDetails details);

  Future<void> crash();
}

class FirebaseCrashlyticsClient implements CrashlyticsClient {
  FirebaseCrashlyticsClient({FirebaseCrashlytics? crashlytics})
    : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance;

  final FirebaseCrashlytics _crashlytics;

  @override
  Future<void> setCrashlyticsCollectionEnabled(bool enabled) {
    return _crashlytics.setCrashlyticsCollectionEnabled(enabled);
  }

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    Iterable<Object> information = const [],
    bool fatal = false,
  }) {
    return _crashlytics.recordError(
      error,
      stackTrace,
      reason: reason,
      information: information,
      fatal: fatal,
    );
  }

  @override
  Future<void> recordFlutterFatalError(FlutterErrorDetails details) {
    return _crashlytics.recordFlutterFatalError(details);
  }

  @override
  Future<void> crash() async {
    _crashlytics.crash();
  }
}

class FirebaseCrashlyticsService implements AppCrashlyticsService {
  FirebaseCrashlyticsService({
    CrashlyticsClient? client,
    bool? isSupported,
    this.installGlobalHandlers = true,
  }) : _client = client ?? FirebaseCrashlyticsClient(),
       _isSupported = isSupported ?? _defaultIsSupported;

  final CrashlyticsClient _client;
  final bool _isSupported;
  final bool installGlobalHandlers;

  bool _isInitialized = false;

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    _isInitialized = true;
    if (!_isSupported) return;

    await _client.setCrashlyticsCollectionEnabled(true);

    if (!installGlobalHandlers) return;

    final previousFlutterErrorHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      previousFlutterErrorHandler?.call(details);
      unawaited(_client.recordFlutterFatalError(details));
    };

    PlatformDispatcher.instance.onError = (error, stackTrace) {
      unawaited(recordError(error, stackTrace, fatal: true));
      return true;
    };
  }

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    Iterable<Object> information = const [],
    bool fatal = false,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!_isSupported) return;

    await _client.recordError(
      error,
      stackTrace,
      reason: reason,
      information: information,
      fatal: fatal,
    );
  }

  @override
  Future<void> recordDemoHandledException() {
    return recordError(
      StateError('Crashlytics demo handled exception'),
      StackTrace.current,
      reason: 'Developer demo: handled exception button',
      information: const [
        'source=profile_developer_tools',
        'action=record_handled_exception',
      ],
    );
  }

  @override
  Future<void> triggerDemoCrash() async {
    await recordError(
      StateError('Crashlytics demo test crash requested'),
      StackTrace.current,
      reason: 'Developer demo: test crash button',
      information: const [
        'source=profile_developer_tools',
        'action=test_crash',
      ],
      fatal: true,
    );

    if (!_isSupported) return;

    await _client.crash();
  }

  static bool get _defaultIsSupported {
    if (kIsWeb) return false;

    return switch (defaultTargetPlatform) {
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.macOS => true,
      TargetPlatform.fuchsia ||
      TargetPlatform.linux ||
      TargetPlatform.windows => false,
    };
  }
}

class NoOpCrashlyticsService implements AppCrashlyticsService {
  const NoOpCrashlyticsService();

  @override
  bool get isInitialized => true;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    Iterable<Object> information = const [],
    bool fatal = false,
  }) async {}

  @override
  Future<void> recordDemoHandledException() async {}

  @override
  Future<void> triggerDemoCrash() async {}
}
