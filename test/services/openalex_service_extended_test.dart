import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openalex/services/openalex_service.dart';

void main() {
  // ---------------------------------------------------------------------------
  // fetchInfluentialPapers
  // ---------------------------------------------------------------------------
  group('OpenAlexService.fetchInfluentialPapers', () {
    test('sends citation-sorted request and parses results', () async {
      Uri? capturedUri;
      final service = OpenAlexService(
        client: MockClient((request) async {
          capturedUri = request.url;
          return http.Response(
            jsonEncode({
              'results': [
                {
                  'id': 'W1',
                  'display_name': 'Influential Paper',
                  'publication_year': 2023,
                  'cited_by_count': 500,
                },
              ],
            }),
            200,
          );
        }),
      );

      final papers = await service.fetchInfluentialPapers(keyword: 'AI');

      expect(capturedUri?.queryParameters['sort'], 'cited_by_count:desc');
      expect(capturedUri?.queryParameters['search'], 'AI');
      expect(papers.single.title, 'Influential Paper');
    });

    test('respects the limit parameter as per-page', () async {
      Uri? capturedUri;
      final service = OpenAlexService(
        client: MockClient((request) async {
          capturedUri = request.url;
          return http.Response(jsonEncode({'results': []}), 200);
        }),
      );

      await service.fetchInfluentialPapers(keyword: 'ML', limit: 10);

      expect(capturedUri?.queryParameters['per-page'], '10');
    });

    test('defaults to per-page 200 when limit is null', () async {
      Uri? capturedUri;
      final service = OpenAlexService(
        client: MockClient((request) async {
          capturedUri = request.url;
          return http.Response(jsonEncode({'results': []}), 200);
        }),
      );

      await service.fetchInfluentialPapers(keyword: 'ML');

      expect(capturedUri?.queryParameters['per-page'], '200');
    });

    test('throws when response status is not 200', () {
      final service = OpenAlexService(
        client: MockClient((request) async => http.Response('error', 500)),
      );

      expect(
        () => service.fetchInfluentialPapers(keyword: 'AI'),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // getTopicIdsFromKeyword
  // ---------------------------------------------------------------------------
  group('OpenAlexService.getTopicIdsFromKeyword', () {
    test('returns empty list when response status is not 200', () async {
      final service = OpenAlexService(
        client: MockClient((request) async => http.Response('error', 500)),
      );

      final ids = await service.getTopicIdsFromKeyword('AI');

      expect(ids, isEmpty);
    });

    test('returns empty list when results are empty', () async {
      final service = OpenAlexService(
        client: MockClient(
          (request) async => http.Response(jsonEncode({'results': []}), 200),
        ),
      );

      final ids = await service.getTopicIdsFromKeyword('AI');

      expect(ids, isEmpty);
    });

    test('returns exact match id when a topic name matches exactly', () async {
      final service = OpenAlexService(
        client: MockClient(
          (request) async => http.Response(
            jsonEncode({
              'results': [
                {
                  'id': 'https://openalex.org/T_EXACT',
                  'display_name': 'Artificial Intelligence',
                },
                {
                  'id': 'https://openalex.org/T_OTHER',
                  'display_name': 'AI Applications',
                },
              ],
            }),
            200,
          ),
        ),
      );

      final ids = await service.getTopicIdsFromKeyword(
        'Artificial Intelligence',
      );

      expect(ids, hasLength(1));
      expect(ids.single, 'T_EXACT');
    });

    test('returns up to 3 topic ids when no exact match exists', () async {
      final service = OpenAlexService(
        client: MockClient(
          (request) async => http.Response(
            jsonEncode({
              'results': [
                {
                  'id': 'https://openalex.org/T1',
                  'display_name': 'AI Overview',
                },
                {'id': 'https://openalex.org/T2', 'display_name': 'AI Systems'},
                {'id': 'https://openalex.org/T3', 'display_name': 'AI Models'},
                {'id': 'https://openalex.org/T4', 'display_name': 'AI Ethics'},
              ],
            }),
            200,
          ),
        ),
      );

      final ids = await service.getTopicIdsFromKeyword('AI');

      expect(ids, hasLength(3));
      expect(ids, containsAll(['T1', 'T2', 'T3']));
      expect(ids, isNot(contains('T4')));
    });
  });

  // ---------------------------------------------------------------------------
  // fetchTopResearchJournals
  // ---------------------------------------------------------------------------
  group('OpenAlexService.fetchTopResearchJournals', () {
    test('aggregates publication counts per journal name', () async {
      final service = OpenAlexService(
        client: MockClient(
          (request) async => http.Response(
            jsonEncode({
              'results': [
                {
                  'primary_location': {
                    'source': {'display_name': 'Nature'},
                  },
                },
                {
                  'primary_location': {
                    'source': {'display_name': 'Nature'},
                  },
                },
                {
                  'primary_location': {
                    'source': {'display_name': 'IEEE'},
                  },
                },
              ],
            }),
            200,
          ),
        ),
      );

      final journals = await service.fetchTopResearchJournals(keyword: 'AI');

      expect(journals['Nature'], 2);
      expect(journals['IEEE'], 1);
    });

    test('uses Unknown Journal for missing source', () async {
      final service = OpenAlexService(
        client: MockClient(
          (request) async => http.Response(
            jsonEncode({
              'results': [
                {'primary_location': null},
              ],
            }),
            200,
          ),
        ),
      );

      final journals = await service.fetchTopResearchJournals(keyword: 'AI');

      expect(journals['Unknown Journal'], 1);
    });

    test('respects the limit parameter', () async {
      final service = OpenAlexService(
        client: MockClient(
          (request) async => http.Response(
            jsonEncode({
              'results': [
                {
                  'primary_location': {
                    'source': {'display_name': 'Journal A'},
                  },
                },
                {
                  'primary_location': {
                    'source': {'display_name': 'Journal B'},
                  },
                },
                {
                  'primary_location': {
                    'source': {'display_name': 'Journal C'},
                  },
                },
              ],
            }),
            200,
          ),
        ),
      );

      final journals = await service.fetchTopResearchJournals(
        keyword: 'AI',
        limit: 2,
      );

      expect(journals.length, 2);
    });

    test('throws when response is not 200', () {
      final service = OpenAlexService(
        client: MockClient((request) async => http.Response('error', 500)),
      );

      expect(
        () => service.fetchTopResearchJournals(keyword: 'AI'),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // fetchTopResearchJournalRanks
  // ---------------------------------------------------------------------------
  group('OpenAlexService.fetchTopResearchJournalRanks', () {
    test('parses group_by results with source id, name, and count', () async {
      final service = OpenAlexService(
        client: MockClient(
          (request) async => http.Response(
            jsonEncode({
              'group_by': [
                {
                  'key': 'https://openalex.org/S1',
                  'key_display_name': 'Nature',
                  'count': 12,
                },
                {
                  'key': 'https://openalex.org/S2',
                  'key_display_name': 'IEEE Access',
                  'count': 7,
                },
              ],
            }),
            200,
          ),
        ),
      );

      final ranks = await service.fetchTopResearchJournalRanks(keyword: 'AI');

      expect(ranks, hasLength(2));
      expect(ranks[0].sourceId, 'S1');
      expect(ranks[0].displayName, 'Nature');
      expect(ranks[0].count, 12);
      expect(ranks[1].sourceId, 'S2');
    });

    test(
      'falls back to per-work aggregation with source id when group_by is empty',
      () async {
        final service = OpenAlexService(
          client: MockClient(
            (request) async => http.Response(
              jsonEncode({
                'results': [
                  {
                    'primary_location': {
                      'source': {
                        'id': 'https://openalex.org/S1',
                        'display_name': 'Nature',
                      },
                    },
                  },
                  {
                    'primary_location': {
                      'source': {
                        'id': 'https://openalex.org/S1',
                        'display_name': 'Nature',
                      },
                    },
                  },
                  {
                    'primary_location': {
                      'source': {
                        'id': 'https://openalex.org/S2',
                        'display_name': 'IEEE',
                      },
                    },
                  },
                ],
              }),
              200,
            ),
          ),
        );

        final ranks = await service.fetchTopResearchJournalRanks(
          keyword: 'AI',
        );

        expect(ranks, hasLength(2));
        expect(ranks[0].sourceId, 'S1');
        expect(ranks[0].count, 2);
        expect(ranks[1].sourceId, 'S2');
        expect(ranks[1].count, 1);
      },
    );

    test(
      'uses Unknown Journal and empty sourceId for a missing source',
      () async {
        final service = OpenAlexService(
          client: MockClient(
            (request) async => http.Response(
              jsonEncode({
                'results': [
                  {'primary_location': null},
                ],
              }),
              200,
            ),
          ),
        );

        final ranks = await service.fetchTopResearchJournalRanks(
          keyword: 'AI',
        );

        expect(ranks, hasLength(1));
        expect(ranks.single.sourceId, isEmpty);
        expect(ranks.single.displayName, 'Unknown Journal');
      },
    );

    test('respects the limit parameter in the fallback path', () async {
      final service = OpenAlexService(
        client: MockClient(
          (request) async => http.Response(
            jsonEncode({
              'results': [
                {
                  'primary_location': {
                    'source': {
                      'id': 'https://openalex.org/S1',
                      'display_name': 'Journal A',
                    },
                  },
                },
                {
                  'primary_location': {
                    'source': {
                      'id': 'https://openalex.org/S2',
                      'display_name': 'Journal B',
                    },
                  },
                },
                {
                  'primary_location': {
                    'source': {
                      'id': 'https://openalex.org/S3',
                      'display_name': 'Journal C',
                    },
                  },
                },
              ],
            }),
            200,
          ),
        ),
      );

      final ranks = await service.fetchTopResearchJournalRanks(
        keyword: 'AI',
        limit: 2,
      );

      expect(ranks, hasLength(2));
    });

    test('throws when response is not 200', () {
      final service = OpenAlexService(
        client: MockClient((request) async => http.Response('error', 500)),
      );

      expect(
        () => service.fetchTopResearchJournalRanks(keyword: 'AI'),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // fetchTopContributingAuthors
  // ---------------------------------------------------------------------------
  group('OpenAlexService.fetchTopContributingAuthors', () {
    test('counts author appearances across works', () async {
      final service = OpenAlexService(
        client: MockClient(
          (request) async => http.Response(
            jsonEncode({
              'results': [
                {
                  'authorships': [
                    {
                      'author': {'display_name': 'Ada Lovelace'},
                    },
                    {
                      'author': {'display_name': 'Grace Hopper'},
                    },
                  ],
                },
                {
                  'authorships': [
                    {
                      'author': {'display_name': 'Ada Lovelace'},
                    },
                  ],
                },
              ],
            }),
            200,
          ),
        ),
      );

      final authors = await service.fetchTopContributingAuthors(keyword: 'AI');

      expect(authors['Ada Lovelace'], 2);
      expect(authors['Grace Hopper'], 1);
    });

    test('skips authors with null display_name', () async {
      final service = OpenAlexService(
        client: MockClient(
          (request) async => http.Response(
            jsonEncode({
              'results': [
                {
                  'authorships': [
                    {
                      'author': {'display_name': null},
                    },
                    {
                      'author': {'display_name': 'Known Author'},
                    },
                  ],
                },
              ],
            }),
            200,
          ),
        ),
      );

      final authors = await service.fetchTopContributingAuthors(keyword: 'AI');

      expect(authors.containsKey(null), isFalse);
      expect(authors['Known Author'], 1);
    });

    test('respects the limit parameter', () async {
      final service = OpenAlexService(
        client: MockClient(
          (request) async => http.Response(
            jsonEncode({
              'results': [
                {
                  'authorships': [
                    {
                      'author': {'display_name': 'Author A'},
                    },
                    {
                      'author': {'display_name': 'Author B'},
                    },
                    {
                      'author': {'display_name': 'Author C'},
                    },
                  ],
                },
              ],
            }),
            200,
          ),
        ),
      );

      final authors = await service.fetchTopContributingAuthors(
        keyword: 'AI',
        limit: 2,
      );

      expect(authors.length, 2);
    });

    test('throws when response is not 200', () {
      final service = OpenAlexService(
        client: MockClient((request) async => http.Response('error', 500)),
      );

      expect(
        () => service.fetchTopContributingAuthors(keyword: 'AI'),
        throwsA(isA<Exception>()),
      );
    });

    test('returns empty map for empty results', () async {
      final service = OpenAlexService(
        client: MockClient(
          (request) async => http.Response(jsonEncode({'results': []}), 200),
        ),
      );

      final authors = await service.fetchTopContributingAuthors(keyword: 'AI');

      expect(authors, isEmpty);
    });
  });
}
