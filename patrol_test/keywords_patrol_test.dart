import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/models/keyword/keyword_analysis_paper.dart';
import 'package:openalex/models/keyword/keyword_analysis_result.dart';
import 'package:openalex/models/keyword/keyword_dashboard_result.dart';
import 'package:openalex/models/keyword/keyword_frequency_stat.dart';
import 'package:openalex/models/keyword/keyword_overview.dart';
import 'package:openalex/models/keyword/keyword_trend_point.dart';
import 'package:openalex/models/keyword/openalex_keyword.dart';
import 'package:openalex/routes/app_router.dart';
import 'package:openalex/routes/app_routes.dart';
import 'package:openalex/screens/app/app_shell_screen.dart';
import 'package:openalex/services/analytics/app_analytics_service.dart';
import 'package:openalex/services/analytics/no_op_analytics_service.dart';
import 'package:openalex/services/keyword_dashboard_service.dart';
import 'package:openalex/services/openalex_keyword_service.dart';
import 'package:openalex/services/openalex_service.dart';
import 'package:openalex/services/report/report_metadata_service.dart';
import 'package:openalex/services/suggestion_service.dart';
import 'package:openalex/utils/app_keys.dart';
import 'package:openalex/viewmodels/analytics_view_model.dart';
import 'package:openalex/viewmodels/auth_view_model.dart';
import 'package:openalex/viewmodels/home_view_model.dart';
import 'package:openalex/viewmodels/keyword_analyzer_view_model.dart';
import 'package:openalex/viewmodels/keyword_dashboard_view_model.dart';
import 'package:openalex/viewmodels/selected_topic_view_model.dart';
import 'package:openalex/viewmodels/uploaded_reports_view_model.dart';
import 'package:patrol/patrol.dart';
import 'package:provider/provider.dart';

import '../test/fakes/fake_auth_service.dart';

const _config = PatrolTesterConfig(
  settlePolicy: SettlePolicy.noSettle,
  visibleTimeout: Duration(seconds: 10),
  existsTimeout: Duration(seconds: 10),
  printLogs: true,
);

const _mostFrequentKeywordsListKey = Key('most_frequent_keywords_list');

const _keyword = OpenAlexKeyword(
  id: 'K_TEST_MACHINE_LEARNING',
  displayName: 'Machine Learning',
  worksCount: 128,
  citedByCount: 4096,
);

const _trend = [
  KeywordTrendPoint(year: 2022, count: 12),
  KeywordTrendPoint(year: 2023, count: 24),
  KeywordTrendPoint(year: 2024, count: 36),
];

const _paper = KeywordAnalysisPaper(
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

class _FakeKeywordDashboardService extends KeywordDashboardService {
  @override
  Future<KeywordDashboardResult> fetchKeywordDashboard({
    DateTime? asOf,
    bool forceRefresh = false,
    int? trendEndYear,
    int? trendStartYear,
  }) async {
    debugPrint('[keywords patrol] fake keyword dashboard requested');

    const overview = KeywordOverview(
      id: 'K_TEST_MACHINE_LEARNING',
      name: 'Machine Learning',
      currentPeriodCount: 64,
      previousPeriodCount: 32,
      growthRate: 100,
      hotScore: 98,
      status: KeywordStatus.hot,
      trend: _trend,
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
      trendSeries: const {'Machine Learning': _trend},
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
  Future<OpenAlexKeyword?> resolveKeyword(String keyword) async {
    debugPrint('[keywords patrol] fake resolveKeyword("$keyword")');
    return _keyword;
  }

  @override
  Future<KeywordAnalysisResult> analyzeResolvedKeyword(
    String keyword,
    OpenAlexKeyword resolvedKeyword, {
    int fromYear = 2011,
    int? toYear,
  }) async {
    debugPrint('[keywords patrol] fake analyzeResolvedKeyword("$keyword")');
    return const KeywordAnalysisResult(
      keyword: 'Machine Learning',
      resolvedKeyword: _keyword,
      trend: _trend,
      relevantPapers: [_paper],
      mostCitedPapers: [_paper],
      latestPapers: [_paper],
      openAccessPapers: [_paper],
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
    return analyzeResolvedKeyword(keyword, _keyword);
  }

  @override
  Future<List<KeywordTrendPoint>> fetchKeywordTrend({
    required String keyword,
    int fromYear = 2011,
    int? toYear,
  }) async {
    debugPrint('[keywords patrol] fake fetchKeywordTrend("$keyword")');
    return _trend;
  }
}

Future<void> _launchApp(PatrolIntegrationTester $) async {
  debugPrint('[keywords patrol] launching deterministic AppShell harness');

  final authService = FakeAuthService(initialUser: fakeUser());
  final analyticsService = const NoOpAnalyticsService();
  final selectedTopicViewModel = SelectedTopicViewModel();
  final openAlexService = OpenAlexService();
  final suggestionService = SuggestionService();
  final keywordDashboardService = _FakeKeywordDashboardService();
  final keywordService = _FakeOpenAlexKeywordService();
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
        Provider.value(value: keywordDashboardService),
        Provider.value(value: keywordService),
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
          create: (_) => KeywordDashboardViewModel(keywordDashboardService),
        ),
        ChangeNotifierProvider(
          create: (_) => KeywordAnalyzerViewModel(keywordService),
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
  debugPrint('[keywords patrol] harness pumped');
}

Future<void> _waitFor(
  PatrolIntegrationTester $,
  Finder finder, {
  required String label,
  Duration timeout = const Duration(seconds: 15),
}) async {
  debugPrint('[keywords patrol] waiting for $label');
  final end = DateTime.now().add(timeout);
  var attempts = 0;
  while (DateTime.now().isBefore(end)) {
    await $.pump(const Duration(milliseconds: 250));
    attempts++;
    if (finder.evaluate().isNotEmpty) {
      debugPrint('[keywords patrol] found $label after $attempts pumps');
      return;
    }
  }
  debugPrint('[keywords patrol] timed out waiting for $label');
  expect(finder, findsWidgets);
}

Future<void> _waitForKeywordDashboard(PatrolIntegrationTester $) async {
  debugPrint('[keywords patrol] waiting for keyword dashboard loaded state');
  final searchFinder = find.byKey(AppKeys.keywordSearchInput);
  final hotKeywordFinder = find.text('Current Hot Keyword');
  final loadingFinder = find.text('Loading keyword activity...');
  final emptyFinder = find.text('No recent keyword activity found.');
  final errorFinder = find.text(
    'Unable to load keyword activity. Please try again.',
  );

  final end = DateTime.now().add(const Duration(seconds: 15));
  var attempts = 0;
  while (DateTime.now().isBefore(end)) {
    await $.pump(const Duration(milliseconds: 250));
    attempts++;

    if (searchFinder.evaluate().isNotEmpty &&
        hotKeywordFinder.evaluate().isNotEmpty) {
      debugPrint(
        '[keywords patrol] keyword dashboard loaded after $attempts pumps',
      );
      return;
    }

    if (errorFinder.evaluate().isNotEmpty) {
      fail('Keywords dashboard rendered the error state.');
    }

    if (emptyFinder.evaluate().isNotEmpty) {
      fail('Keywords dashboard rendered the empty state.');
    }
  }

  final wasLoading = loadingFinder.evaluate().isNotEmpty;
  final wasEmpty = emptyFinder.evaluate().isNotEmpty;
  final wasError = errorFinder.evaluate().isNotEmpty;
  fail(
    'Timed out waiting for the keyword dashboard loaded state '
    '(${AppKeys.keywordSearchInput} + Current Hot Keyword). '
    'loading=$wasLoading empty=$wasEmpty error=$wasError',
  );
}

Future<void> _scrollDashboardUntilFound(
  PatrolIntegrationTester $,
  Finder finder, {
  required String label,
}) async {
  debugPrint('[keywords patrol] scrolling dashboard to $label');
  final scrollable = find.byType(ListView).first;

  for (var attempt = 0; attempt < 8; attempt++) {
    if (finder.evaluate().isNotEmpty) {
      debugPrint('[keywords patrol] found $label after $attempt scrolls');
      return;
    }
    await $.tester.drag(scrollable, const Offset(0, -420));
    await $.pump(const Duration(milliseconds: 250));
  }

  fail('Could not find $label after scrolling the keyword dashboard.');
}

Future<void> _ensureVisible(
  PatrolIntegrationTester $,
  Finder finder, {
  required String label,
}) async {
  debugPrint('[keywords patrol] ensuring $label is visible');
  await _waitFor($, finder, label: label);
  await $.tester.ensureVisible(finder);
  await $.pump(const Duration(milliseconds: 250));
}

Finder _byKeyPrefix(String prefix) {
  return find.byWidgetPredicate((widget) {
    final key = widget.key;
    return key is ValueKey<String> && key.value.startsWith(prefix);
  });
}

String _firstVisibleTextInside(Finder finder) {
  final texts = find
      .descendant(of: finder.first, matching: find.byType(Text))
      .evaluate()
      .map((element) => (element.widget as Text).data?.trim())
      .whereType<String>()
      .where((value) => value.isNotEmpty)
      .where((value) => !value.startsWith('#'))
      .toList();
  expect(texts, isNotEmpty);
  return texts.first;
}

void main() {
  patrolTest(
    'Keywords tab opens Keyword Detail and verifies analysis and authors',
    ($) async {
      debugPrint('[keywords patrol] test started');
      await _launchApp($);

      debugPrint('[keywords patrol] tapping Keywords tab');
      await $(find.byKey(AppKeys.keywordsTab)).tap();
      await _waitForKeywordDashboard($);
      expect($('Keyword Analyzer'), findsWidgets);
      expect(find.byKey(AppKeys.keywordSearchInput), findsOneWidget);

      await _scrollDashboardUntilFound(
        $,
        find.byKey(_mostFrequentKeywordsListKey),
        label: 'most frequent keywords list',
      );
      expect($('Most Frequent Keywords'), findsOneWidget);
      final keywordItem = _byKeyPrefix('keyword_item_');
      await _waitFor($, keywordItem, label: 'keyword item');
      final keywordName = _firstVisibleTextInside(keywordItem);
      debugPrint('[keywords patrol] tapping keyword "$keywordName"');

      await $(keywordItem.first).tap();
      await _waitFor(
        $,
        find.byKey(AppKeys.keywordDetailScreen),
        label: 'keyword detail screen',
      );
      await _waitFor(
        $,
        find.byKey(AppKeys.keywordAnalysisSection),
        label: 'keyword analysis section',
      );

      expect(find.text(keywordName), findsWidgets);
      expect($('Keyword Matched'), findsOneWidget);
      expect(find.byKey(AppKeys.keywordTrendSection), findsOneWidget);

      debugPrint('[keywords patrol] verifying author ranking');
      await _ensureVisible(
        $,
        find.byKey(AppKeys.authorRankingSection),
        label: 'author ranking section',
      );
      await _waitFor(
        $,
        find.byKey(AppKeys.authorRankingSection),
        label: 'author ranking section',
      );
      expect($('Top Contributing Authors'), findsOneWidget);
      final authorItem = _byKeyPrefix('author_ranking_item_');
      await _waitFor($, authorItem, label: 'author ranking item');
      expect(_firstVisibleTextInside(authorItem), contains(':'));

      debugPrint('[keywords patrol] verifying publications section');
      await _ensureVisible(
        $,
        find.byKey(AppKeys.keywordPublicationsSection),
        label: 'publications section',
      );
      expect($('Papers Using This Keyword'), findsOneWidget);
      final publicationsSection = find.byKey(
        AppKeys.keywordPublicationsSection,
      );

      expect(
        find.descendant(
          of: publicationsSection,
          matching: find.text(
            'Deterministic Keyword Analysis for Patrol Tests',
          ),
        ),
        findsWidgets,
      );

      debugPrint('[keywords patrol] test finished successfully');
    },
    config: _config,
    timeout: const Timeout(Duration(minutes: 1)),
  );
}
