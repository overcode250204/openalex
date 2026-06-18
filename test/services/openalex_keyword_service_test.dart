import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openalex/services/openalex_keyword_service.dart';

void main() {
  group('OpenAlexKeywordService', () {
    test('fetchKeywordTrend calls group_by endpoint', () async {
      Uri? requestedUri;
      final service = OpenAlexKeywordService(
        client: MockClient((request) async {
          requestedUri = request.url;
          return http.Response(
            jsonEncode({
              'group_by': [
                {'key': '2024', 'count': 2},
              ],
            }),
            200,
          );
        }),
      );

      final trend = await service.fetchKeywordTrend('machine learning');

      expect(requestedUri?.queryParameters['search'], 'machine learning');
      expect(requestedUri?.queryParameters['group_by'], 'publication_year');
      expect(
        requestedUri?.queryParameters['mailto'],
        OpenAlexKeywordService.mailto,
      );
      expect(trend.single.year, 2024);
    });

    test('fetchMostCitedPapers calls citation sort endpoint', () async {
      final requestedUris = <Uri>[];
      final service = _serviceCapturingUris(requestedUris);

      await service.fetchMostCitedPapers('machine learning');

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

    test('fetchLatestPapers calls publication date sort endpoint', () async {
      final requestedUris = <Uri>[];
      final service = _serviceCapturingUris(requestedUris);

      await service.fetchLatestPapers('machine learning');

      expect(
        requestedUris.single.queryParameters['sort'],
        'publication_date:desc',
      );
      expect(requestedUris.single.queryParameters['per-page'], '5');
    });

    test(
      'fetchOpenAccessPapers calls OA filter and citation sort endpoint',
      () async {
        final requestedUris = <Uri>[];
        final service = _serviceCapturingUris(requestedUris);

        await service.fetchOpenAccessPapers('machine learning');

        expect(
          requestedUris.single.queryParameters['filter'],
          'open_access.is_oa:true',
        );
        expect(
          requestedUris.single.queryParameters['sort'],
          'cited_by_count:desc',
        );
        expect(requestedUris.single.queryParameters['per-page'], '5');
      },
    );
  });
}

OpenAlexKeywordService _serviceCapturingUris(List<Uri> requestedUris) {
  return OpenAlexKeywordService(
    client: MockClient((request) async {
      requestedUris.add(request.url);
      return http.Response(
        jsonEncode({
          'results': [
            {'id': 'W1', 'display_name': 'Paper', 'cited_by_count': 1},
          ],
        }),
        200,
      );
    }),
  );
}
