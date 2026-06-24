import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:openalex/main.dart';
import 'package:openalex/models/keyword/keyword_analysis_paper.dart';
import 'package:openalex/models/keyword/keyword_analysis_result.dart';
import 'package:openalex/models/keyword/keyword_dashboard_result.dart';
import 'package:openalex/models/keyword/keyword_frequency_stat.dart';
import 'package:openalex/models/keyword/keyword_overview.dart';
import 'package:openalex/models/keyword/keyword_trend_point.dart';
import 'package:openalex/models/keyword/openalex_keyword.dart';
import 'package:openalex/services/keyword_dashboard_service.dart';
import 'package:openalex/services/openalex_keyword_service.dart';
import 'package:openalex/services/suggestion_service.dart';
import 'package:openalex/utils/app_keys.dart';
import 'package:patrol_finders/patrol_finders.dart';

import '../test/fakes/fake_auth_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const config = PatrolTesterConfig(settlePolicy: SettlePolicy.noSettle);

  patrolWidgetTest(
    'Keywords tab can perform keyword analysis',
    ($) async {
      await _pumpKeywordTestApp($);
      await _openKeywordsTab($);
      await _analyzeMachineLearning($);

      expect(find.byKey(AppKeys.keywordDetailScreen), findsOneWidget);
      expect(find.byKey(AppKeys.keywordAnalysisResult), findsOneWidget);
      expect(find.text('machine learning'), findsWidgets);
      expect(find.byKey(AppKeys.keywordMetricsSection), findsOneWidget);
      expect(find.byKey(AppKeys.keywordTrendChart), findsOneWidget);
      expect(find.textContaining('Unable to'), findsNothing);
      expect(find.text('No keyword analysis data found.'), findsNothing);
    },
    config: config,
  );

  patrolWidgetTest(
    'Keyword Detail displays author ranking',
    ($) async {
      await _pumpKeywordTestApp($);
      await _openKeywordsTab($);
      await _analyzeMachineLearning($);

      await $.tester.ensureVisible(find.byKey(AppKeys.authorRankingSection));
      await $.tester.pumpAndSettle();

      expect(find.byKey(AppKeys.keywordDetailScreen), findsOneWidget);
      expect(find.byKey(AppKeys.keywordDetailTitle), findsOneWidget);
      expect(find.byKey(AppKeys.authorRankingSection), findsOneWidget);
      expect(find.byKey(AppKeys.authorRankingList), findsOneWidget);
      expect(find.byKey(AppKeys.authorRank1), findsOneWidget);
      expect(find.byKey(AppKeys.authorName1), findsOneWidget);
      expect(find.text('#1'), findsOneWidget);
      expect(find.text('Dr. Alice Nguyen'), findsOneWidget);
      expect(find.text('12 papers'), findsOneWidget);
    },
    config: config,
  );
}

Future<void> _pumpKeywordTestApp(PatrolTester $) async {
  await $.tester.pumpWidget(
    MyApp(
      authService: FakeAuthService(initialUser: fakeUser()),
      keywordService: _FakeOpenAlexKeywordService(),
      keywordDashboardService: _FakeKeywordDashboardService(),
      suggestionService: _FakeSuggestionService(),
    ),
  );
  await $.tester.pumpAndSettle();
}

Future<void> _openKeywordsTab(PatrolTester $) async {
  await $(find.byKey(AppKeys.navKeywordsTab)).tap();
  await $.tester.pumpAndSettle();

  expect(find.byKey(AppKeys.keywordSearchField), findsOneWidget);
}

Future<void> _analyzeMachineLearning(PatrolTester $) async {
  await $.tester.tap(find.byKey(AppKeys.keywordSearchField));
  await $.tester.enterText(
    find.byKey(AppKeys.keywordSearchField),
    'machine learning',
  );
  await $.tester.pumpAndSettle();

  await $(find.byKey(AppKeys.keywordAnalyzeButton)).tap();
  await $.tester.pumpAndSettle();
}

const _machineLearningKeyword = OpenAlexKeyword(
  id: 'keywords/machine-learning',
  displayName: 'machine learning',
  worksCount: 1234,
  citedByCount: 9876,
);

final _trend = <KeywordTrendPoint>[
  const KeywordTrendPoint(year: 2022, count: 18),
  const KeywordTrendPoint(year: 2023, count: 29),
  const KeywordTrendPoint(year: 2024, count: 41),
];

const _papers = <KeywordAnalysisPaper>[
  KeywordAnalysisPaper(
    id: 'https://openalex.org/W1001',
    title: 'Reliable machine learning for scientific discovery',
    publicationYear: 2024,
    publicationDate: '2024-03-14',
    sourceName: 'Journal of Machine Learning Research',
    doi: 'https://doi.org/10.0000/test.1001',
    citedByCount: 321,
    isOpenAccess: true,
    keywordScore: 0.96,
  ),
  KeywordAnalysisPaper(
    id: 'https://openalex.org/W1002',
    title: 'Interpretable models for applied machine learning',
    publicationYear: 2023,
    publicationDate: '2023-08-02',
    sourceName: 'Machine Learning',
    doi: 'https://doi.org/10.0000/test.1002',
    citedByCount: 210,
    isOpenAccess: false,
    keywordScore: 0.89,
  ),
];

class _FakeOpenAlexKeywordService extends OpenAlexKeywordService {
  @override
  Future<OpenAlexKeyword?> resolveKeyword(String keyword) async {
    return keyword.trim().toLowerCase() == 'machine learning'
        ? _machineLearningKeyword
        : null;
  }

  @override
  Future<KeywordAnalysisResult> analyzeKeyword(
    String keyword, {
    int fromYear = 2011,
    int? toYear,
  }) async {
    final resolved = await resolveKeyword(keyword);
    if (resolved == null) {
      throw KeywordNotFoundException('No matching OpenAlex keyword found.');
    }
    return analyzeResolvedKeyword(
      keyword,
      resolved,
      fromYear: fromYear,
      toYear: toYear,
    );
  }

  @override
  Future<KeywordAnalysisResult> analyzeResolvedKeyword(
    String keyword,
    OpenAlexKeyword resolvedKeyword, {
    int fromYear = 2011,
    int? toYear,
  }) async {
    return KeywordAnalysisResult(
      keyword: keyword.trim(),
      resolvedKeyword: resolvedKeyword,
      trend: _trend,
      relevantPapers: _papers,
      mostCitedPapers: _papers,
      latestPapers: _papers.reversed.toList(),
      openAccessPapers: [_papers.first],
      topAuthors: const {
        'Dr. Alice Nguyen': 12,
        'Prof. Bob Smith': 8,
        'Dr. Carla Rossi': 5,
      },
      topSources: const {
        'Journal of Machine Learning Research': 14,
        'Machine Learning': 9,
        'Artificial Intelligence': 6,
      },
    );
  }

  @override
  Future<List<KeywordTrendPoint>> fetchKeywordTrend({
    required String keyword,
    int fromYear = 2011,
    int? toYear,
  }) async {
    return _trend;
  }
}

class _FakeKeywordDashboardService extends KeywordDashboardService {
  @override
  Future<KeywordDashboardResult> fetchKeywordDashboard({
    DateTime? asOf,
    int? trendStartYear,
    int? trendEndYear,
    bool forceRefresh = false,
  }) async {
    final now = DateTime.utc(2026, 6, 25);
    const overview = KeywordOverview(
      id: 'keywords/machine-learning',
      name: 'machine learning',
      currentPeriodCount: 42,
      previousPeriodCount: 21,
      growthRate: 100,
      hotScore: 1,
      status: KeywordStatus.hot,
      trend: [
        KeywordTrendPoint(year: 2022, count: 18),
        KeywordTrendPoint(year: 2023, count: 29),
        KeywordTrendPoint(year: 2024, count: 41),
      ],
    );

    return KeywordDashboardResult(
      hottestKeyword: overview,
      mostFrequentKeywords: const [
        overview,
        KeywordOverview(
          id: 'keywords/deep-learning',
          name: 'deep learning',
          currentPeriodCount: 30,
          previousPeriodCount: 20,
          growthRate: 50,
          hotScore: 0.7,
          status: KeywordStatus.emerging,
        ),
      ],
      trendingKeywords: const [overview],
      statistics: const KeywordFrequencyStat(
        totalKeywordsAnalyzed: 3,
        totalRecentPublications: 72,
        hottestKeyword: 'machine learning',
        fastestGrowthRate: 100,
      ),
      trendSeries: {'machine learning': _trend},
      currentPeriodStart: DateTime.utc(2025, 6, 25),
      currentPeriodEnd: now,
      previousPeriodStart: DateTime.utc(2024, 6, 25),
      previousPeriodEnd: DateTime.utc(2025, 6, 24),
      fetchedAt: now,
    );
  }
}

class _FakeSuggestionService extends SuggestionService {
  @override
  Future<List<OpenAlexKeyword>> fetchOpenAlexKeywordSuggestions(
    String query,
  ) async {
    return query.trim().toLowerCase().contains('machine')
        ? [_machineLearningKeyword]
        : [];
  }
}
