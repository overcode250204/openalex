import 'package:flutter/material.dart';
import 'package:openalex/providers/publication_list_provider.dart';
import 'package:openalex/providers/publication_provider.dart';
import 'package:openalex/providers/publication_detail_provider.dart';
import 'package:openalex/screens/search_screen.dart';
import 'package:openalex/services/openalex_service.dart';
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

            ChangeNotifierProvider(
              create: (_) => PublicationListProvider(),
            ),

            ChangeNotifierProvider(
              create: (_) => PublicationDetailProvider(),
            ),
          ],

        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Journal Trend Analyzer',
          theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
          home: const SearchScreen(),
        ),
      );
  }
}



