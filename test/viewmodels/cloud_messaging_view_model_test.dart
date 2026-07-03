import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/models/firebase/app_push_notification.dart';
import 'package:openalex/services/firebase/cloud_messaging_service.dart';
import 'package:openalex/viewmodels/cloud_messaging_view_model.dart';

class _FakeCloudMessagingService implements CloudMessagingService {
  _FakeCloudMessagingService({
    this.initializeSnapshot = const CloudMessagingSnapshot(
      permissionStatus: CloudMessagingPermissionStatus.notDetermined,
      token: null,
      backgroundNotifications: [],
    ),
    this.requestedStatus = CloudMessagingPermissionStatus.authorized,
    this.nextToken = 'token-after-request',
  });

  final foregroundController =
      StreamController<AppPushNotification>.broadcast();
  final openedController = StreamController<AppPushNotification>.broadcast();
  final tokenController = StreamController<String>.broadcast();

  CloudMessagingSnapshot initializeSnapshot;
  CloudMessagingPermissionStatus requestedStatus;
  String? nextToken;
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
    return initializeSnapshot;
  }

  @override
  Future<CloudMessagingPermissionStatus> requestPermission() async {
    requestPermissionCalls++;
    return requestedStatus;
  }

  @override
  Future<String?> getToken() async => nextToken;

  Future<void> dispose() async {
    await foregroundController.close();
    await openedController.close();
    await tokenController.close();
  }
}

AppPushNotification notification(
  String id, {
  PushNotificationSource source = PushNotificationSource.foreground,
}) {
  return AppPushNotification(
    id: id,
    title: 'Test push $id',
    body: 'Body $id',
    data: const {},
    source: source,
    receivedAt: DateTime(2026, 6, 25, 10),
  );
}

void main() {
  group('CloudMessagingViewModel', () {
    test(
      'initializes permission state token and stored notifications',
      () async {
        final service = _FakeCloudMessagingService(
          initializeSnapshot: CloudMessagingSnapshot(
            permissionStatus: CloudMessagingPermissionStatus.authorized,
            token: 'initial-token',
            initialNotification: notification(
              'initial',
              source: PushNotificationSource.initial,
            ),
            backgroundNotifications: [
              notification(
                'background',
                source: PushNotificationSource.background,
              ),
            ],
          ),
        );
        final viewModel = CloudMessagingViewModel(service);

        await viewModel.initialize();

        expect(service.initializeCalls, 1);
        expect(
          viewModel.permissionStatus,
          CloudMessagingPermissionStatus.authorized,
        );
        expect(viewModel.canReceiveNotifications, isTrue);
        expect(viewModel.token, 'initial-token');
        expect(viewModel.notifications.map((item) => item.id), [
          'background',
          'initial',
        ]);

        viewModel.dispose();
        await service.dispose();
      },
    );

    test('requestPermission updates permission state and token', () async {
      final service = _FakeCloudMessagingService(
        requestedStatus: CloudMessagingPermissionStatus.provisional,
        nextToken: 'requested-token',
      );
      final viewModel = CloudMessagingViewModel(service);

      await viewModel.requestPermission();

      expect(service.requestPermissionCalls, 1);
      expect(
        viewModel.permissionStatus,
        CloudMessagingPermissionStatus.provisional,
      );
      expect(viewModel.canReceiveNotifications, isTrue);
      expect(viewModel.token, 'requested-token');

      viewModel.dispose();
      await service.dispose();
    });

    test(
      'adds foreground opened-app notifications and token refreshes',
      () async {
        final service = _FakeCloudMessagingService(
          initializeSnapshot: const CloudMessagingSnapshot(
            permissionStatus: CloudMessagingPermissionStatus.authorized,
            token: 'initial-token',
            backgroundNotifications: [],
          ),
        );
        final viewModel = CloudMessagingViewModel(service);

        await viewModel.initialize();
        service.foregroundController.add(notification('foreground'));
        service.openedController.add(
          notification('opened', source: PushNotificationSource.openedApp),
        );
        service.tokenController.add('refreshed-token');
        await Future<void>.delayed(Duration.zero);

        expect(viewModel.notifications.map((item) => item.id), [
          'opened',
          'foreground',
        ]);
        expect(viewModel.token, 'refreshed-token');

        viewModel.dispose();
        await service.dispose();
      },
    );

    test('does not initialize twice', () async {
      final service = _FakeCloudMessagingService();
      final viewModel = CloudMessagingViewModel(service);

      await viewModel.initialize();
      await viewModel.initialize();

      expect(service.initializeCalls, 1);

      viewModel.dispose();
      await service.dispose();
    });
  });
}
