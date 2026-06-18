import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/models/keyword/keyword_analysis_paper.dart';
import 'package:openalex/models/keyword/keyword_analysis_result.dart';
import 'package:openalex/models/keyword/keyword_trend_point.dart';
import 'package:openalex/models/keyword/openalex_keyword.dart';
import 'package:openalex/screens/keyword_analyzer_page.dart';
import 'package:openalex/services/openalex_keyword_service.dart';
import 'package:openalex/viewmodels/keyword_analyzer_view_model.dart';
import 'package:provider/provider.dart';

class FakeKeywordService extends OpenAlexKeywordService {
  @override
  Future<KeywordAnalysisResult> analyzeKeyword(String keyword) async {
    return KeywordAnalysisResult(
      keyword: keyword,
      resolvedKeyword: const OpenAlexKeyword(
        id: 'C123',
        displayName: 'Artificial intelligence',
        worksCount: 12911371,
        citedByCount: 199170687,
      ),
      trend: const [KeywordTrendPoint(year: 2024, count: 5)],
      relevantPapers: const [_samplePaper],
      mostCitedPapers: const [_samplePaper],
      latestPapers: const [_samplePaper],
      openAccessPapers: const [_samplePaper],
    );
  }
}

const _samplePaper = KeywordAnalysisPaper(
  id: 'W1',
  title: 'AI Paper',
  publicationYear: 2024,
  publicationDate: '2024-01-01',
  sourceName: 'IEEE Access',
  doi: 'https://doi.org/10.1000/ai',
  landingPageUrl: null,
  pdfUrl: null,
  citedByCount: 1234,
  isOpenAccess: true,
);

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

  testWidgets('renders Keyword Analyzer dashboard labels after search', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => KeywordAnalyzerViewModel(FakeKeywordService()),
        child: const MaterialApp(home: KeywordAnalyzerPage()),
      ),
    );

    await tester.enterText(find.byType(TextField), 'Artificial Intelligence');
    await tester.tap(find.text('Analyze Keyword'));
    await tester.pumpAndSettle();

    expect(find.text('Keyword Matched'), findsOneWidget);
    expect(find.text('Keyword Trend'), findsOneWidget);
    expect(find.text('Papers Using This Keyword'), findsOneWidget);
    expect(find.text('Most Cited Papers Using This Keyword'), findsOneWidget);

    final dashboardScrollable = find.byType(Scrollable).first;

    await tester.scrollUntilVisible(
      find.text('Latest Papers Using This Keyword'),
      300,
      scrollable: dashboardScrollable,
    );
    expect(find.text('Latest Papers Using This Keyword'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Open Access Papers Using This Keyword'),
      300,
      scrollable: dashboardScrollable,
    );
    expect(find.text('Open Access Papers Using This Keyword'), findsOneWidget);
    expect(find.text('2024 • IEEE Access'), findsWidgets);
  });
}
