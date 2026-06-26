import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/models/auth/app_user.dart';
import 'package:openalex/models/firebase/app_push_notification.dart';
import 'package:openalex/services/analytics/app_analytics_service.dart';
import 'package:openalex/services/firebase/cloud_messaging_service.dart';
import 'package:openalex/services/firebase/crashlytics_service.dart';
import 'package:openalex/services/firebase/remote_config_service.dart';
import 'package:openalex/viewmodels/auth_view_model.dart';
import 'package:openalex/viewmodels/cloud_messaging_view_model.dart';
import 'package:openalex/viewmodels/crashlytics_view_model.dart';
import 'package:openalex/viewmodels/remote_config_view_model.dart';

import '../fakes/fake_auth_service.dart';

class _RecordingAnalyticsService implements AppAnalyticsService {
  final events = <String>[];

  @override
  Future<void> logLogin({required AppUser user, required String method}) async {
    events.add('login:$method:${user.email}');
  }

  @override
  Future<void> logLogout({
    required AppUser? user,
    required String method,
  }) async {
    events.add('logout:$method:${user?.email}');
  }

  @override
  Future<void> clearUser() async {
    events.add('clear-user');
  }

  @override
  Future<void> logExportPdf({
    required String topic,
    required int publicationCount,
  }) async {}

  @override
  Future<void> logSearchTopic(
    String keyword, {
    int? resultCount,
    String? searchSource,
    String? topicId,
    int? hasValidTopic,
    int? filterYearFrom,
    int? filterYearTo,
    int? openAccessOnly,
    String? sortOption,
  }) async {}

  @override
  Future<void> logViewJournal({
    required String journalName,
    required String journalId,
    int? worksCount,
    int? citedByCount,
  }) async {}

  @override
  Future<void> logViewKeyword({required String keyword}) async {}

  @override
  Future<void> logViewPublication({
    required String publicationTitle,
    required int? publicationYear,
  }) async {}
}

class _MutableRemoteConfigService implements AppRemoteConfigService {
  _MutableRemoteConfigService({
    this.maxJournals = 10,
    this.maxKeywords = 5,
    this.nextMaxJournals,
    this.nextMaxKeywords,
  });

  int maxJournals;
  int maxKeywords;
  int? nextMaxJournals;
  int? nextMaxKeywords;
  int initializeCalls = 0;
  int fetchCalls = 0;

  @override
  int get maxJournalsDisplayed => maxJournals;

  @override
  int get maxKeywordsDisplayed => maxKeywords;

  @override
  Future<void> initialize() async {
    initializeCalls++;
  }

  @override
  Future<bool> fetchAndActivate() async {
    fetchCalls++;
    maxJournals = nextMaxJournals ?? maxJournals;
    maxKeywords = nextMaxKeywords ?? maxKeywords;
    return true;
  }
}

class _FakeCloudMessagingService implements CloudMessagingService {
  final foregroundController =
      StreamController<AppPushNotification>.broadcast();
  final openedController = StreamController<AppPushNotification>.broadcast();
  final tokenController = StreamController<String>.broadcast();

  int initializeCalls = 0;
  int requestPermissionCalls = 0;

  @override
  Stream<AppPushNotification> get foregroundNotifications =>
      foregroundController.stream;

  @override
  Stream<AppPushNotification> get openedAppNotifications =>
      openedController.stream;

  @override
  Stream<String> get tokenRefreshes => tokenController.stream;

  @override
  Future<CloudMessagingSnapshot> initialize() async {
    initializeCalls++;
    return CloudMessagingSnapshot(
      permissionStatus: CloudMessagingPermissionStatus.notDetermined,
      token: 'initial-token',
      backgroundNotifications: [
        _notification('stored', PushNotificationSource.background),
      ],
    );
  }

  @override
  Future<CloudMessagingPermissionStatus> requestPermission() async {
    requestPermissionCalls++;
    return CloudMessagingPermissionStatus.authorized;
  }

  @override
  Future<String?> getToken() async => 'authorized-token';

  Future<void> dispose() async {
    await foregroundController.close();
    await openedController.close();
    await tokenController.close();
  }
}

class _FakeCrashlyticsService implements AppCrashlyticsService {
  int initializeCalls = 0;
  int handledExceptionCalls = 0;
  int testCrashCalls = 0;
  bool throwOnHandledException = false;
  bool throwOnTestCrash = false;

  @override
  bool get isInitialized => initializeCalls > 0;

  @override
  Future<void> initialize() async {
    initializeCalls++;
  }

  @override
  Future<void> recordDemoHandledException() async {
    handledExceptionCalls++;
    if (throwOnHandledException) {
      throw StateError('handled exception failed');
    }
  }

  @override
  Future<void> triggerDemoCrash() async {
    testCrashCalls++;
    if (throwOnTestCrash) {
      throw StateError('test crash failed');
    }
  }

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    Iterable<Object> information = const [],
    bool fatal = false,
  }) async {}
}

AppPushNotification _notification(String id, PushNotificationSource source) {
  return AppPushNotification(
    id: id,
    title: 'Push $id',
    body: 'Body $id',
    data: const {},
    source: source,
    receivedAt: DateTime(2026, 6, 25, 10),
  );
}

void main() {
  group('Firebase ViewModel behavior with mocked services', () {
    test(
      'analytics ViewModel behavior logs login and logout without Firebase',
      () async {
        final authService = FakeAuthService(
          initialUser: fakeUser(email: 'researcher@example.com'),
        );
        final analytics = _RecordingAnalyticsService();
        final viewModel = AuthViewModel(
          authService: authService,
          analyticsService: analytics,
        );

        await viewModel.signOut();
        await viewModel.signInWithGoogle();

        expect(authService.signOutCount, 1);
        expect(authService.signInCount, 1);
        expect(analytics.events, [
          'logout:google:researcher@example.com',
          'clear-user',
          'login:google:researcher@example.com',
        ]);

        viewModel.dispose();
        await authService.dispose();
      },
    );

    test(
      'remote config ViewModel fetches and exposes updated mocked values',
      () async {
        final service = _MutableRemoteConfigService(
          maxJournals: 8,
          maxKeywords: 4,
          nextMaxJournals: 3,
          nextMaxKeywords: 2,
        );
        final viewModel = RemoteConfigViewModel(service);

        await viewModel.initialize();
        await viewModel.fetchAndActivate();

        expect(service.initializeCalls, 1);
        expect(service.fetchCalls, 1);
        expect(viewModel.maxJournalsDisplayed, 3);
        expect(viewModel.maxKeywordsDisplayed, 2);
        expect(viewModel.isFetching, isFalse);
      },
    );

    test('notification ViewModel tracks permission token and pushes', () async {
      final service = _FakeCloudMessagingService();
      final viewModel = CloudMessagingViewModel(service);

      await viewModel.initialize();
      await viewModel.requestPermission();
      service.foregroundController.add(
        _notification('foreground', PushNotificationSource.foreground),
      );
      service.openedController.add(
        _notification('opened', PushNotificationSource.openedApp),
      );
      service.tokenController.add('refreshed-token');
      await Future<void>.delayed(Duration.zero);

      expect(service.initializeCalls, 1);
      expect(service.requestPermissionCalls, 1);
      expect(
        viewModel.permissionStatus,
        CloudMessagingPermissionStatus.authorized,
      );
      expect(viewModel.canReceiveNotifications, isTrue);
      expect(viewModel.token, 'refreshed-token');
      expect(viewModel.notifications.map((item) => item.id), [
        'opened',
        'foreground',
        'stored',
      ]);

      viewModel.dispose();
      await service.dispose();
    });

    test(
      'Crashlytics ViewModel sends demo actions through mocked service',
      () async {
        final service = _FakeCrashlyticsService();
        final viewModel = CrashlyticsViewModel(service);

        final handledSent = await viewModel.recordDemoHandledException();
        final crashSent = await viewModel.triggerDemoCrash();

        expect(handledSent, isTrue);
        expect(crashSent, isTrue);
        expect(service.handledExceptionCalls, 1);
        expect(service.testCrashCalls, 1);
        expect(viewModel.isRecordingHandledException, isFalse);
        expect(viewModel.isTriggeringCrash, isFalse);
        expect(viewModel.errorMessage, isNull);
      },
    );

    test('Crashlytics ViewModel exposes errors from mocked service', () async {
      final service = _FakeCrashlyticsService()..throwOnHandledException = true;
      final viewModel = CrashlyticsViewModel(service);

      final didSend = await viewModel.recordDemoHandledException();

      expect(didSend, isFalse);
      expect(service.handledExceptionCalls, 1);
      expect(
        viewModel.errorMessage,
        'Unable to send handled exception to Crashlytics.',
      );
      expect(viewModel.isRecordingHandledException, isFalse);
    });
  });
}
