import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/models/auth/app_user.dart';
import 'package:openalex/screens/auth/auth_gate_screen.dart';
import 'package:openalex/services/firebase_auth_service.dart';
import 'package:openalex/utils/app_keys.dart';
import 'package:openalex/viewmodels/auth_view_model.dart';
import 'package:provider/provider.dart';

import '../fakes/fake_auth_service.dart';

class _PendingAuthService implements AuthService {
  final _signInCompleter = Completer<AppUser>();
  final _authController = StreamController<AppUser?>.broadcast();
  int signInCount = 0;

  @override
  Stream<AppUser?> authStateChanges() => _authController.stream;

  @override
  AppUser? getCurrentUser() => null;

  @override
  Future<AppUser> signInWithGoogle() {
    signInCount++;
    return _signInCompleter.future;
  }

  @override
  Future<void> signOut() async {}

  void failSignIn(Object error) {
    _signInCompleter.completeError(error);
  }

  Future<void> dispose() => _authController.close();
}

Widget _build(AuthViewModel viewModel) {
  return ChangeNotifierProvider<AuthViewModel>.value(
    value: viewModel,
    child: const MaterialApp(
      home: AuthGateScreen(child: Text('Authenticated app')),
    ),
  );
}

void main() {
  testWidgets('logged-out user opens Login Screen directly', (tester) async {
    final service = FakeAuthService();
    final viewModel = AuthViewModel(authService: service);

    await tester.pumpWidget(_build(viewModel));

    expect(find.text('OpenAlex Research'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.byKey(AppKeys.googleSignInButton), findsOneWidget);
    expect(find.text('Authenticated app'), findsNothing);

    viewModel.dispose();
    await service.dispose();
  });

  testWidgets('logged-in user opens AppShell directly after restart', (
    tester,
  ) async {
    final service = FakeAuthService(initialUser: fakeUser());
    final viewModel = AuthViewModel(authService: service);

    await tester.pumpWidget(_build(viewModel));

    expect(find.text('Authenticated app'), findsOneWidget);
    expect(find.text('OpenAlex Research'), findsNothing);

    viewModel.dispose();
    await service.dispose();
  });

  testWidgets('successful Google Sign-In redirects to the app', (tester) async {
    final service = FakeAuthService();
    final viewModel = AuthViewModel(authService: service);

    await tester.pumpWidget(_build(viewModel));
    await tester.pump();

    expect(find.text('OpenAlex Research'), findsOneWidget);

    await tester.tap(find.byKey(AppKeys.googleSignInButton));
    await tester.pump();
    await tester.pump();

    expect(find.text('Authenticated app'), findsOneWidget);
    expect(find.text('OpenAlex Research'), findsNothing);
    expect(service.signInCount, 1);

    viewModel.dispose();
    await service.dispose();
  });

  testWidgets('shows loading and error states during failed Google Sign-In', (
    tester,
  ) async {
    final service = _PendingAuthService();
    final viewModel = AuthViewModel(authService: service);

    await tester.pumpWidget(_build(viewModel));
    service._authController.add(null);
    await tester.pump();

    await tester.tap(find.byKey(AppKeys.googleSignInButton));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    service.failSignIn(StateError('No account'));
    await tester.pump();

    expect(
      find.text('Unable to sign in with Google. Please try again.'),
      findsOneWidget,
    );
    expect(service.signInCount, 1);

    viewModel.dispose();
    await service.dispose();
  });
}
