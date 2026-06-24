import 'package:flutter/material.dart';
import 'package:openalex/app/app_providers.dart';
import 'package:openalex/app/firebase_bootstrap.dart';
import 'package:openalex/routes/app_router.dart';
import 'package:openalex/routes/app_routes.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'services/firebase/firebase_auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  await FirebaseBootstrap.initialize();
  runApp(const MyApp());
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
        title: 'Journal Trend Analyzer',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
        initialRoute: AppRoutes.home,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}
