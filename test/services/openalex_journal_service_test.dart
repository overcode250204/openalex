import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openalex/models/journal/journal_publication.dart';
import 'package:openalex/models/journal/journal_source.dart';
import 'package:openalex/services/openalex_journal_service.dart';

void main() {
  group('JournalSource', () {
    test('parses nullable OpenAlex source fields safely', () {
      final source = JournalSource.fromJson({
        'id': 'https://openalex.org/S2770115547',
        'display_name': 'IEEE Access',
        'type': 'journal',
        'issn_l': '2169-3536',
        'issn': ['2169-3536'],
        'works_count': 78000,
        'cited_by_count': 900000,
        'summary_stats': {'h_index': 84},
      });

      expect(source.sourceId, 'S2770115547');
      expect(source.displayName, 'IEEE Access');
      expect(source.type, 'journal');
      expect(source.hIndex, 84);
      expect(source.displayPublisher, 'Unknown publisher');
    });
  });

  group('JournalPublication', () {
    test('parses work JSON and reconstructs abstract', () {
      final publication = JournalPublication.fromJson({
        'id': 'https://openalex.org/W123',
        'display_name': 'Journal Paper',
        'publication_year': 2024,
        'publication_date': '2024-05-01',
        'doi': 'https://doi.org/10.1109/test',
        'cited_by_count': 12,
        'authorships': [
          {
            'author': {'display_name': 'Ada Lovelace'},
          },
        ],
        'primary_location': {
          'landing_page_url': 'https://example.org/paper',
          'pdf_url': 'https://example.org/paper.pdf',
          'source': {
            'id': 'https://openalex.org/S2770115547',
            'display_name': 'IEEE Access',
          },
        },
        'open_access': {'is_oa': true},
        'abstract_inverted_index': {
          'Research': [0],
          'works': [1],
        },
      });

      expect(publication.workId, 'W123');
      expect(publication.title, 'Journal Paper');
      expect(publication.displayJournal, 'IEEE Access');
      expect(publication.sourceId, 'S2770115547');
      expect(publication.isOpenAccess, isTrue);
      expect(publication.abstractText, 'Research works');
    });
  });

  group('OpenAlexJournalService', () {
    test('searchJournals calls sources API and filters type journal', () async {
      Uri? requestedUri;
      final service = OpenAlexJournalService(
        client: MockClient((request) async {
          requestedUri = request.url;
          return http.Response(
            jsonEncode({
              'results': [
                {
                  'id': 'https://openalex.org/S1',
                  'display_name': 'Real Journal',
                  'type': 'journal',
                },
                {
                  'id': 'https://openalex.org/I1',
                  'display_name': 'Organization',
                  'type': 'institution',
                },
              ],
            }),
            200,
          );
        }),
      );

      final results = await service.searchJournals('IEEE Access');

      expect(requestedUri?.path, '/sources');
      expect(requestedUri?.queryParameters['search'], 'IEEE Access');
      expect(requestedUri?.queryParameters['filter'], 'type:journal');
      expect(requestedUri?.queryParameters['sort'], 'works_count:desc');
      expect(results.map((source) => source.displayName), ['Real Journal']);
    });

    test('getJournalPublications uses selected source id filter', () async {
      Uri? requestedUri;
      final service = OpenAlexJournalService(
        client: MockClient((request) async {
          requestedUri = request.url;
          return http.Response(
            jsonEncode({
              'results': [
                {'id': 'https://openalex.org/W1', 'display_name': 'Paper'},
              ],
            }),
            200,
          );
        }),
      );

      final publications = await service.getJournalPublications(
        'https://openalex.org/S2770115547',
      );

      expect(requestedUri?.path, '/works');
      expect(
        requestedUri?.queryParameters['filter'],
        'primary_location.source.id:S2770115547',
      );
      expect(requestedUri?.queryParameters['sort'], 'publication_date:desc');
      expect(requestedUri?.queryParameters['per-page'], '20');
      expect(publications.single.workId, 'W1');
    });

    test(
      'getHighestCitedPublication requests one citation-sorted work',
      () async {
        Uri? requestedUri;
        final service = OpenAlexJournalService(
          client: MockClient((request) async {
            requestedUri = request.url;
            return http.Response(
              jsonEncode({
                'results': [
                  {
                    'id': 'https://openalex.org/W2',
                    'display_name': 'Impact Paper',
                    'cited_by_count': 99,
                  },
                ],
              }),
              200,
            );
          }),
        );

        final publication = await service.getHighestCitedPublication('S1');

        expect(requestedUri?.queryParameters['sort'], 'cited_by_count:desc');
        expect(requestedUri?.queryParameters['per-page'], '1');
        expect(publication?.title, 'Impact Paper');
      },
    );

    test('getSourcesByIds batches a single request by id', () async {
      Uri? requestedUri;
      final service = OpenAlexJournalService(
        client: MockClient((request) async {
          requestedUri = request.url;
          return http.Response(
            jsonEncode({
              'results': [
                {
                  'id': 'https://openalex.org/S1',
                  'display_name': 'Journal A',
                  'type': 'journal',
                },
                {
                  'id': 'https://openalex.org/S2',
                  'display_name': 'Journal B',
                  'type': 'journal',
                },
              ],
            }),
            200,
          );
        }),
      );

      final sources = await service.getSourcesByIds(['S1', 'S2']);

      expect(requestedUri?.path, '/sources');
      expect(
        requestedUri?.queryParameters['filter'],
        'ids.openalex:S1|S2',
      );
      expect(sources.map((s) => s.displayName), ['Journal A', 'Journal B']);
    });

    test('getSourcesByIds returns empty without a request for no ids', () async {
      var requested = false;
      final service = OpenAlexJournalService(
        client: MockClient((request) async {
          requested = true;
          return http.Response(jsonEncode({'results': []}), 200);
        }),
      );

      final sources = await service.getSourcesByIds([]);

      expect(sources, isEmpty);
      expect(requested, isFalse);
    });
  });
}
