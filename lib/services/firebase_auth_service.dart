import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/auth/app_user.dart';

abstract class AuthService {
  Stream<AppUser?> authStateChanges();

  AppUser? getCurrentUser();

  Future<AppUser> signInWithGoogle();

  Future<void> signOut();
}

class FirebaseAuthService implements AuthService {
  FirebaseAuthService({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  bool _isGoogleSignInInitialized = false;

  @override
  Stream<AppUser?> authStateChanges() {
    return _firebaseAuth.authStateChanges().map((firebaseUser) {
      if (firebaseUser == null) {
        return null;
      }

      return AppUser.fromFirebaseUser(firebaseUser);
    });
  }

  @override
  AppUser? getCurrentUser() {
    final firebaseUser = _firebaseAuth.currentUser;

    if (firebaseUser == null) {
      return null;
    }

    return AppUser.fromFirebaseUser(firebaseUser);
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    await _ensureGoogleSignInInitialized();

    final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

    final GoogleSignInAuthentication googleAuth = googleUser.authentication;

    final OAuthCredential credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    final UserCredential userCredential = await _firebaseAuth
        .signInWithCredential(credential);

    final User? firebaseUser = userCredential.user;

    if (firebaseUser == null) {
      throw StateError('Firebase user is null after Google Sign-In.');
    }

    return AppUser.fromFirebaseUser(firebaseUser);
  }

  @override
  Future<void> signOut() async {
    await _ensureGoogleSignInInitialized();

    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_isGoogleSignInInitialized) {
      return;
    }

    await _googleSignIn.initialize();
    _isGoogleSignInInitialized = true;
  }
}
