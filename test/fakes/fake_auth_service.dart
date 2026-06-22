import 'dart:async';

import 'package:openalex/models/auth/app_user.dart';
import 'package:openalex/services/firebase_auth_service.dart';

class FakeAuthService implements AuthService {
  FakeAuthService({AppUser? initialUser, this.signInError, this.signOutError})
    : _currentUser = initialUser;

  final Object? signInError;
  final Object? signOutError;
  final _controller = StreamController<AppUser?>.broadcast();

  AppUser? _currentUser;
  bool _isDisposed = false;
  int signInCount = 0;
  int signOutCount = 0;

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield _currentUser;
    yield* _controller.stream;
  }

  @override
  AppUser? getCurrentUser() => _currentUser;

  @override
  Future<AppUser> signInWithGoogle() async {
    signInCount++;
    final error = signInError;
    if (error != null) throw error;

    final user = _currentUser ?? fakeUser();
    _currentUser = user;
    if (!_isDisposed) _controller.add(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    signOutCount++;
    final error = signOutError;
    if (error != null) throw error;

    _currentUser = null;
    if (!_isDisposed) _controller.add(null);
  }

  void emit(AppUser? user) {
    _currentUser = user;
    if (!_isDisposed) _controller.add(user);
  }

  Future<void> dispose() {
    _isDisposed = true;
    return _controller.close();
  }
}

AppUser fakeUser({
  String uid = 'user-1',
  String? email = 'researcher@example.com',
  String? displayName = 'Researcher One',
  String? photoUrl,
  bool isEmailVerified = true,
}) {
  return AppUser(
    uid: uid,
    email: email,
    displayName: displayName,
    photoUrl: photoUrl,
    isEmailVerified: isEmailVerified,
  );
}
