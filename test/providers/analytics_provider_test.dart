import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openalex/models/analytics/topic_analytics.dart';
import 'package:openalex/models/publication/publication.dart';
import 'package:openalex/models/search/search_filter.dart';
import 'package:openalex/viewmodels/analytics_view_model.dart';
import 'package:openalex/services/analytics_service.dart';

class MockAnalyticsService extends Mock implements AnalyticsService {}

void main() {
  setUpAll(() {
    registerFallbackValue(const SearchFilter());
  });

  late MockAnalyticsService mockService;
  late AnalyticsViewModel provider;

  setUp(() {
    mockService = MockAnalyticsService();
    provider = AnalyticsViewModel(analyticsService: mockService);
  });

  test('initial state', () {
    expect(provider.isLoading, false);
    expect(provider.error, isNull);
    expect(provider.hasLoaded, false);
    expect(provider.hasData, false);
    expect(provider.publicationTrend, isEmpty);
  });

  test('fetchAnalytics loading success', () async {
    when(
      () => mockService.fetchAll(
        any(),
        any(),
        topicId: any<String?>(named: 'topicId'),
      ),
    ).thenAnswer(
      (_) async => const TopicAnalytics(
        publicationTrend: {2020: 10, 2021: 20},
        topKeywords: {'AI': 50},
        institutionRanking: {'MIT': 100},
        countryOutput: {'USA': 200},
        topAuthors: {'John Doe': 30},
        totalWorks: 500,
        analyzedWorks: 2,
        totalCitations: 120,
        mostInfluentialPaper: InfluentialPaperSummary(
          id: 'W1',
          title: 'Great Paper',
          citedByCount: 100,
        ),
      ),
    );

    final future = provider.fetchAnalytics('test', const SearchFilter(), []);

    expect(provider.isLoading, true);

    await future;

    expect(provider.isLoading, false);
    expect(provider.error, isNull);
    expect(provider.hasLoaded, true);
    expect(provider.hasData, true);
    expect(provider.publicationTrend, isNotEmpty);
    expect(provider.totalWorks, 500);
    expect(provider.averageCitations, 60);
    expect(provider.topAuthorName, 'John Doe');
    expect(provider.mostCitedTitle, 'Great Paper');
  });

  test('fetchAnalytics loading failure', () async {
    when(
      () => mockService.fetchAll(
        any(),
        any(),
        topicId: any<String?>(named: 'topicId'),
      ),
    ).thenThrow(Exception('API Error'));

    await provider.fetchAnalytics('test', const SearchFilter(), []);

    expect(provider.isLoading, false);
    expect(provider.error, contains('API Error'));
    expect(provider.hasData, false);
  });

  test('loads summary-only analytics for Trend Analysis', () async {
    when(
      () => mockService.fetchSummary(
        any(),
        any(),
        topicId: any<String?>(named: 'topicId'),
      ),
    ).thenAnswer(
      (_) async => const TopicAnalytics(
        publicationTrend: {2024: 7},
        topKeywords: {},
        institutionRanking: {},
        countryOutput: {},
        topAuthors: {'Ada': 4},
        topJournals: {'Nature': 3},
        totalWorks: 7,
        analyzedWorks: 7,
        totalCitations: 70,
        mostInfluentialPaper: InfluentialPaperSummary(
          id: 'W1',
          title: 'Top Work',
          citedByCount: 30,
        ),
      ),
    );

    final future = provider.fetchAnalytics(
      'AI',
      const SearchFilter(yearFrom: 2024, yearTo: 2024),
      [],
      topicId: 'T1',
      includeCharts: false,
    );

    expect(provider.isLoading, isTrue);
    await future;

    expect(provider.totalWorks, 7);
    expect(provider.averageCitations, 10);
    expect(provider.mostActiveYear, 2024);
    expect(provider.topAuthorName, 'Ada');
    expect(provider.topJournalName, 'Nature');
    expect(provider.mostCitedTitle, 'Top Work');
    verify(
      () => mockService.fetchSummary('AI', any(), topicId: 'T1'),
    ).called(1);
    verifyNever(
      () => mockService.fetchAll(
        any(),
        any(),
        topicId: any<String?>(named: 'topicId'),
      ),
    );
  });

  test('uses trend fallback and exposes error when summary fails', () async {
    when(
      () => mockService.fetchSummary(
        any(),
        any(),
        topicId: any<String?>(named: 'topicId'),
      ),
    ).thenThrow(Exception('API limit'));

    await provider.fetchAnalytics(
      'AI',
      const SearchFilter(yearFrom: 2023, yearTo: 2024),
      [],
      topicId: 'T1',
      fallbackTrend: const {2023: 2, 2024: 5},
      includeCharts: false,
    );

    expect(provider.error, contains('API limit'));
    expect(provider.totalWorks, 7);
    expect(provider.mostActiveYear, 2024);
    expect(provider.topAuthorName, isNull);
  });

  test('empty topic result loads safely with unavailable metrics', () async {
    when(
      () => mockService.fetchSummary(
        any(),
        any(),
        topicId: any<String?>(named: 'topicId'),
      ),
    ).thenAnswer((_) async => TopicAnalytics.empty());

    await provider.fetchAnalytics(
      'Empty topic',
      const SearchFilter(),
      [],
      topicId: 'T-empty',
      includeCharts: false,
    );

    expect(provider.hasLoaded, isTrue);
    expect(provider.totalWorks, 0);
    expect(provider.averageCitations, isNull);
    expect(provider.mostActiveYear, isNull);
    expect(provider.topAuthorName, isNull);
    expect(provider.topJournalName, isNull);
    expect(provider.mostInfluentialPaper, isNull);
  });

  test('force refresh retries after a summary API error', () async {
    var attempts = 0;
    when(
      () => mockService.fetchSummary(
        any(),
        any(),
        topicId: any<String?>(named: 'topicId'),
      ),
    ).thenAnswer((_) async {
      attempts++;
      if (attempts == 1) throw Exception('temporary error');
      return const TopicAnalytics(
        publicationTrend: {2024: 3},
        topKeywords: {},
        institutionRanking: {},
        countryOutput: {},
        totalWorks: 3,
      );
    });

    await provider.fetchAnalytics(
      'AI',
      const SearchFilter(),
      [],
      topicId: 'T1',
      includeCharts: false,
    );
    expect(provider.error, isNotNull);

    await provider.fetchAnalytics(
      'AI',
      const SearchFilter(),
      [],
      topicId: 'T1',
      includeCharts: false,
      forceRefresh: true,
    );

    expect(provider.error, isNull);
    expect(provider.totalWorks, 3);
    expect(attempts, 2);
  });

  test(
    'reuses the visible trend when the summary trend part is unavailable',
    () async {
      when(
        () => mockService.fetchSummary(
          any(),
          any(),
          topicId: any<String?>(named: 'topicId'),
        ),
      ).thenAnswer(
        (_) async => const TopicAnalytics(
          publicationTrend: {},
          topKeywords: {},
          institutionRanking: {},
          countryOutput: {},
          topAuthors: {'Ada': 2},
        ),
      );

      await provider.fetchAnalytics(
        'AI',
        const SearchFilter(yearFrom: 2023, yearTo: 2024),
        [],
        topicId: 'T1',
        fallbackTrend: const {2023: 2, 2024: 5},
        includeCharts: false,
      );

      expect(provider.publicationTrend, {2023: 2, 2024: 5});
      expect(provider.totalWorks, 7);
      expect(provider.mostActiveYear, 2024);
      expect(provider.topAuthorName, 'Ada');
    },
  );

  test('clear resets state', () async {
    when(
      () => mockService.fetchAll(
        any(),
        any(),
        topicId: any<String?>(named: 'topicId'),
      ),
    ).thenAnswer(
      (_) async => const TopicAnalytics(
        publicationTrend: {2020: 10},
        topKeywords: {},
        institutionRanking: {},
        countryOutput: {},
      ),
    );

    await provider.fetchAnalytics('test', const SearchFilter(), []);
    expect(provider.hasData, true);

    provider.clear();
    expect(provider.hasData, false);
    expect(provider.publicationTrend, isEmpty);
  });

  test('computed getters', () async {
    when(
      () => mockService.fetchAll(
        any(),
        any(),
        topicId: any<String?>(named: 'topicId'),
      ),
    ).thenAnswer(
      (_) async => const TopicAnalytics(
        publicationTrend: {2021: 10, 2022: 30, 2023: 30},
        topKeywords: {'AI': 50, 'ML': 30},
        institutionRanking: {},
        countryOutput: {},
        topJournals: {'Nature': 10},
      ),
    );

    await provider.fetchAnalytics('test', const SearchFilter(), []);

    expect(provider.publicationGrowthRate, isNotNull);
    expect(provider.latestCompleteYear, isNotNull);
    expect(provider.mostActiveYear, 2023);
    expect(provider.topJournalName, 'Nature');
    expect(provider.topKeywordName, 'AI');
  });

  test('author impact', () async {
    when(
      () => mockService.fetchAll(
        any(),
        any(),
        topicId: any<String?>(named: 'topicId'),
      ),
    ).thenAnswer(
      (_) async => const TopicAnalytics(
        publicationTrend: {},
        topKeywords: {},
        institutionRanking: {},
        countryOutput: {},
        authorImpact: [
          AuthorImpactSummary(name: 'Alice', paperCount: 2, totalCitations: 30),
          AuthorImpactSummary(name: 'Bob', paperCount: 1, totalCitations: 10),
        ],
      ),
    );

    final pubs = <Publication>[
      Publication(
        id: '1',
        title: 'Title 1',
        authors: ['Alice', 'Bob'],
        publicationYear: 2020,
        citedByCount: 10,
        journalName: '',
        doi: '',
        abstractText: '',
        relatedWorkIds: [],
        referencedWorkIds: [],
      ),
      Publication(
        id: '2',
        title: 'Title 2',
        authors: ['Alice'],
        publicationYear: 2021,
        citedByCount: 20,
        journalName: '',
        doi: '',
        abstractText: '',
        relatedWorkIds: [],
        referencedWorkIds: [],
      ),
    ];

    await provider.fetchAnalytics('test', const SearchFilter(), pubs);

    final impact = provider.authorImpact;
    expect(impact.length, 2);

    // Alice should have 2 papers, 30 citations
    final alice = impact.firstWhere((a) => a.name == 'Alice');
    expect(alice.paperCount, 2);
    expect(alice.totalCitations, 30);

    // Bob should have 1 paper, 10 citations
    final bob = impact.firstWhere((a) => a.name == 'Bob');
    expect(bob.paperCount, 1);
    expect(bob.totalCitations, 10);
  });

  test('does not duplicate an identical loaded or in-flight request', () async {
    final completer = Completer<TopicAnalytics>();
    when(
      () => mockService.fetchAll(
        any(),
        any(),
        topicId: any<String?>(named: 'topicId'),
      ),
    ).thenAnswer((_) => completer.future);

    final first = provider.fetchAnalytics(
      'AI',
      const SearchFilter(yearFrom: 2020, yearTo: 2024),
      [],
      topicId: 'T1',
    );
    final duplicate = provider.fetchAnalytics(
      'AI',
      const SearchFilter(yearFrom: 2020, yearTo: 2024),
      [],
      topicId: 'T1',
    );
    completer.complete(TopicAnalytics.empty());
    await Future.wait([first, duplicate]);

    await provider.fetchAnalytics(
      'AI',
      const SearchFilter(yearFrom: 2020, yearTo: 2024),
      [],
      topicId: 'T1',
    );

    verify(() => mockService.fetchAll('AI', any(), topicId: 'T1')).called(1);
  });

  test('refreshes for topic and year changes without stale values', () async {
    when(
      () => mockService.fetchAll(
        any(),
        any(),
        topicId: any<String?>(named: 'topicId'),
      ),
    ).thenAnswer((invocation) async {
      final topicId = invocation.namedArguments[#topicId] as String?;
      final filter = invocation.positionalArguments[1] as SearchFilter;
      final value = topicId == 'T2' ? 20 : (filter.yearFrom == 2022 ? 12 : 10);
      return TopicAnalytics(
        publicationTrend: {filter.yearFrom ?? 2020: value},
        topKeywords: const {},
        institutionRanking: const {},
        countryOutput: const {},
        totalWorks: value,
      );
    });

    await provider.fetchAnalytics(
      'AI',
      const SearchFilter(yearFrom: 2020),
      [],
      topicId: 'T1',
    );
    expect(provider.totalWorks, 10);

    await provider.fetchAnalytics(
      'AI',
      const SearchFilter(yearFrom: 2022),
      [],
      topicId: 'T1',
    );
    expect(provider.totalWorks, 12);

    await provider.fetchAnalytics(
      'Robotics',
      const SearchFilter(yearFrom: 2022),
      [],
      topicId: 'T2',
    );
    expect(provider.totalWorks, 20);
    expect(provider.publicationTrend.values.single, 20);
    verify(
      () => mockService.fetchAll(
        any(),
        any(),
        topicId: any<String?>(named: 'topicId'),
      ),
    ).called(3);
  });

  test('ignores a stale response after a newer topic request', () async {
    final first = Completer<TopicAnalytics>();
    final second = Completer<TopicAnalytics>();
    when(
      () => mockService.fetchAll(
        any(),
        any(),
        topicId: any<String?>(named: 'topicId'),
      ),
    ).thenAnswer((invocation) {
      final topicId = invocation.namedArguments[#topicId] as String?;
      return topicId == 'T1' ? first.future : second.future;
    });

    final oldRequest = provider.fetchAnalytics(
      'Old topic',
      const SearchFilter(),
      [],
      topicId: 'T1',
    );
    final newRequest = provider.fetchAnalytics(
      'New topic',
      const SearchFilter(),
      [],
      topicId: 'T2',
    );

    second.complete(
      const TopicAnalytics(
        publicationTrend: {2024: 9},
        topKeywords: {},
        institutionRanking: {},
        countryOutput: {},
        totalWorks: 9,
      ),
    );
    await newRequest;
    first.complete(
      const TopicAnalytics(
        publicationTrend: {2020: 99},
        topKeywords: {},
        institutionRanking: {},
        countryOutput: {},
        totalWorks: 99,
      ),
    );
    await oldRequest;

    expect(provider.totalWorks, 9);
    expect(provider.publicationTrend, {2024: 9});
    expect(provider.isLoading, false);
  });
}
