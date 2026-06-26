import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/screens/profile/profile_screen.dart';
import 'package:openalex/services/firebase/cloud_messaging_service.dart';
import 'package:openalex/services/firebase/crashlytics_service.dart';
import 'package:openalex/services/firebase/remote_config_service.dart';
import 'package:openalex/utils/app_keys.dart';
import 'package:openalex/viewmodels/auth_view_model.dart';
import 'package:openalex/viewmodels/cloud_messaging_view_model.dart';
import 'package:openalex/viewmodels/crashlytics_view_model.dart';
import 'package:openalex/viewmodels/remote_config_view_model.dart';
import 'package:openalex/viewmodels/selected_topic_view_model.dart';
import 'package:provider/provider.dart';

import '../fakes/fake_auth_service.dart';

Widget _buildProfile({
  required FakeAuthService authService,
  SelectedTopicViewModel? selectedTopic,
  AppCrashlyticsService? crashlyticsService,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) => AuthViewModel(authService: authService),
      ),
      ChangeNotifierProvider(
        create: (_) => selectedTopic ?? SelectedTopicViewModel(),
      ),
      ChangeNotifierProvider(
        create: (_) =>
            CloudMessagingViewModel(const NoOpCloudMessagingService())
              ..initialize(),
      ),
      ChangeNotifierProvider(
        create: (_) => RemoteConfigViewModel(const NoOpRemoteConfigService()),
      ),
      Provider<AppCrashlyticsService>(
        create: (_) => crashlyticsService ?? const NoOpCrashlyticsService(),
      ),
      ChangeNotifierProvider(
        create: (context) =>
            CrashlyticsViewModel(context.read<AppCrashlyticsService>()),
      ),
    ],
    child: const MaterialApp(home: ProfileScreen()),
  );
}

class _FakeCrashlyticsService implements AppCrashlyticsService {
  var initializeCount = 0;
  var handledExceptionCount = 0;
  var testCrashCount = 0;
  final recordedErrors = <Object>[];

  @override
  bool get isInitialized => initializeCount > 0;

  @override
  Future<void> initialize() async {
    initializeCount++;
  }

  @override
  Future<void> recordDemoHandledException() async {
    handledExceptionCount++;
  }

  @override
  Future<void> triggerDemoCrash() async {
    testCrashCount++;
  }

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    Iterable<Object> information = const [],
    bool fatal = false,
  }) async {
    recordedErrors.add(error);
  }
}

void main() {
  testWidgets('shows Firebase Auth user avatar name and email', (tester) async {
    await tester.pumpWidget(
      _buildProfile(
        authService: FakeAuthService(
          initialUser: fakeUser(
            displayName: 'Ada Lovelace',
            email: 'ada@example.com',
          ),
        ),
      ),
    );

    expect(find.text('Ada Lovelace'), findsOneWidget);
    expect(find.text('ada@example.com'), findsOneWidget);
    expect(find.text('AL'), findsOneWidget);
    expect(find.text('Google via Firebase Auth'), findsOneWidget);
    expect(find.text('Verified'), findsOneWidget);
  });

  testWidgets('falls back gracefully when Firebase Auth profile is partial', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildProfile(
        authService: FakeAuthService(
          initialUser: fakeUser(displayName: null, email: 'reader@example.com'),
        ),
      ),
    );

    expect(find.text('reader'), findsOneWidget);
    expect(find.text('reader@example.com'), findsOneWidget);
  });

  testWidgets('renders selected topic and opens sign out confirmation', (
    tester,
  ) async {
    final selectedTopic = SelectedTopicViewModel()
      ..setTopic('Artificial Intelligence');
    final authService = FakeAuthService(initialUser: fakeUser());

    await tester.pumpWidget(
      _buildProfile(authService: authService, selectedTopic: selectedTopic),
    );

    expect(find.text('Artificial Intelligence'), findsOneWidget);
    expect(find.byKey(AppKeys.logoutButton), findsOneWidget);

    await tester.tap(find.byKey(AppKeys.logoutButton));
    await tester.pumpAndSettle();

    expect(find.text('Sign out?'), findsOneWidget);
    expect(
      find.text(
        'You will need to sign in again to access your research dashboard.',
      ),
      findsOneWidget,
    );
    expect(authService.signOutCount, 0);
  });

  testWidgets('does not sign out when confirmation is cancelled', (
    tester,
  ) async {
    final authService = FakeAuthService(initialUser: fakeUser());

    await tester.pumpWidget(_buildProfile(authService: authService));

    await tester.tap(find.byKey(AppKeys.logoutButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(authService.signOutCount, 0);
    expect(find.text('Sign out?'), findsNothing);
  });

  testWidgets('signs out when confirmation is accepted', (tester) async {
    final authService = FakeAuthService(initialUser: fakeUser());

    await tester.pumpWidget(_buildProfile(authService: authService));

    await tester.tap(find.byKey(AppKeys.logoutButton));
    await tester.pumpAndSettle();

    final confirmButton = find.widgetWithText(FilledButton, 'Sign out');

    expect(confirmButton, findsOneWidget);

    await tester.tap(confirmButton);
    await tester.pumpAndSettle();

    expect(authService.signOutCount, 1);
  });

  testWidgets('is usable on a small screen without overflowing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _buildProfile(authService: FakeAuthService(initialUser: fakeUser())),
    );

    expect(find.text('Research workspace'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses a wide layout without hiding profile data', (tester) async {
    tester.view.physicalSize = const Size(900, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _buildProfile(
        authService: FakeAuthService(
          initialUser: fakeUser(
            displayName: 'Grace Hopper',
            email: 'grace@example.com',
          ),
        ),
      ),
    );

    expect(find.text('Grace Hopper'), findsOneWidget);
    expect(find.text('grace@example.com'), findsOneWidget);
    expect(find.text('Research workspace'), findsOneWidget);
  });

  testWidgets('shows clearly marked Crashlytics developer demo buttons', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildProfile(authService: FakeAuthService(initialUser: fakeUser())),
    );

    await tester.scrollUntilVisible(
      find.text('Developer demo tools'),
      300,
      scrollable: find.byType(Scrollable),
    );

    expect(find.text('Developer demo tools'), findsOneWidget);
    expect(
      find.text(
        'Crashlytics verification actions for development and demos only.',
      ),
      findsOneWidget,
    );
    expect(find.text('Demo: Record handled exception'), findsOneWidget);
    expect(find.text('Demo: Test crash'), findsOneWidget);
  });

  testWidgets('Crashlytics demo buttons send evidence through service', (
    tester,
  ) async {
    final crashlytics = _FakeCrashlyticsService();

    await tester.pumpWidget(
      _buildProfile(
        authService: FakeAuthService(initialUser: fakeUser()),
        crashlyticsService: crashlytics,
      ),
    );

    await tester.scrollUntilVisible(
      find.text('Demo: Record handled exception'),
      300,
      scrollable: find.byType(Scrollable),
    );

    await tester.tap(find.text('Demo: Record handled exception'));
    await tester.pump();

    expect(crashlytics.handledExceptionCount, 1);
    expect(
      find.text('Demo handled exception sent to Crashlytics'),
      findsOneWidget,
    );

    await tester.tap(find.text('Demo: Test crash'));
    await tester.pump();

    expect(crashlytics.testCrashCount, 1);
  });
}
