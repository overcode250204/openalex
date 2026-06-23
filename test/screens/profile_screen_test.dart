import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/screens/profile/profile_screen.dart';
import 'package:openalex/utils/app_keys.dart';
import 'package:openalex/viewmodels/auth_view_model.dart';
import 'package:openalex/viewmodels/selected_topic_view_model.dart';
import 'package:provider/provider.dart';

import '../fakes/fake_auth_service.dart';

Widget _buildProfile({
  required FakeAuthService authService,
  SelectedTopicViewModel? selectedTopic,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) => AuthViewModel(authService: authService),
      ),
      ChangeNotifierProvider(
        create: (_) => selectedTopic ?? SelectedTopicViewModel(),
      ),
    ],
    child: const MaterialApp(home: ProfileScreen()),
  );
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
}
