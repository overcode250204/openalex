import 'package:flutter/material.dart';
import 'package:openalex/providers/analytics_provider.dart';
import 'package:openalex/providers/journal_search_provider.dart';
import 'package:openalex/providers/keyword_dashboard_provider.dart';
import 'package:openalex/providers/publication_list_provider.dart';
import 'package:openalex/providers/publication_provider.dart';
import 'package:openalex/providers/publication_detail_provider.dart';
import 'package:openalex/screens/app_shell.dart';
import 'package:openalex/services/openalex_journal_service.dart';
import 'package:openalex/services/keyword_dashboard_service.dart';
import 'package:openalex/services/openalex_keyword_service.dart';
import 'package:openalex/services/openalex_service.dart';
import 'package:openalex/viewmodels/keyword_analyzer_view_model.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => PublicationProvider(OpenAlexService()),
        ),

        ChangeNotifierProvider(create: (_) => PublicationListProvider()),

        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),

        ChangeNotifierProvider(
          create: (_) => KeywordDashboardProvider(KeywordDashboardService()),
        ),

        ChangeNotifierProvider(create: (_) => PublicationDetailProvider()),

        ChangeNotifierProvider(
          create: (_) => KeywordAnalyzerViewModel(OpenAlexKeywordService()),
        ),

        ChangeNotifierProvider(
          create: (_) => JournalSearchProvider(OpenAlexJournalService()),
        ),
      ],

      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Journal Trend Analyzer',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
        home: const AppShell(),
      ),
    );
  }
}
