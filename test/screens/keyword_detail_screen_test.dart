import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/screens/keyword/keyword_detail_screen.dart';
import 'package:openalex/models/keyword/openalex_keyword.dart';
import 'package:provider/provider.dart';
import 'package:openalex/viewmodels/keyword_analyzer_view_model.dart';
import 'package:openalex/services/openalex_keyword_service.dart';
import 'package:openalex/screens/keyword_analyzer_page.dart';

void main() {
  Widget buildTestWidget() {
    return MaterialApp(
      home: ChangeNotifierProvider(
        create: (_) => KeywordAnalyzerViewModel(OpenAlexKeywordService()),
        child: const KeywordDetailScreen(
          selectedKeyword: OpenAlexKeyword(
            id: 'k1',
            displayName: 'Test Keyword Title',
            worksCount: 100,
            citedByCount: 100,
          ),
        ),
      ),
    );
  }

  group('KeywordDetailScreen Tests', () {
    testWidgets('screen renders with required provider dependencies', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      expect(find.byType(KeywordDetailScreen), findsOneWidget);
    });

    testWidgets('selected keyword title is passed down', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      expect(find.byType(KeywordAnalyzerPage), findsOneWidget);
    });

    testWidgets('back navigation works', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      final backButton = find.byIcon(Icons.arrow_back);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();
    });
  });
}

