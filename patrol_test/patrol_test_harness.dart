import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/models/keyword/keyword_analysis_paper.dart';
import 'package:openalex/models/keyword/keyword_analysis_result.dart';
import 'package:openalex/models/keyword/keyword_dashboard_result.dart';
import 'package:openalex/models/keyword/keyword_frequency_stat.dart';
import 'package:openalex/models/keyword/keyword_overview.dart';
import 'package:openalex/models/keyword/keyword_trend_point.dart';
import 'package:openalex/models/keyword/openalex_keyword.dart';
import 'package:openalex/models/publication/publication.dart';
import 'package:openalex/models/topic/topic.dart';
import 'package:openalex/routes/app_router.dart';
import 'package:openalex/routes/app_routes.dart';
import 'package:openalex/screens/app/app_shell_screen.dart';
import 'package:openalex/services/analytics/app_analytics_service.dart';
import 'package:openalex/services/analytics/no_op_analytics_service.dart';
import 'package:openalex/services/history_service.dart';
import 'package:openalex/services/keyword_dashboard_service.dart';
import 'package:openalex/services/openalex_journal_service.dart';
import 'package:openalex/services/openalex_keyword_service.dart';
import 'package:openalex/services/openalex_service.dart';
import 'package:openalex/services/report/report_metadata_service.dart';
import 'package:openalex/services/suggestion_service.dart';
import 'package:openalex/services/zotero_service.dart';
import 'package:openalex/viewmodels/analytics_view_model.dart';
import 'package:openalex/viewmodels/auth_view_model.dart';
import 'package:openalex/viewmodels/home_view_model.dart';
import 'package:openalex/viewmodels/journal_view_model.dart';
import 'package:openalex/viewmodels/keyword_analyzer_view_model.dart';
import 'package:openalex/viewmodels/keyword_dashboard_view_model.dart';
import 'package:openalex/viewmodels/selected_topic_view_model.dart';
import 'package:openalex/viewmodels/trend_analysis_view_model.dart';
import 'package:openalex/viewmodels/uploaded_reports_view_model.dart';
import 'package:patrol/patrol.dart';
import 'package:provider/provider.dart';

import '../test/fakes/fake_auth_service.dart';

final patrolPublication = Publication(
  id: 'W_TEST_PUBLICATION',
  title: 'Deterministic Machine Learning for Patrol Tests',
  publicationYear: 2024,
  citedByCount: 42,
  journalName: 'Journal of Reliable UI Tests',
  doi: 'https://doi.org/10.0000/patrol-publication',
  abstractText:
      'This deterministic publication fixture lets Patrol verify topic search '
      'and publication detail screens without live OpenAlex network data.',
  authors: const ['Ada Lovelace', 'Alan Turing'],
  oaUrl: 'https://example.com/patrol-publication.pdf',
  relatedWorkIds: const ['W_RELATED_PATROL'],
  referencedWorkIds: const ['W_REFERENCE_PATROL'],
);

const patrolKeyword = OpenAlexKeyword(
  id: 'K_TEST_MACHINE_LEARNING',
  displayName: 'Machine Learning',
  worksCount: 128,
  citedByCount: 4096,
);

const patrolKeywordTrend = [
  KeywordTrendPoint(year: 2022, count: 12),
  KeywordTrendPoint(year: 2023, count: 24),
  KeywordTrendPoint(year: 2024, count: 36),
];

const patrolKeywordPaper = KeywordAnalysisPaper(
  id: 'W_TEST_KEYWORD_PAPER',
  title: 'Deterministic Keyword Analysis for Patrol Tests',
  publicationYear: 2024,
  publicationDate: '2024-06-01',
  sourceName: 'Journal of Reliable UI Tests',
  doi: 'https://doi.org/10.0000/patrol-keyword',
  citedByCount: 42,
  isOpenAccess: true,
  keywordScore: 0.97,
);

class PatrolFakeOpenAlexService extends OpenAlexService {
  @override
  Future<(int total, List<Publication> publications)> searchPublications({
    required String keyword,
    int perPage = 50,
    String sort = 'cited_by_count:desc',
    List<String>? topicIds,
  }) async {
    debugPrint('[patrol harness] fake searchPublications("$keyword")');
    return (1, [patrolPublication]);
  }

  @override
  Future<List<String>> getTopicIdsFromKeyword(String keyword) async {
    debugPrint('[patrol harness] fake getTopicIdsFromKeyword("$keyword")');
    return const ['T_TEST_MACHINE_LEARNING'];
  }

  @override
  Future<Publication?> fetchDetail(String workId) async {
    debugPrint('[patrol harness] fake fetchDetail("$workId")');
    return patrolPublication;
  }

  @override
  Future<List<Publication>> fetchByIds(List<String> ids) async {
    return ids.isEmpty ? [] : [patrolPublication];
  }

  @override
  Future<List<Publication>> fetchCitedBy(String workId, {int page = 1}) async {
    return [patrolPublication];
  }
}

class PatrolFakeSuggestionService extends SuggestionService {
  @override
  Future<List<TopicSuggestion>> fetchTopicSuggestions(String query) async {
    return [
      TopicSuggestion(
        id: 'T_TEST_MACHINE_LEARNING',
        displayName: 'Machine Learning',
        workCount: 128,
      ),
    ];
  }

  @override
  Future<List<String>> fetchRelatedKeywords(String keyword) async {
    return const ['Deep Learning', 'Neural Networks'];
  }
}

class PatrolFakeHistoryService extends SearchHistoryService {
  final List<String> _history = [];

  @override
  Future<List<String>> getHistory() async => List.unmodifiable(_history);

  @override
  Future<void> addHistory(String keyword) async {
    if (keyword.trim().isEmpty) return;
    _history.remove(keyword);
    _history.insert(0, keyword);
  }
}

class PatrolFakeKeywordDashboardService extends KeywordDashboardService {
  @override
  Future<KeywordDashboardResult> fetchKeywordDashboard({
    DateTime? asOf,
    bool forceRefresh = false,
    int? trendEndYear,
    int? trendStartYear,
  }) async {
    debugPrint('[patrol harness] fake keyword dashboard requested');

    const overview = KeywordOverview(
      id: 'K_TEST_MACHINE_LEARNING',
      name: 'Machine Learning',
      currentPeriodCount: 64,
      previousPeriodCount: 32,
      growthRate: 100,
      hotScore: 98,
      status: KeywordStatus.hot,
      trend: patrolKeywordTrend,
    );

    return KeywordDashboardResult(
      hottestKeyword: overview,
      mostFrequentKeywords: const [overview],
      trendingKeywords: const [overview],
      statistics: const KeywordFrequencyStat(
        totalKeywordsAnalyzed: 1,
        totalRecentPublications: 64,
        hottestKeyword: 'Machine Learning',
        fastestGrowthRate: 100,
      ),
      trendSeries: const {'Machine Learning': patrolKeywordTrend},
      currentPeriodStart: DateTime(2024),
      currentPeriodEnd: DateTime(2024, 12, 31),
      previousPeriodStart: DateTime(2023),
      previousPeriodEnd: DateTime(2023, 12, 31),
      fetchedAt: DateTime(2024, 6, 1),
    );
  }
}

class PatrolFakeOpenAlexKeywordService extends OpenAlexKeywordService {
  @override
  Future<OpenAlexKeyword?> resolveKeyword(String keyword) async {
    debugPrint('[patrol harness] fake resolveKeyword("$keyword")');
    return patrolKeyword;
  }

  @override
  Future<KeywordAnalysisResult> analyzeResolvedKeyword(
    String keyword,
    OpenAlexKeyword resolvedKeyword, {
    int fromYear = 2011,
    int? toYear,
  }) async {
    debugPrint('[patrol harness] fake analyzeResolvedKeyword("$keyword")');
    return const KeywordAnalysisResult(
      keyword: 'Machine Learning',
      resolvedKeyword: patrolKeyword,
      trend: patrolKeywordTrend,
      relevantPapers: [patrolKeywordPaper],
      mostCitedPapers: [patrolKeywordPaper],
      latestPapers: [patrolKeywordPaper],
      openAccessPapers: [patrolKeywordPaper],
      topAuthors: {'Ada Lovelace': 7, 'Alan Turing': 5},
      topSources: {'Journal of Reliable UI Tests': 3},
    );
  }

  @override
  Future<KeywordAnalysisResult> analyzeKeyword(
    String keyword, {
    int fromYear = 2011,
    int? toYear,
  }) {
    return analyzeResolvedKeyword(keyword, patrolKeyword);
  }

  @override
  Future<List<KeywordTrendPoint>> fetchKeywordTrend({
    required String keyword,
    int fromYear = 2011,
    int? toYear,
  }) async {
    return patrolKeywordTrend;
  }
}

class PatrolFakeZoteroService extends ZoteroService {
  PatrolFakeZoteroService() : super(apiKey: 'patrol', userId: 'patrol');

  @override
  Future<String> savePublicationToZotero(Publication publication) async {
    return 'PATROL_ZOTERO_KEY';
  }
}

Future<void> launchPatrolApp(PatrolIntegrationTester $) async {
  debugPrint('[patrol harness] launching deterministic AppShell');

  final authService = FakeAuthService(initialUser: fakeUser());
  final analyticsService = const NoOpAnalyticsService();
  final selectedTopicViewModel = SelectedTopicViewModel();
  final openAlexService = PatrolFakeOpenAlexService();
  final suggestionService = PatrolFakeSuggestionService();
  final keywordDashboardService = PatrolFakeKeywordDashboardService();
  final keywordService = PatrolFakeOpenAlexKeywordService();
  final authViewModel = AuthViewModel(
    authService: authService,
    analyticsService: analyticsService,
  );

  await $.tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<AppAnalyticsService>.value(value: analyticsService),
        Provider<OpenAlexService>.value(value: openAlexService),
        Provider.value(value: OpenAlexJournalService()),
        Provider<SuggestionService>.value(value: suggestionService),
        Provider<KeywordDashboardService>.value(value: keywordDashboardService),
        Provider<OpenAlexKeywordService>.value(value: keywordService),
        Provider<ZoteroService>.value(value: PatrolFakeZoteroService()),
        Provider<ReportMetadataService>.value(
          value: const NoOpReportMetadataService(),
        ),
        ChangeNotifierProvider.value(value: authViewModel),
        ChangeNotifierProvider.value(value: selectedTopicViewModel),
        ChangeNotifierProvider(
          create: (_) => HomeViewModel(
            openAlexService,
            historyService: PatrolFakeHistoryService(),
            suggestionService: suggestionService,
            selectedTopicViewModel: selectedTopicViewModel,
            analyticsService: analyticsService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => TrendAnalysisViewModel(service: openAlexService),
        ),
        ChangeNotifierProvider(create: (_) => AnalyticsViewModel()),
        ChangeNotifierProvider(
          create: (_) => KeywordDashboardViewModel(keywordDashboardService),
        ),
        ChangeNotifierProvider(
          create: (_) => KeywordAnalyzerViewModel(keywordService),
        ),
        ChangeNotifierProvider(
          create: (_) => JournalViewModel(
            OpenAlexJournalService(),
            suggestionService: suggestionService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => UploadedReportsViewModel(
            metadataService: const NoOpReportMetadataService(),
            userIdResolver: () => authViewModel.currentUser?.uid,
          ),
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
  debugPrint('[patrol harness] launch complete');
}
