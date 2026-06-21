import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/models/publication.dart';
import 'package:openalex/models/search_filter.dart';
import 'package:openalex/models/topic.dart';
import 'package:openalex/providers/publication_provider.dart';
import 'package:openalex/services/openalex_service.dart';

class FakeFilterOpenAlexService extends OpenAlexService {
  FakeFilterOpenAlexService({required this.responses, this.errorOnCall});

  final List<(int total, List<Publication> publications)> responses;
  final int? errorOnCall;
  final List<Map<String, String>> requestedParams = [];
  var _callCount = 0;

  @override
  Future<(int total, List<Publication> publications)> searchWithFilter(
    Map<String, String> params,
  ) async {
    _callCount++;
    requestedParams.add(Map<String, String>.from(params));

    if (errorOnCall == _callCount) {
      throw Exception('boom');
    }

    return responses[_callCount - 1];
  }

  @override
  Future<List<String>> getTopicIdsFromKeyword(String keyword) async {
    return ['T10616', 'T10862', 'T12002'];
  }
}

Publication publication(String id, {int? year = 2024}) {
  return Publication(
    id: id,
    title: 'Paper $id',
    publicationYear: year,
    citedByCount: 1,
    journalName: 'Journal',
    doi: null,
    abstractText: null,
    authors: const ['Ada Lovelace'],
    referencedWorkIds: ["1", "2"],
    relatedWorkIds: ["1", "2"],
    oaUrl: "123",
  );
}

List<Publication> publications(int count, {String prefix = 'P'}) {
  return List.generate(count, (index) => publication('$prefix$index'));
}

void main() {
  group('PublicationProvider search feature flow', () {
    test(
      'searchWithFilter resets pagination and exposes total results',
      () async {
        final service = FakeFilterOpenAlexService(
          responses: [(120, publications(50))],
        );
        final provider = PublicationProvider(service);

        await provider.searchWithFilter('AI', null);

        expect(provider.currentTopic, 'AI');
        expect(provider.publications, hasLength(50));
        expect(provider.totalResults, 120);
        expect(provider.hasMore, isTrue);
        expect(provider.isLoading, isFalse);
        expect(provider.isLoadingMore, isFalse);
        expect(provider.errorMessage, isNull);
        expect(service.requestedParams.single['search'], 'AI');
        expect(service.requestedParams.single['page'], '1');
      },
    );

    test(
      'loadMore appends next page and stops when fewer than page size',
      () async {
        final service = FakeFilterOpenAlexService(
          responses: [
            (75, publications(50, prefix: 'A')),
            (75, publications(25, prefix: 'B')),
          ],
        );
        final provider = PublicationProvider(service);

        await provider.searchWithFilter('AI', null);
        await provider.loadMore();

        expect(provider.publications, hasLength(75));
        expect(provider.hasMore, isFalse);
        expect(service.requestedParams.map((params) => params['page']), [
          '1',
          '2',
        ]);
      },
    );

    test('updateFilter applies filters to the current topic', () async {
      final service = FakeFilterOpenAlexService(
        responses: [
          (10, publications(10)),
          (4, publications(4, prefix: 'Filtered')),
        ],
      );
      final provider = PublicationProvider(service);

      await provider.searchWithFilter('AI', null);
      await provider.updateFilter(
        const SearchFilter(
          yearFrom: 2020,
          yearTo: 2024,
          isOpenAccess: true,
          documentType: DocumentType.article,
          sortOption: SortOption.citedDesc,
        ),
      );

      final filteredParams = service.requestedParams.last;

      expect(provider.filter.yearFrom, 2020);
      expect(provider.publications, hasLength(4));
      expect(filteredParams['search'], 'AI');
      expect(filteredParams['page'], '1');
      expect(
        filteredParams['filter'],
        'publication_year:2020-2024,is_oa:true,type:article,primary_topic.id:T10616|T10862|T12002',
      );
      expect(filteredParams['sort'], 'cited_by_count:desc');
    });

    test(
      'resetFilter restores default filter without clearing results',
      () async {
        final service = FakeFilterOpenAlexService(
          responses: [(2, publications(2))],
        );
        final provider = PublicationProvider(service);

        await provider.updateFilter(
          const SearchFilter(sortOption: SortOption.yearDesc),
        );
        await provider.searchWithFilter('AI', null);

        provider.resetFilter();

        expect(provider.filter.sortOption, SortOption.relevance);
        expect(provider.publications, hasLength(2));
      },
    );

    test(
      'searchWithFilter exposes friendly error and clears stale results',
      () async {
        final service = FakeFilterOpenAlexService(
          responses: [(50, publications(50))],
          errorOnCall: 2,
        );
        final provider = PublicationProvider(service);

        await provider.searchWithFilter('AI', null);
        await provider.loadMore();

        expect(provider.publications, isEmpty);
        expect(
          provider.errorMessage,
          'Cannot load publications. Please try again.',
        );
        expect(provider.isLoading, isFalse);
        expect(provider.isLoadingMore, isFalse);
      },
    );

    test('searchWithFilter normalizes selected topic OpenAlex id', () async {
      final service = FakeFilterOpenAlexService(
        responses: [(1, publications(1))],
      );
      final provider = PublicationProvider(service);

      await provider.searchWithFilter(
        'AI',
        TopicSuggestion(
          id: 'https://openalex.org/T12345',
          displayName: 'Artificial intelligence',
          workCount: 10,
        ),
      );

      expect(
        service.requestedParams.single['filter'],
        contains('primary_topic.id:T12345'),
      );
      expect(
        service.requestedParams.single['filter'],
        isNot(contains('https://openalex.org/')),
      );
    });
  });
}
