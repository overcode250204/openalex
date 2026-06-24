import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/models/auth/app_user.dart';
import 'package:openalex/models/publication/publication.dart';
import 'package:openalex/services/analytics/app_analytics_service.dart';
import 'package:openalex/viewmodels/home_view_model.dart';
import 'package:openalex/services/history_service.dart';
import 'package:openalex/services/openalex_service.dart';
import 'package:openalex/services/suggestion_service.dart';

class FakeOpenAlexService extends OpenAlexService {
  FakeOpenAlexService({
    this.results = const [],
    this.error,
    this.total = 0,
    this.topicIds = const ['T1'],
  });

  final List<Publication> results;
  int total;
  final Object? error;
  final List<String> topicIds;
  String? requestedKeyword;
  List<String>? requestedTopicIds;
  int? requestedFromYear;
  int? requestedToYear;

  @override
  Future<(int total, List<Publication> publications)> searchPublications({
    required String keyword,
    int perPage = 50,
    String sort = 'cited_by_count:desc',
    List<String>? topicIds,
  }) async {
    requestedKeyword = keyword;
    requestedTopicIds = topicIds;

    if (error != null) {
      throw error!;
    }

    return (total, results);
  }

  @override
  Future<List<String>> getTopicIdsFromKeyword(String keyword) async => topicIds;
}

class FakeSearchHistoryService extends SearchHistoryService {
  final List<String> _history = [];

  @override
  Future<void> addHistory(String keyword) async {
    _history.remove(keyword);
    _history.insert(0, keyword);
  }

  @override
  Future<List<String>> getHistory() async {
    return List<String>.from(_history);
  }
}

class FakeSuggestionService extends SuggestionService {
  @override
  Future<List<String>> fetchRelatedKeywords(String keyword) async {
    return [];
  }
}

class RecordingAnalyticsService implements AppAnalyticsService {
  final searchTopicEvents = <Map<String, Object?>>[];

  @override
  Future<void> logLogin({required AppUser user, required String method}) async {}

  @override
  Future<void> logLogout({
    required AppUser? user,
    required String method,
  }) async {}

  @override
  Future<void> clearUser() async {}

  @override
  Future<void> logSearchTopic(
    String keyword, {
    int? resultCount,
    String? searchSource,
    String? topicId,
    int? hasValidTopic,
    int? filterYearFrom,
    int? filterYearTo,
    int? openAccessOnly,
    String? sortOption,
  }) async {
    searchTopicEvents.add({
      'keyword': keyword,
      'resultCount': resultCount,
      'searchSource': searchSource,
      'topicId': topicId,
      'hasValidTopic': hasValidTopic,
      'filterYearFrom': filterYearFrom,
      'filterYearTo': filterYearTo,
      'openAccessOnly': openAccessOnly,
      'sortOption': sortOption,
    });
  }

  @override
  Future<void> logViewKeyword({required String keyword}) async {}

  @override
  Future<void> logViewPublication({
    required String publicationTitle,
    required int? publicationYear,
  }) async {}
}

HomeViewModel testProvider(
  OpenAlexService service, {
  AppAnalyticsService? analyticsService,
}) {
  return HomeViewModel(
    service,
    historyService: FakeSearchHistoryService(),
    suggestionService: FakeSuggestionService(),
    analyticsService: analyticsService ?? RecordingAnalyticsService(),
  );
}

Publication publication({
  required String title,
  required int citations,
  int? year,
  String? journal,
  List<String> authors = const [],
}) {
  return Publication(
    id: title,
    title: title,
    publicationYear: year,
    citedByCount: citations,
    journalName: journal,
    doi: null,
    abstractText: null,
    authors: authors,
    referencedWorkIds: List.empty(),
    relatedWorkIds: List.empty(),
    oaUrl: "",
  );
}

void main() {
  test('rejects empty search term without calling the service', () async {
    final service = FakeOpenAlexService();
    final provider = testProvider(service);
    var notifications = 0;
    provider.addListener(() => notifications++);

    await provider.searchPublications(keyword: '   ');

    expect(provider.errorMessage, 'Please enter a research topic.');
    expect(provider.isLoading, isFalse);
    expect(provider.publications, isEmpty);
    expect(service.requestedKeyword, isNull);
    expect(notifications, 1);
  });

  test('loads publications and exposes aggregate dashboard values', () async {
    final service = FakeOpenAlexService(
      results: [
        publication(
          title: 'First',
          citations: 5,
          year: 2022,
          journal: 'Journal A',
          authors: ['Ada', 'Grace'],
        ),
        publication(
          title: 'Second',
          citations: 20,
          year: 2023,
          journal: 'Journal A',
          authors: ['Ada'],
        ),
        publication(
          title: 'Third',
          citations: 1,
          year: 2023,
          journal: null,
          authors: ['Linus'],
        ),
      ],
    );
    final provider = testProvider(service);
    final loadingStates = <bool>[];
    provider.addListener(() => loadingStates.add(provider.isLoading));

    await provider.searchPublications(keyword: '  AI  ');

    expect(service.requestedKeyword, 'AI');
    expect(loadingStates, [true, false]);
    expect(provider.currentTopic, 'AI');
    expect(provider.currentTopicId, 'T1');
    expect(service.requestedTopicIds, ['T1']);
    expect(provider.errorMessage, isNull);
    expect(provider.totalPublications, 3);
    expect(provider.averageCitationCount, closeTo(26 / 3, 0.001));
    expect(provider.publicationCountByYear, {2022: 1, 2023: 2});
    expect(provider.mostActiveYear, 2023);
    expect(provider.topInfluentialPapers.map((p) => p.title), [
      'Second',
      'First',
      'Third',
    ]);
    expect(provider.mostInfluentialPaper?.title, 'Second');
    expect(provider.topJournals, {'Journal A': 2, 'Unknown journal': 1});
    expect(provider.topJournal, 'Journal A');
    expect(provider.topAuthors, {'Ada': 2, 'Grace': 1, 'Linus': 1});
    expect(provider.topAuthor, 'Ada');
  });

  test('logs search_topic after a successful topic search', () async {
    final analytics = RecordingAnalyticsService();
    final service = FakeOpenAlexService(
      total: 42,
      results: [publication(title: 'First', citations: 5, year: 2024)],
      topicIds: const ['T123'],
    );
    final provider = testProvider(service, analyticsService: analytics);

    await provider.searchPublications(keyword: '  AI  ');

    expect(analytics.searchTopicEvents, hasLength(1));
    expect(analytics.searchTopicEvents.single, {
      'keyword': 'AI',
      'resultCount': 42,
      'searchSource': 'manual',
      'topicId': 'T123',
      'hasValidTopic': 1,
      'filterYearFrom': null,
      'filterYearTo': null,
      'openAccessOnly': 0,
      'sortOption': 'relevance',
    });
  });

  test('does not log search_topic when topic search fails', () async {
    final analytics = RecordingAnalyticsService();
    final provider = testProvider(
      FakeOpenAlexService(error: Exception('boom')),
      analyticsService: analytics,
    );

    await provider.searchPublications(keyword: 'AI');

    expect(analytics.searchTopicEvents, isEmpty);
  });

  test(
    'clears publications and exposes friendly message on service failure',
    () async {
      final provider = testProvider(
        FakeOpenAlexService(error: Exception('boom')),
      );

      await provider.searchPublications(keyword: 'AI');

      expect(provider.publications, isEmpty);
      expect(provider.currentTopicId, 'T1');
      expect(provider.isLoading, isFalse);
      expect(
        provider.errorMessage,
        'Cannot load publications. Please try again.',
      );
      expect(provider.averageCitationCount, 0);
      expect(provider.mostActiveYear, isNull);
      expect(provider.topJournal, isNull);
      expect(provider.topAuthor, isNull);
      expect(provider.mostInfluentialPaper, isNull);
    },
  );
}
