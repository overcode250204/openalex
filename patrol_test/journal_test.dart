import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/models/journal/journal_source.dart';
import 'package:openalex/models/keyword/keyword_analysis_result.dart';
import 'package:openalex/models/keyword/keyword_dashboard_result.dart';
import 'package:openalex/models/keyword/keyword_frequency_stat.dart';
import 'package:openalex/models/keyword/keyword_trend_point.dart';
import 'package:openalex/models/publication/publication.dart';
import 'package:openalex/models/topic/topic.dart';
import 'package:openalex/routes/app_router.dart';
import 'package:openalex/routes/app_routes.dart';
import 'package:openalex/screens/app/app_shell_screen.dart';
import 'package:openalex/services/analytics/app_analytics_service.dart';
import 'package:openalex/services/analytics/no_op_analytics_service.dart';
import 'package:openalex/services/keyword_dashboard_service.dart';
import 'package:openalex/services/openalex_journal_service.dart';
import 'package:openalex/services/openalex_keyword_service.dart';
import 'package:openalex/services/openalex_service.dart';
import 'package:openalex/services/report/report_metadata_service.dart';
import 'package:openalex/services/suggestion_service.dart';
import 'package:openalex/utils/app_keys.dart';
import 'package:openalex/viewmodels/analytics_view_model.dart';
import 'package:openalex/viewmodels/auth_view_model.dart';
import 'package:openalex/viewmodels/home_view_model.dart';
import 'package:openalex/viewmodels/journal_view_model.dart';
import 'package:openalex/viewmodels/keyword_analyzer_view_model.dart';
import 'package:openalex/viewmodels/keyword_dashboard_view_model.dart';
import 'package:openalex/viewmodels/selected_topic_view_model.dart';
import 'package:openalex/viewmodels/uploaded_reports_view_model.dart';
import 'package:patrol/patrol.dart';
import 'package:provider/provider.dart';

import '../test/fakes/fake_auth_service.dart';

const _config = PatrolTesterConfig(
  settlePolicy: SettlePolicy.noSettle,
  visibleTimeout: Duration(seconds: 15),
  existsTimeout: Duration(seconds: 15),
  printLogs: true,
);

Publication _pub({
  required String id,
  required String title,
  required String journalName,
  required int citedByCount,
}) {
  return Publication(
    id: id,
    title: title,
    publicationYear: 2024,
    citedByCount: citedByCount,
    journalName: journalName,
    doi: null,
    abstractText: null,
    authors: const [],
    relatedWorkIds: const [],
    referencedWorkIds: const [],
  );
}

final _publications = [
  _pub(
    id: 'W_NATURE_1',
    title: 'Deterministic Patrol Paper One',
    journalName: 'Nature',
    citedByCount: 10,
  ),
  _pub(
    id: 'W_NATURE_2',
    title: 'Deterministic Patrol Paper Two',
    journalName: 'Nature',
    citedByCount: 20,
  ),
  _pub(
    id: 'W_SCIENCE_1',
    title: 'Deterministic Patrol Paper Three',
    journalName: 'Science',
    citedByCount: 5,
  ),
];

// Deterministic journals matching the fake publications above so that
// worksCount / citedByCount assertions in the detail screen align.
final _journalSources = [
  const JournalSource(
    id: 'https://openalex.org/S_NATURE',
    displayName: 'Nature',
    publisher: 'Nature Portfolio',
    issnL: '0028-0836',
    worksCount: 2,
    citedByCount: 30,
  ),
  const JournalSource(
    id: 'https://openalex.org/S_SCIENCE',
    displayName: 'Science',
    publisher: 'AAAS',
    issnL: '0036-8075',
    worksCount: 1,
    citedByCount: 5,
  ),
];

class _FakeOpenAlexService extends OpenAlexService {
  @override
  Future<List<String>> getTopicIdsFromKeyword(String keyword) async {
    debugPrint('[journal patrol] fake getTopicIdsFromKeyword("$keyword")');
    return [];
  }

  @override
  Future<(int, List<Publication>)> searchPublications({
    required String keyword,
    int perPage = 50,
    String sort = 'cited_by_count:desc',
    List<String>? topicIds,
  }) async {
    debugPrint('[journal patrol] fake searchPublications("$keyword")');
    return (_publications.length, _publications);
  }
}

class _FakeSuggestionService extends SuggestionService {
  @override
  Future<List<TopicSuggestion>> fetchTopicSuggestions(String query) async => [];

  @override
  Future<List<String>> fetchRelatedKeywords(String keyword) async => [];
}

class _FakeOpenAlexJournalService extends OpenAlexJournalService {
  @override
  Future<List<JournalSource>> fetchTopJournals({int perPage = 20}) async {
    debugPrint('[journal patrol] fake fetchTopJournals');
    return _journalSources;
  }

  @override
  Future<List<JournalSource>> searchJournals(
    String query, {
    int perPage = 20,
  }) async {
    debugPrint('[journal patrol] fake searchJournals("$query")');
    return _journalSources
        .where(
          (j) => j.displayName.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }

  @override
  Future<List<Publication>> fetchPublicationsForJournal(
    String journalId, {
    int perPage = 10,
    int page = 1,
  }) async {
    debugPrint('[journal patrol] fake fetchPublicationsForJournal($journalId)');
    return _publications
        .where(
          (p) => journalId.toLowerCase().contains(
            (p.journalName ?? '').toLowerCase(),
          ),
        )
        .toList();
  }
}

class _FakeKeywordDashboardService extends KeywordDashboardService {
  @override
  Future<KeywordDashboardResult> fetchKeywordDashboard({
    DateTime? asOf,
    bool forceRefresh = false,
    int? trendEndYear,
    int? trendStartYear,
  }) async {
    return KeywordDashboardResult(
      hottestKeyword: null,
      mostFrequentKeywords: const [],
      trendingKeywords: const [],
      statistics: const KeywordFrequencyStat(
        totalKeywordsAnalyzed: 0,
        totalRecentPublications: 0,
        hottestKeyword: '',
        fastestGrowthRate: 0.0,
      ),
      trendSeries: const {},
      currentPeriodStart: DateTime(2024),
      currentPeriodEnd: DateTime(2024, 12, 31),
      previousPeriodStart: DateTime(2023),
      previousPeriodEnd: DateTime(2023, 12, 31),
      fetchedAt: DateTime(2024, 6, 1),
    );
  }
}

class _FakeOpenAlexKeywordService extends OpenAlexKeywordService {
  @override
  Future<KeywordAnalysisResult> analyzeKeyword(
    String keyword, {
    int fromYear = 2011,
    int? toYear,
  }) async {
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

Future<void> _launchApp(PatrolIntegrationTester $) async {
  debugPrint('[journal patrol] launching deterministic AppShell harness');

  final authService = FakeAuthService(initialUser: fakeUser());
  final analyticsService = const NoOpAnalyticsService();
  final selectedTopicViewModel = SelectedTopicViewModel();
  final openAlexService = _FakeOpenAlexService();
  final suggestionService = _FakeSuggestionService();
  final journalService = _FakeOpenAlexJournalService();
  final authViewModel = AuthViewModel(
    authService: authService,
    analyticsService: analyticsService,
  );

  await $.tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<AppAnalyticsService>.value(value: analyticsService),
        Provider.value(value: openAlexService),
        Provider.value(value: suggestionService),
        Provider<ReportMetadataService>.value(
          value: const NoOpReportMetadataService(),
        ),
        ChangeNotifierProvider.value(value: authViewModel),
        ChangeNotifierProvider.value(value: selectedTopicViewModel),
        ChangeNotifierProvider(
          create: (_) => HomeViewModel(
            openAlexService,
            suggestionService: suggestionService,
            selectedTopicViewModel: selectedTopicViewModel,
            analyticsService: analyticsService,
          ),
        ),
        ChangeNotifierProvider(create: (_) => AnalyticsViewModel()),
        ChangeNotifierProvider(
          create: (_) =>
              KeywordDashboardViewModel(_FakeKeywordDashboardService()),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              KeywordAnalyzerViewModel(_FakeOpenAlexKeywordService()),
        ),
        ChangeNotifierProvider(
          create: (_) => UploadedReportsViewModel(
            metadataService: const NoOpReportMetadataService(),
            userIdResolver: () => authViewModel.currentUser?.uid,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => JournalViewModel(journalService),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Journal Trend Analyzer Patrol Harness',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
        initialRoute: AppRoutes.home,
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.home) {
            return MaterialPageRoute<void>(
              builder: (_) => const AppShell(),
              settings: settings,
            );
          }
          return AppRouter.onGenerateRoute(settings);
        },
      ),
    ),
  );

  await $.tester.pump();
  await $.tester.pump(const Duration(milliseconds: 300));
  debugPrint('[journal patrol] harness pumped');
}

Future<void> _waitFor(
  PatrolIntegrationTester $,
  Finder finder, {
  required String label,
  Duration timeout = const Duration(seconds: 15),
}) async {
  debugPrint('[journal patrol] waiting for $label');
  final end = DateTime.now().add(timeout);
  var attempts = 0;
  while (DateTime.now().isBefore(end)) {
    await $.pump(const Duration(milliseconds: 250));
    attempts++;
    if (finder.evaluate().isNotEmpty) {
      debugPrint('[journal patrol] found $label after $attempts pumps');
      return;
    }
  }
  debugPrint('[journal patrol] timed out waiting for $label');
  expect(finder, findsWidgets);
}

Finder _byKeyPrefix(String prefix) {
  return find.byWidgetPredicate((widget) {
    final key = widget.key;
    return key is ValueKey<String> && key.value.startsWith(prefix);
  });
}

void main() {
  patrolTest(
    'Top journals load by default; tapping one opens Journal Detail',
    ($) async {
      debugPrint('[journal patrol] test started');
      await _launchApp($);

      // First, search a topic on Home so HomeViewModel.publications is populated.
      // This lets the Journal Detail screen show "Related Publications".
      debugPrint('[journal patrol] searching a topic on Home');
      await $(
        find.byKey(AppKeys.topicSearchInput),
      ).enterText('machine learning');
      await $(find.byKey(AppKeys.topicSearchButton)).tap();
      await _waitFor(
        $,
        find.byKey(AppKeys.publicationResultsList),
        label: 'publication results list',
      );

      debugPrint('[journal patrol] tapping Journals tab');
      await $(find.byKey(AppKeys.journalsTab)).tap();
      await _waitFor(
        $,
        find.text('Top Journals'),
        label: 'journals list heading',
      );

      expect(find.text('Nature'), findsWidgets);
      expect(find.text('Science'), findsWidgets);

      final journalItem = _byKeyPrefix('journal_item_');
      await _waitFor($, journalItem, label: 'journal item');

      debugPrint('[journal patrol] tapping first journal item');
      await $(journalItem.first).tap();

      await _waitFor(
        $,
        find.byKey(AppKeys.journalDetailScreen),
        label: 'journal detail screen',
      );
      await _waitFor(
        $,
        find.byKey(AppKeys.journalStatsSection),
        label: 'journal stats section',
      );

      // Stats come from JournalSource.worksCount / citedByCount
      expect(find.text('2 publications'), findsOneWidget);
      expect(find.text('30 citations'), findsOneWidget);

      debugPrint('[journal patrol] verifying related publications');
      final publicationsSection = find.byKey(
        AppKeys.journalPublicationsSection,
      );
      expect(
        find.descendant(
          of: publicationsSection,
          matching: find.text('Deterministic Patrol Paper One'),
        ),
        findsWidgets,
      );

      debugPrint('[journal patrol] navigating back to Journals list');
      await $.tester.pageBack();
      await $.pump(const Duration(milliseconds: 300));
      expect(find.text('Top Journals'), findsOneWidget);

      debugPrint('[journal patrol] test finished successfully');
    },
    config: _config,
    timeout: const Timeout(Duration(minutes: 1)),
  );
}
