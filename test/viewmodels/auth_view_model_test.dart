import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/models/auth/app_user.dart';
import 'package:openalex/services/firebase_auth_service.dart';
import 'package:openalex/viewmodels/auth_view_model.dart';

import '../fakes/fake_auth_service.dart';

class _CompleterAuthService implements AuthService {
  _CompleterAuthService({AppUser? initialUser}) : _currentUser = initialUser;

  final _controller = StreamController<AppUser?>.broadcast();
  final signInCompleter = Completer<AppUser>();
  final signOutCompleter = Completer<void>();

  AppUser? _currentUser;

  @override
  Stream<AppUser?> authStateChanges() => _controller.stream;

  @override
  AppUser? getCurrentUser() => _currentUser;

  @override
  Future<AppUser> signInWithGoogle() => signInCompleter.future;

  @override
  Future<void> signOut() => signOutCompleter.future;

  void emit(AppUser? user) {
    _currentUser = user;
    _controller.add(user);
  }

  Future<void> dispose() => _controller.close();
}

void main() {
  group('AuthViewModel', () {
    test('uses persisted signed-in user immediately on startup', () async {
      final user = fakeUser();
      final service = FakeAuthService(initialUser: user);
      final viewModel = AuthViewModel(authService: service);

      expect(viewModel.status, AuthStatus.authenticated);
      expect(viewModel.currentUser, user);
      expect(viewModel.isAuthenticated, isTrue);

      viewModel.dispose();
      await service.dispose();
    });

    test(
      'uses unauthenticated state immediately when no user is persisted',
      () async {
        final service = FakeAuthService();
        final viewModel = AuthViewModel(authService: service);

        expect(viewModel.status, AuthStatus.unauthenticated);
        expect(viewModel.currentUser, isNull);

        viewModel.dispose();
        await service.dispose();
      },
    );

    test(
      'keeps unauthenticated state when auth stream emits no user',
      () async {
        final service = FakeAuthService();
        final viewModel = AuthViewModel(authService: service);

        await Future<void>.delayed(Duration.zero);

        expect(viewModel.status, AuthStatus.unauthenticated);
        expect(viewModel.currentUser, isNull);

        viewModel.dispose();
        await service.dispose();
      },
    );

    test('moves to authenticated when a user is emitted', () async {
      final user = fakeUser();
      final service = FakeAuthService(initialUser: user);
      final viewModel = AuthViewModel(authService: service);

      await Future<void>.delayed(Duration.zero);

      expect(viewModel.status, AuthStatus.authenticated);
      expect(viewModel.currentUser, user);
      expect(viewModel.isAuthenticated, isTrue);

      viewModel.dispose();
      await service.dispose();
    });

    test(
      'signInWithGoogle exposes loading state until sign-in completes',
      () async {
        final service = _CompleterAuthService();
        final viewModel = AuthViewModel(authService: service);

        final signInFuture = viewModel.signInWithGoogle();

        expect(viewModel.isLoading, isTrue);

        final user = fakeUser();
        service.signInCompleter.complete(user);
        service.emit(user);
        await signInFuture;

        expect(viewModel.isLoading, isFalse);
        expect(viewModel.errorMessage, isNull);

        viewModel.dispose();
        await service.dispose();
      },
    );

    test('maps Firebase auth errors to friendly messages', () async {
      final service = FakeAuthService(
        signInError: FirebaseAuthException(code: 'network-request-failed'),
      );
      final viewModel = AuthViewModel(authService: service);

      await viewModel.signInWithGoogle();

      expect(
        viewModel.errorMessage,
        'Network error. Please check your internet connection.',
      );

      viewModel.dispose();
      await service.dispose();
    });

    test('maps Google Sign-In cancellation to a friendly message', () async {
      final service = FakeAuthService(
        signInError: PlatformException(code: 'sign_in_canceled'),
      );
      final viewModel = AuthViewModel(authService: service);

      await viewModel.signInWithGoogle();

      expect(viewModel.errorMessage, 'Google Sign-In was cancelled.');

      viewModel.dispose();
      await service.dispose();
    });

    test('maps missing Google id token to a friendly message', () async {
      final service = FakeAuthService(
        signInError: const GoogleSignInIdTokenException(),
      );
      final viewModel = AuthViewModel(authService: service);

      await viewModel.signInWithGoogle();

      expect(
        viewModel.errorMessage,
        'Google Sign-In could not verify this account. Please try again.',
      );

      viewModel.dispose();
      await service.dispose();
    });

    test(
      'signOut clears the current user when auth state emits null',
      () async {
        final service = FakeAuthService(initialUser: fakeUser());
        final viewModel = AuthViewModel(authService: service);

        await Future<void>.delayed(Duration.zero);
        await viewModel.signOut();

        expect(viewModel.status, AuthStatus.unauthenticated);
        expect(viewModel.currentUser, isNull);
        expect(service.signOutCount, 1);

        viewModel.dispose();
        await service.dispose();
      },
    );
  });
}
