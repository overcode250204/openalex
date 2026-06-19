import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/models/journal/journal_publication.dart';
import 'package:openalex/models/journal/journal_source.dart';
import 'package:openalex/providers/journal_search_provider.dart';
import 'package:openalex/services/openalex_journal_service.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeJournalService extends OpenAlexJournalService {
  final List<JournalSource> journalResults;
  final List<JournalPublication> publicationResults;
  final JournalPublication? highestCited;
  final Object? searchError;
  final Object? publicationsError;

  int getPublicationsCalls = 0;
  int getHighestCitedCalls = 0;
  List<String> requestedSourceIds = [];

  _FakeJournalService({
    this.journalResults = const [],
    this.publicationResults = const [],
    this.highestCited,
    this.searchError,
    this.publicationsError,
  });

  @override
  Future<List<JournalSource>> searchJournals(String query) async {
    if (searchError != null) throw searchError!;
    return journalResults;
  }

  @override
  Future<List<JournalPublication>> getJournalPublications(
    String sourceId, {
    int page = 1,
    int perPage = 20,
  }) async {
    getPublicationsCalls++;
    requestedSourceIds.add(sourceId);
    if (publicationsError != null) throw publicationsError!;
    return publicationResults;
  }

  @override
  Future<JournalPublication?> getHighestCitedPublication(
    String sourceId,
  ) async {
    getHighestCitedCalls++;
    return highestCited;
  }
}

JournalSource _source({String id = 'S1', String name = 'IEEE Access'}) {
  return JournalSource(
    id: 'https://openalex.org/$id',
    sourceId: id,
    displayName: name,
    type: 'journal',
    issnL: null,
    issn: [],
    worksCount: 1000,
    citedByCount: 50000,
    hIndex: 80,
    hostOrganizationName: null,
  );
}

JournalPublication _publication(String id) {
  return JournalPublication(
    id: 'https://openalex.org/W$id',
    workId: 'W$id',
    title: 'Paper $id',
    publicationYear: 2024,
    publicationDate: '2024-01-01',
    doi: null,
    citedByCount: 10,
    authors: ['Ada Lovelace'],
    journalName: 'IEEE Access',
    sourceId: 'S1',
    isOpenAccess: false,
    landingPageUrl: null,
    pdfUrl: null,
    abstractText: null,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('JournalSearchProvider initial state', () {
    test('has correct defaults', () {
      final provider = JournalSearchProvider(_FakeJournalService());

      expect(provider.searchQuery, '');
      expect(provider.journals, isEmpty);
      expect(provider.selectedJournal, isNull);
      expect(provider.publications, isEmpty);
      expect(provider.highestCitedPaper, isNull);
      expect(provider.selectedPublication, isNull);
      expect(provider.isSearchingJournals, isFalse);
      expect(provider.isLoadingPublications, isFalse);
      expect(provider.isLoadingMorePublications, isFalse);
      expect(provider.isLoadingHighestCited, isFalse);
      expect(provider.errorMessage, isNull);
      expect(provider.currentPage, 1);
      expect(provider.hasMorePublications, isTrue);
    });
  });

  group('JournalSearchProvider.searchJournals', () {
    test('sets errorMessage and skips HTTP when query is blank', () async {
      final service = _FakeJournalService(journalResults: [_source()]);
      final provider = JournalSearchProvider(service);

      await provider.searchJournals('   ');

      expect(provider.errorMessage, 'Please enter a journal name.');
      expect(provider.isSearchingJournals, isFalse);
      expect(provider.journals, isEmpty);
    });

    test('populates journals and clears error on success', () async {
      final service = _FakeJournalService(journalResults: [_source()]);
      final provider = JournalSearchProvider(service);

      final loadingStates = <bool>[];
      provider.addListener(
        () => loadingStates.add(provider.isSearchingJournals),
      );

      await provider.searchJournals('IEEE Access');

      expect(loadingStates, [true, false]);
      expect(provider.journals.single.displayName, 'IEEE Access');
      expect(provider.errorMessage, isNull);
    });

    test('sets error when no journals are found', () async {
      final provider = JournalSearchProvider(
        _FakeJournalService(journalResults: []),
      );

      await provider.searchJournals('Unknown Journal');

      expect(provider.errorMessage, 'No matching journal found.');
      expect(provider.journals, isEmpty);
    });

    test('sets generic error message on service exception', () async {
      final provider = JournalSearchProvider(
        _FakeJournalService(searchError: Exception('network error')),
      );

      await provider.searchJournals('Nature');

      expect(provider.errorMessage, contains('Cannot load data'));
      expect(provider.isSearchingJournals, isFalse);
    });

    test('resets state before new search', () async {
      final service = _FakeJournalService(journalResults: [_source()]);
      final provider = JournalSearchProvider(service);

      await provider.searchJournals('IEEE');
      expect(provider.journals, hasLength(1));

      // Second search with empty query resets journals
      await provider.searchJournals('   ');

      expect(provider.journals, isEmpty);
      expect(provider.selectedJournal, isNull);
    });
  });

  group('JournalSearchProvider.selectJournal', () {
    test('loads publications and highest cited in parallel', () async {
      final pub = _publication('1');
      final cited = _publication('99');
      final service = _FakeJournalService(
        publicationResults: [pub],
        highestCited: cited,
      );
      final provider = JournalSearchProvider(service);

      await provider.selectJournal(_source());

      expect(provider.selectedJournal?.displayName, 'IEEE Access');
      expect(provider.publications.single.workId, 'W1');
      expect(provider.highestCitedPaper?.workId, 'W99');
      expect(provider.isLoadingPublications, isFalse);
      expect(provider.isLoadingHighestCited, isFalse);
    });

    test('sets empty publications message when no papers exist', () async {
      final provider = JournalSearchProvider(
        _FakeJournalService(publicationResults: []),
      );

      await provider.selectJournal(_source());

      expect(provider.errorMessage, contains('no publications'));
    });

    test('sets error message when loading publications fails', () async {
      final provider = JournalSearchProvider(
        _FakeJournalService(publicationsError: Exception('boom')),
      );

      await provider.selectJournal(_source());

      expect(provider.errorMessage, contains('Cannot load data'));
      expect(provider.publications, isEmpty);
    });
  });

  group('JournalSearchProvider.loadMorePublications', () {
    test('appends next page and updates hasMore', () async {
      // Page 1 returns 20 results (full page → hasMore = true)
      final page1 = List.generate(20, (i) => _publication('P1_$i'));
      // Page 2 returns 15 results (partial → hasMore = false)
      final page2 = List.generate(15, (i) => _publication('P2_$i'));

      // Use anonymous override approach via extended fake
      final flexService = _FlexJournalService([page1, page2]);
      final provider = JournalSearchProvider(flexService);

      await provider.selectJournal(_source());
      expect(provider.publications, hasLength(20));
      expect(provider.hasMorePublications, isTrue);

      await provider.loadMorePublications();

      expect(provider.publications, hasLength(35));
      expect(provider.hasMorePublications, isFalse);

      expect(flexService._callIndex, 2);
    });

    test('does nothing when hasMore is false', () async {
      final service = _FakeJournalService(
        publicationResults: List.generate(5, (i) => _publication('$i')),
      );
      final provider = JournalSearchProvider(service);
      await provider.selectJournal(_source()); // loads 5 < 20 → hasMore=false

      final countBefore = service.getPublicationsCalls;
      await provider.loadMorePublications();

      expect(service.getPublicationsCalls, countBefore); // no new call
    });

    test('does nothing when no journal is selected', () async {
      final service = _FakeJournalService();
      final provider = JournalSearchProvider(service);

      await provider.loadMorePublications(); // should be a no-op

      expect(service.getPublicationsCalls, 0);
    });
  });

  group('JournalSearchProvider.selectPublication', () {
    test('stores the selected publication and notifies', () async {
      final pub = _publication('42');
      final service = _FakeJournalService(publicationResults: [pub]);
      final provider = JournalSearchProvider(service);
      await provider.selectJournal(_source());

      var notified = false;
      provider.addListener(() => notified = true);

      provider.selectPublication(pub);

      expect(provider.selectedPublication?.workId, 'W42');
      expect(notified, isTrue);
    });
  });

  group('JournalSearchProvider.clearSelection', () {
    test('resets all journal-related state', () async {
      final pub = _publication('1');
      final cited = _publication('99');
      final service = _FakeJournalService(
        publicationResults: [pub],
        highestCited: cited,
      );
      final provider = JournalSearchProvider(service);
      await provider.selectJournal(_source());

      provider.selectPublication(pub);
      expect(provider.selectedJournal, isNotNull);

      var notified = false;
      provider.addListener(() => notified = true);

      provider.clearSelection();

      expect(provider.selectedJournal, isNull);
      expect(provider.publications, isEmpty);
      expect(provider.highestCitedPaper, isNull);
      expect(provider.selectedPublication, isNull);
      expect(provider.currentPage, 1);
      expect(provider.hasMorePublications, isTrue);
      expect(provider.errorMessage, isNull);
      expect(notified, isTrue);
    });
  });
}

// Helper: sequential responses fake
class _FlexJournalService extends OpenAlexJournalService {
  final List<List<JournalPublication>> _pages;
  int _callIndex = 0;

  _FlexJournalService(this._pages);

  @override
  Future<List<JournalSource>> searchJournals(String query) async => [];

  @override
  Future<List<JournalPublication>> getJournalPublications(
    String sourceId, {
    int page = 1,
    int perPage = 20,
  }) async {
    if (_callIndex >= _pages.length) return [];
    return _pages[_callIndex++];
  }

  @override
  Future<JournalPublication?> getHighestCitedPublication(
    String sourceId,
  ) async => null;
}
