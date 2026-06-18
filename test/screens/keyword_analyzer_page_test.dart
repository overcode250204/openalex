import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/screens/keyword_analyzer_page.dart';
import 'package:openalex/services/openalex_keyword_service.dart';
import 'package:openalex/viewmodels/keyword_analyzer_view_model.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('renders Keyword Analyzer initial state', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => KeywordAnalyzerViewModel(OpenAlexKeywordService()),
        child: const MaterialApp(home: KeywordAnalyzerPage()),
      ),
    );

    expect(find.text('Keyword Analyzer'), findsOneWidget);
    expect(find.text('Academic keyword'), findsOneWidget);
    expect(find.text('Analyze Keyword'), findsOneWidget);
    expect(
      find.text('Enter an academic keyword and tap Analyze Keyword.'),
      findsOneWidget,
    );
  });
}
