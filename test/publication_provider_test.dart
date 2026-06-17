import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/models/publication.dart';
import 'package:openalex/providers/publication_provider.dart';
import 'package:openalex/services/history_service.dart';
import 'package:openalex/services/openalex_service.dart';
import 'package:openalex/services/suggestion_service.dart';

class FakeOpenAlexService extends OpenAlexService {
  FakeOpenAlexService({this.results = const [], this.error, this.total = 0});

  final List<Publication> results;
  int total;
  final Object? error;
  String? requestedKeyword;
  int? requestedFromYear;
  int? requestedToYear;

  @override
  Future<(int total, List<Publication> publications)> searchPublications({
    required String keyword,
    int perPage = 50,
    String sort = 'cited_by_count:desc',
    List<String>? topicIds
  }) async {
    requestedKeyword = keyword;

    if (error != null) {
      throw error!;
    }

    return (total, results);
  }

  
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

PublicationProvider testProvider(OpenAlexService service) {
  return PublicationProvider(
    service,
    historyService: FakeSearchHistoryService(),
    suggestionService: FakeSuggestionService(),
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
    oaUrl: ""
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

    await provider.searchPublications(
      keyword: '  AI  ',
    );

    expect(service.requestedKeyword, '  AI  ');
    expect(loadingStates, [true, false]);
    expect(provider.currentTopic, 'AI');
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

  test(
    'clears publications and exposes friendly message on service failure',
    () async {
      final provider = testProvider(
        FakeOpenAlexService(error: Exception('boom')),
      );

      await provider.searchPublications(keyword: 'AI');

      expect(provider.publications, isEmpty);
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
