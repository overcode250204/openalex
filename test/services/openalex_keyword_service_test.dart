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
        expect(requestedUris.single.queryParameters['per-page'], '5');
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
