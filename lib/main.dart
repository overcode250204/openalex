import 'dart:async';

import 'package:flutter/material.dart';
import 'package:openalex/app/app_providers.dart';
import 'package:openalex/app/firebase_bootstrap.dart';
import 'package:openalex/models/auth/app_user.dart';
import 'package:openalex/routes/app_router.dart';
import 'package:openalex/routes/app_routes.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'services/firebase/firebase_auth_service.dart';

// DO NOT COMMIT WITH true — for local dev only
const bool _bypassGoogleAuthForTesting = true;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  await FirebaseBootstrap.initialize();
  runApp(
    MyApp(authService: _bypassGoogleAuthForTesting ? _DevAuthService() : null),
  );
}

class _DevAuthService implements AuthService {
  final _user = const AppUser(
    uid: 'dev-user-1',
    email: 'dev@example.com',
    displayName: 'Dev User',
    photoUrl: "hi",
    isEmailVerified: true,
  );

  @override
  Stream<AppUser?> authStateChanges() => Stream.value(_user);

  @override
  AppUser? getCurrentUser() => _user;

  @override
  Future<AppUser> signInWithGoogle() async => _user;

  @override
  Future<void> signOut() async {}
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.authService});

  final AuthService? authService;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: AppProviders.build(authService: authService),

      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ScholarTrend',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
        initialRoute: AppRoutes.home,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}
