import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:openalex/services/firebase_auth_service.dart';

import '../models/auth/app_user.dart';

enum AuthStatus { checking, authenticated, unauthenticated }

class AuthViewModel extends ChangeNotifier {
  AuthViewModel({required AuthService authService})
    : _authService = authService {
    final persistedUser = _authService.getCurrentUser();
    _currentUser = persistedUser;
    _status = persistedUser == null
        ? AuthStatus.unauthenticated
        : AuthStatus.authenticated;
    _listenToAuthChanges();
  }

  final AuthService _authService;

  StreamSubscription<AppUser?>? _authSubscription;

  AuthStatus _status = AuthStatus.checking;
  AppUser? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthStatus get status => _status;

  AppUser? get currentUser => _currentUser;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _currentUser != null;

  Future<void> signInWithGoogle() async {
    if (_isLoading) {
      return;
    }

    _setLoading(true);
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.signInWithGoogle();
    } catch (error) {
      _errorMessage = _mapAuthError(error);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    if (_isLoading) {
      return;
    }

    _setLoading(true);
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.signOut();
    } catch (error) {
      _errorMessage = _mapAuthError(error);
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _listenToAuthChanges() {
    _authSubscription = _authService.authStateChanges().listen(
      (user) {
        _currentUser = user;
        _status = user == null
            ? AuthStatus.unauthenticated
            : AuthStatus.authenticated;

        notifyListeners();
      },
      onError: (Object error) {
        _currentUser = null;
        _status = AuthStatus.unauthenticated;
        _errorMessage = _mapAuthError(error);

        notifyListeners();
      },
    );
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _mapAuthError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'account-exists-with-different-credential':
          return 'This email is already linked to another sign-in method.';
        case 'invalid-credential':
          return 'The Google credential is invalid or expired. Please try again.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        default:
          return error.message ?? 'Firebase authentication failed.';
      }
    }

    if (error is PlatformException) {
      if (error.code == 'sign_in_canceled') {
        return 'Google Sign-In was cancelled.';
      }

      if (error.code == 'network_error') {
        return 'Network error. Please check your internet connection.';
      }

      return error.message ?? 'Google Sign-In failed.';
    }

    if (error is GoogleSignInIdTokenException) {
      return 'Google Sign-In could not verify this account. Please try again.';
    }

    return 'Unable to sign in with Google. Please try again.';
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
