import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openalex/services/openalex_keyword_service.dart';

void main() {
  group('OpenAlexKeywordService', () {
    test(
      'fetchKeywordTrend uses keyword id filter and publication date limit',
      () async {
        Uri? requestedUri;
        final service = OpenAlexKeywordService(
          client: MockClient((request) async {
            requestedUri = request.url;
            return http.Response(
              jsonEncode({
                'group_by': [
                  {'key': '2024', 'count': 2},
                  {'key': '${DateTime.now().toUtc().year + 1}', 'count': 5},
                ],
              }),
              200,
            );
          }),
        );

        final trend = await service.fetchKeywordTrendByKeywordId('C123');

        expect(requestedUri?.queryParameters.containsKey('search'), isFalse);
        expect(requestedUri?.queryParameters['group_by'], 'publication_year');
        expect(
          requestedUri?.queryParameters['filter'],
          'keywords.id:C123,to_publication_date:${_todayIsoDate()}',
        );
        expect(
          trend.map((point) => point.year),
          isNot(contains(DateTime.now().toUtc().year + 1)),
        );
      },
    );

    test(
      'fetchRelevantPapers uses keyword id filter without text search',
      () async {
        final requestedUris = <Uri>[];
        final service = _serviceCapturingUris(requestedUris);

        await service.fetchRelevantPapersByKeywordId('C123');

        expect(
          requestedUris.single.queryParameters.containsKey('search'),
          isFalse,
        );
        expect(
          requestedUris.single.queryParameters['filter'],
          'keywords.id:C123,to_publication_date:${_todayIsoDate()}',
        );
        expect(requestedUris.single.queryParameters['per-page'], '25');
      },
    );

    test('fetchMostCitedPapers uses citation sort and date limit', () async {
      final requestedUris = <Uri>[];
      final service = _serviceCapturingUris(requestedUris);

      await service.fetchMostCitedPapersByKeywordId('C123');

      expect(
        requestedUris.single.queryParameters['filter'],
        'keywords.id:C123,to_publication_date:${_todayIsoDate()}',
      );
      expect(
        requestedUris.single.queryParameters['sort'],
        'cited_by_count:desc',
      );
      expect(requestedUris.single.queryParameters['per-page'], '5');
      expect(
        requestedUris.single.queryParameters['mailto'],
        OpenAlexKeywordService.mailto,
      );
    });

    test(
      'fetchLatestPapers uses publication date sort and date limit',
      () async {
        final requestedUris = <Uri>[];
        final service = _serviceCapturingUris(requestedUris);

        await service.fetchLatestPapersByKeywordId('C123');

        expect(
          requestedUris.single.queryParameters['filter'],
          'keywords.id:C123,to_publication_date:${_todayIsoDate()}',
        );
        expect(
          requestedUris.single.queryParameters['sort'],
          'publication_date:desc',
        );
        expect(requestedUris.single.queryParameters['per-page'], '5');
      },
    );

    test('fetchOpenAccessPapers uses OA filter and date limit', () async {
      final requestedUris = <Uri>[];
      final service = _serviceCapturingUris(requestedUris);

      await service.fetchOpenAccessPapersByKeywordId('C123');

      expect(
        requestedUris.single.queryParameters['filter'],
        'keywords.id:C123,open_access.is_oa:true,to_publication_date:${_todayIsoDate()}',
      );
      expect(
        requestedUris.single.queryParameters['sort'],
        'cited_by_count:desc',
      );
      expect(requestedUris.single.queryParameters['per-page'], '5');
    });

    test('filters out future-dated papers after parsing', () async {
      final service = OpenAlexKeywordService(
        client: MockClient((request) async {
          return http.Response(
            jsonEncode({
              'results': [
                {
                  'id': 'W1',
                  'display_name': 'Valid Paper',
                  'publication_year': DateTime.now().toUtc().year,
                  'publication_date': _todayIsoDate(),
                },
                {
                  'id': 'W2',
                  'display_name': 'Future Paper',
                  'publication_year': DateTime.now().toUtc().year + 1,
                  'publication_date':
                      '${DateTime.now().toUtc().year + 1}-01-01',
                },
              ],
            }),
            200,
          );
        }),
      );

      final papers = await service.fetchLatestPapersByKeywordId('C123');

      expect(papers.map((paper) => paper.title), ['Valid Paper']);
    });
  });

  group('fetchTopAuthorsByKeywordId', () {
    test('sends correct group_by param and filter', () async {
      Uri? capturedUri;
      final service = OpenAlexKeywordService(
        client: MockClient((request) async {
          capturedUri = request.url;
          return http.Response(jsonEncode({'group_by': []}), 200);
        }),
      );

      await service.fetchTopAuthorsByKeywordId('C123');

      expect(
        capturedUri?.queryParameters['group_by'],
        'authorships.author.id',
      );
      expect(
        capturedUri?.queryParameters['filter'],
        'keywords.id:C123,to_publication_date:${_todayIsoDate()}',
      );
    });

    test('parses group_by response into Map<String, int>', () async {
      final service = OpenAlexKeywordService(
        client: MockClient((_) async => http.Response(
          jsonEncode({
            'group_by': [
              {'key': 'A1', 'key_display_name': 'John Doe', 'count': 42},
              {'key': 'A2', 'key_display_name': 'Jane Smith', 'count': 28},
            ],
          }),
          200,
        )),
      );

      final result = await service.fetchTopAuthorsByKeywordId('C123');

      expect(result, {'John Doe': 42, 'Jane Smith': 28});
    });

    test('skips entries with empty or null display name', () async {
      final service = OpenAlexKeywordService(
        client: MockClient((_) async => http.Response(
          jsonEncode({
            'group_by': [
              {'key': 'A1', 'key_display_name': 'John Doe', 'count': 42},
              {'key': 'A2', 'key_display_name': '', 'count': 10},
              {'key': 'A3', 'key_display_name': null, 'count': 5},
            ],
          }),
          200,
        )),
      );

      final result = await service.fetchTopAuthorsByKeywordId('C123');

      expect(result.keys, ['John Doe']);
    });

    test('returns empty map when group_by field is absent', () async {
      final service = OpenAlexKeywordService(
        client: MockClient((_) async => http.Response(jsonEncode({}), 200)),
      );

      final result = await service.fetchTopAuthorsByKeywordId('C123');

      expect(result, isEmpty);
    });

    test('respects custom perPage param', () async {
      Uri? capturedUri;
      final service = OpenAlexKeywordService(
        client: MockClient((request) async {
          capturedUri = request.url;
          return http.Response(jsonEncode({'group_by': []}), 200);
        }),
      );

      await service.fetchTopAuthorsByKeywordId('C123', perPage: 20);

      expect(capturedUri?.queryParameters['per-page'], '20');
    });
  });

  group('fetchTopJournalsByKeywordId', () {
    test('sends correct group_by param', () async {
      Uri? capturedUri;
      final service = OpenAlexKeywordService(
        client: MockClient((request) async {
          capturedUri = request.url;
          return http.Response(jsonEncode({'group_by': []}), 200);
        }),
      );

      await service.fetchTopJournalsByKeywordId('C123');

      expect(
        capturedUri?.queryParameters['group_by'],
        'primary_location.source.id',
      );
    });

    test('parses group_by response into Map<String, int>', () async {
      final service = OpenAlexKeywordService(
        client: MockClient((_) async => http.Response(
          jsonEncode({
            'group_by': [
              {'key': 'S1', 'key_display_name': 'Nature', 'count': 100},
              {'key': 'S2', 'key_display_name': 'IEEE Access', 'count': 80},
            ],
          }),
          200,
        )),
      );

      final result = await service.fetchTopJournalsByKeywordId('C123');

      expect(result, {'Nature': 100, 'IEEE Access': 80});
    });
  });

  group('analyzeKeyword – topAuthors and topSources', () {
    test('populates topAuthors and topSources from group_by responses',
        () async {
      final service = OpenAlexKeywordService(
        client: MockClient((request) async {
          final params = request.url.queryParameters;

          if (request.url.path == '/keywords') {
            return http.Response(
              jsonEncode({
                'results': [
                  {
                    'id': 'C123',
                    'display_name': 'AI',
                    'works_count': 100,
                    'cited_by_count': 500,
                  },
                ],
              }),
              200,
            );
          }

          if (params['group_by'] == 'publication_year') {
            return http.Response(
              jsonEncode({
                'group_by': [
                  {'key': '2024', 'count': 10},
                ],
              }),
              200,
            );
          }

          if (params['group_by'] == 'authorships.author.id') {
            return http.Response(
              jsonEncode({
                'group_by': [
                  {'key': 'A1', 'key_display_name': 'John Doe', 'count': 5},
                ],
              }),
              200,
            );
          }

          if (params['group_by'] == 'primary_location.source.id') {
            return http.Response(
              jsonEncode({
                'group_by': [
                  {'key': 'S1', 'key_display_name': 'Nature', 'count': 20},
                ],
              }),
              200,
            );
          }

          return http.Response(jsonEncode({'results': []}), 200);
        }),
      );

      final result = await service.analyzeKeyword('AI');

      expect(result.topAuthors, {'John Doe': 5});
      expect(result.topSources, {'Nature': 20});
    });
  });
}

OpenAlexKeywordService _serviceCapturingUris(List<Uri> requestedUris) {
  return OpenAlexKeywordService(
    client: MockClient((request) async {
      requestedUris.add(request.url);
      return http.Response(
        jsonEncode({
          'results': [
            {
              'id': 'W1',
              'display_name': 'Paper',
              'publication_year': 2024,
              'publication_date': '2024-01-01',
              'cited_by_count': 1,
            },
          ],
        }),
        200,
      );
    }),
  );
}

String _todayIsoDate() {
  final now = DateTime.now().toUtc();
  final y = now.year.toString().padLeft(4, '0');
  final m = now.month.toString().padLeft(2, '0');
  final d = now.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
