import 'package:flutter/material.dart';
import 'package:openalex/app/app_providers.dart';
import 'package:openalex/app/firebase_bootstrap.dart';
import 'package:openalex/routes/app_router.dart';
import 'package:openalex/routes/app_routes.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'services/firebase/firebase_auth_service.dart';
import 'services/keyword_dashboard_service.dart';
import 'services/openalex_keyword_service.dart';
import 'services/suggestion_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  await FirebaseBootstrap.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    this.authService,
    this.keywordService,
    this.keywordDashboardService,
    this.suggestionService,
  });

  final AuthService? authService;
  final OpenAlexKeywordService? keywordService;
  final KeywordDashboardService? keywordDashboardService;
  final SuggestionService? suggestionService;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: AppProviders.build(
        authService: authService,
        keywordService: keywordService,
        keywordDashboardService: keywordDashboardService,
        suggestionService: suggestionService,
      ),

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
