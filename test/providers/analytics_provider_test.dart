import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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
    expect(provider.hasData, false);
    expect(provider.publicationTrend, isEmpty);
  });

  test('fetchAnalytics loading success', () async {
    when(() => mockService.fetchAll(any(), any())).thenAnswer(
      (_) async => const AnalyticsResult(
        publicationTrend: {2020: 10, 2021: 20},
        topKeywords: {'AI': 50},
        institutionRanking: {'MIT': 100},
        countryOutput: {'USA': 200},
        topAuthors: {'John Doe': 30},
        totalWorks: 500,
        mostCitedTitle: 'Great Paper',
        mostCitedCount: 100,
      ),
    );

    final future = provider.fetchAnalytics('test', const SearchFilter(), []);

    expect(provider.isLoading, true);

    await future;

    expect(provider.isLoading, false);
    expect(provider.error, isNull);
    expect(provider.hasData, true);
    expect(provider.publicationTrend, isNotEmpty);
    expect(provider.totalWorks, 500);
    expect(provider.topAuthorName, 'John Doe');
    expect(provider.mostCitedTitle, 'Great Paper');
  });

  test('fetchAnalytics loading failure', () async {
    when(
      () => mockService.fetchAll(any(), any()),
    ).thenThrow(Exception('API Error'));

    await provider.fetchAnalytics('test', const SearchFilter(), []);

    expect(provider.isLoading, false);
    expect(provider.error, contains('API Error'));
    expect(provider.hasData, false);
  });

  test('clear resets state', () async {
    when(() => mockService.fetchAll(any(), any())).thenAnswer(
      (_) async => const AnalyticsResult(
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
    when(() => mockService.fetchAll(any(), any())).thenAnswer(
      (_) async => const AnalyticsResult(
        publicationTrend: {2021: 10, 2022: 20, 2023: 30},
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
      () => mockService.fetchAll(any(), any()),
    ).thenAnswer((_) async => AnalyticsResult.empty());

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
}
