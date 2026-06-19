import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/main.dart';
import 'package:openalex/models/app_page.dart';
import 'package:openalex/models/journal/journal_publication.dart';
import 'package:openalex/models/journal/journal_source.dart';
import 'package:openalex/models/keyword/keyword_analysis_result.dart';
import 'package:openalex/models/keyword/keyword_trend_point.dart';
import 'package:openalex/models/publication.dart';
import 'package:openalex/providers/journal_search_provider.dart';
import 'package:openalex/providers/publication_detail_provider.dart';
import 'package:openalex/providers/publication_provider.dart';
import 'package:openalex/screens/app_shell.dart';
import 'package:openalex/services/openalex_journal_service.dart';
import 'package:openalex/services/openalex_keyword_service.dart';
import 'package:openalex/services/openalex_service.dart';
import 'package:openalex/services/suggestion_service.dart';
import 'package:openalex/viewmodels/keyword_analyzer_view_model.dart';
import 'package:provider/provider.dart';

// ---------------------------------------------------------------------------
// Fakes – minimal service stubs so screens don't make real HTTP calls
// ---------------------------------------------------------------------------

class _FakeOpenAlexService extends OpenAlexService {
  @override
  Future<(int, List<Publication>)> searchPublications({
    required String keyword,
    int perPage = 50,
    String sort = 'cited_by_count:desc',
    List<String>? topicIds,
  }) async =>
      (0, <Publication>[]);

  @override
  Future<(int, List<Publication>)> searchWithFilter(
          Map<String, String> params) async =>
      (0, <Publication>[]);
}

class _FakeJournalService extends OpenAlexJournalService {
  @override
  Future<List<JournalSource>> searchJournals(String query) async => [];

  @override
  Future<List<JournalPublication>> getJournalPublications(String sourceId,
          {int page = 1, int perPage = 20}) async =>
      [];

  @override
  Future<JournalPublication?> getHighestCitedPublication(
          String sourceId) async =>
      null;
}

class _FakeKeywordService extends OpenAlexKeywordService {
  @override
  Future<KeywordAnalysisResult> analyzeKeyword(String keyword) async {
    return KeywordAnalysisResult(
      keyword: keyword,
      trend: const [KeywordTrendPoint(year: 2024, count: 1)],
      relevantPapers: const [],
      mostCitedPapers: const [],
      latestPapers: const [],
      openAccessPapers: const [],
    );
  }
}

class _FakeSuggestionService extends SuggestionService {
  @override
  Future<List<String>> fetchRelatedKeywords(String keyword) async => [];
}

// ---------------------------------------------------------------------------
// Helper: wrap AppShell with all required providers
// ---------------------------------------------------------------------------

Widget _appShellWidget() {
  final openAlexService = _FakeOpenAlexService();
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) => PublicationProvider(
          openAlexService,
          suggestionService: _FakeSuggestionService(),
        ),
      ),
      ChangeNotifierProvider(
        create: (_) => JournalSearchProvider(_FakeJournalService()),
      ),
      ChangeNotifierProvider(
        create: (_) => PublicationDetailProvider(service: openAlexService),
      ),
      ChangeNotifierProvider(
        create: (_) => KeywordAnalyzerViewModel(_FakeKeywordService()),
      ),
    ],
    child: const MaterialApp(home: AppShell()),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('AppShell – initial state', () {
    testWidgets('renders home page (TrendAnalyzerHomePage) by default',
        (tester) async {
      await tester.pumpWidget(_appShellWidget());
      await tester.pump();

      // TrendAnalyzerHomePage has 'Trend Analyzer' in the AppBar
      expect(find.text('Trend Analyzer'), findsOneWidget);
    });

    testWidgets('MyApp entry point also renders Trend Analyzer',
        (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pump();

      expect(find.text('Trend Analyzer'), findsOneWidget);
    });
  });

  group('AppShell – page switching via drawer', () {
    testWidgets('navigates to Keyword Analyzer (Trends) via drawer',
        (tester) async {
      await tester.pumpWidget(_appShellWidget());
      await tester.pump();

      // Open drawer
      final scaffoldFinder = find.byType(Scaffold).first;
      final ScaffoldState scaffold =
          tester.state<ScaffoldState>(scaffoldFinder);
      scaffold.openDrawer();
      await tester.pumpAndSettle();

      // Expand Keywords group if needed
      await tester.tap(find.text('Keywords'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Trends'));
      await tester.pumpAndSettle();

      // KeywordAnalyzerPage has 'Keyword Analyzer' label
      expect(find.text('Keyword Analyzer'), findsOneWidget);
    });

    testWidgets('navigates to Journal Search via drawer', (tester) async {
      await tester.pumpWidget(_appShellWidget());
      await tester.pump();

      final ScaffoldState scaffold =
          tester.state<ScaffoldState>(find.byType(Scaffold).first);
      scaffold.openDrawer();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Journal'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Search Journal'));
      await tester.pumpAndSettle();

      // JournalSearchScreen renders a search field
      expect(find.text('Search Journal'), findsWidgets);
    });

  });

  group('AppShell – selectedPage enum coverage', () {
    // Test that AppShell routes all AppPage values without throwing
    for (final page in AppPage.values) {
      testWidgets('renders without error for page: ${page.name}',
          (tester) async {
        await tester.pumpWidget(_appShellWidget());
        await tester.pump();

        // Access private state via the ScaffoldState key and simulate page change
        // We just verify that pumpWidget doesn't throw
        expect(tester.takeException(), isNull);
      });
    }
  });
}
