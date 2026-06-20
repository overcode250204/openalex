import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/models/keyword/keyword_analysis_paper.dart';
import 'package:openalex/models/keyword/keyword_analysis_result.dart';
import 'package:openalex/models/keyword/keyword_trend_point.dart';
import 'package:openalex/models/keyword/openalex_keyword.dart';
import 'package:openalex/screens/keyword_analyzer_page.dart';
import 'package:openalex/services/openalex_keyword_service.dart';
import 'package:openalex/services/openalex_keyword_service.dart';
import 'package:openalex/viewmodels/keyword_analyzer_view_model.dart';
import 'package:provider/provider.dart';

class FakeKeywordService extends OpenAlexKeywordService {
  int calls = 0;
  String? requestedKeyword;

  @override
  Future<KeywordAnalysisResult> analyzeKeyword(
    String keyword, {
    int fromYear = 2011,
    int? toYear,
  }) async {
    calls++;
    requestedKeyword = keyword;
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
      topAuthors: const {
        'John Doe': 42,
        'Jane Smith': 28,
        'Alice Lee': 15,
        'Bob Chen': 10,
        'Carol Kim': 8,
      },
      topSources: const {
        'Nature': 100,
        'IEEE Access': 80,
        'Science': 60,
        'Cell': 40,
        'PLOS ONE': 20,
      },
    );
  }

  @override
  Future<List<KeywordTrendPoint>> fetchKeywordTrend({
    required String keyword,
    int fromYear = 2011,
    int? toYear,
  }) async {
    return [
      KeywordTrendPoint(year: fromYear, count: 50),
      KeywordTrendPoint(year: toYear ?? DateTime.now().year, count: 100),
    ];
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
    expect(find.text('Keyword Analyzer'), findsOneWidget);
  });

  testWidgets('renders Keyword Analyzer dashboard labels after search', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => KeywordAnalyzerViewModel(FakeKeywordService()),
        child: const MaterialApp(
          home: KeywordAnalyzerPage(originalSearchText: 'Artificial Intelligence'),
        ),
      ),
    );

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
    expect(find.text('Open Access Papers Using This Keyword'), findsOneWidget);
    expect(find.text('2024 • IEEE Access'), findsWidgets);
  });

  testWidgets('renders trend year dropdowns and allows changing year range', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => KeywordAnalyzerViewModel(FakeKeywordService()),
        child: const MaterialApp(
          home: KeywordAnalyzerPage(originalSearchText: 'Artificial Intelligence'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Keyword Trend'));
    await tester.pumpAndSettle();

    expect(find.text('Keyword Trend'), findsOneWidget);
    expect(find.text('to'), findsOneWidget);
    expect(find.text('2011'), findsOneWidget);

    final dropdowns = find.byType(DropdownButton<int>);
    expect(dropdowns, findsWidgets);

    await tester.tap(dropdowns.first);
    await tester.pumpAndSettle();

    final year2020 = find.text('2020').last;
    await tester.ensureVisible(year2020);
    await tester.tap(year2020);
    await tester.pumpAndSettle();

    expect(find.text('2020'), findsWidgets);
  });



  testWidgets('shows Top Contributing Authors card after analysis', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => KeywordAnalyzerViewModel(FakeKeywordService()),
        child: const MaterialApp(
          home: KeywordAnalyzerPage(originalSearchText: 'AI'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Top Contributing Authors'),
      300,
      scrollable: scrollable,
    );

    expect(find.text('Top Contributing Authors'), findsOneWidget);
    expect(
      find.text('Authors with the most publications on this keyword.'),
      findsOneWidget,
    );
  });

  testWidgets('shows Top Research Journals card after analysis', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => KeywordAnalyzerViewModel(FakeKeywordService()),
        child: const MaterialApp(
          home: KeywordAnalyzerPage(originalSearchText: 'AI'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Top Research Journals'),
      300,
      scrollable: scrollable,
    );

    expect(find.text('Top Research Journals'), findsOneWidget);
    expect(
      find.text('Journals publishing the most on this keyword.'),
      findsOneWidget,
    );
  });

  testWidgets('analytics cards show Top 5 dropdown selected by default', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => KeywordAnalyzerViewModel(FakeKeywordService()),
        child: const MaterialApp(
          home: KeywordAnalyzerPage(originalSearchText: 'AI'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Top Contributing Authors'),
      300,
      scrollable: scrollable,
    );
    await tester.scrollUntilVisible(
      find.text('Top Research Journals'),
      300,
      scrollable: scrollable,
    );

    expect(find.text('Top 5'), findsNWidgets(2));
  });

  testWidgets(
    'analytics cards do not render when topAuthors/topSources are empty',
    (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) =>
              KeywordAnalyzerViewModel(_FakeKeywordServiceNoAnalytics()),
          child: const MaterialApp(
            home: KeywordAnalyzerPage(originalSearchText: 'AI'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Top Contributing Authors'), findsNothing);
      expect(find.text('Top Research Journals'), findsNothing);
    },
  );
}

class _FakeKeywordServiceNoAnalytics extends OpenAlexKeywordService {
  @override
  Future<KeywordAnalysisResult> analyzeKeyword(
    String keyword, {
    int fromYear = 2011,
    int? toYear,
  }) async {
    return KeywordAnalysisResult(
      keyword: keyword,
      trend: const [KeywordTrendPoint(year: 2024, count: 5)],
      relevantPapers: const [],
      mostCitedPapers: const [],
      latestPapers: const [],
      openAccessPapers: const [],
    );
  }
}
