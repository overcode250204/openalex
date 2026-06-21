import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openalex/services/keyword_dashboard_service.dart';

void main() {
  group('KeywordDashboardService trend range', () {
    test('fills 2011-2016 with zero when OpenAlex starts at 2017', () async {
      final service = KeywordDashboardService(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'group_by': [
                {'key': '2017', 'count': 17},
                {'key': '2026', 'count': 26},
              ],
            }),
            200,
          ),
        ),
      );

      final points = await service.fetchKeywordTrend(
        keywordId: 'test-keyword',
        startYear: 2011,
        endYear: 2026,
      );

      expect(
        points.map((point) => point.year),
        orderedEquals(List.generate(16, (i) => 2011 + i)),
      );
      expect(points.take(6).map((point) => point.count), everyElement(0));
      expect(points.firstWhere((point) => point.year == 2017).count, 17);
      expect(points.last.count, 26);
    });

    test('preserves every value returned for 2011-2026', () async {
      final groups = [
        for (var year = 2011; year <= 2026; year++)
          {'key': '$year', 'count': year - 2000},
      ];
      final service = KeywordDashboardService(
        client: MockClient(
          (_) async => http.Response(jsonEncode({'group_by': groups}), 200),
        ),
      );

      final points = await service.fetchKeywordTrend(
        keywordId: 'test-keyword',
        startYear: 2011,
        endYear: 2026,
      );

      expect(points, hasLength(16));
      for (final point in points) {
        expect(point.count, point.year - 2000);
      }
    });

    test('changing start year updates the API filter and mapped range', () async {
      Uri? requestedUri;
      final service = KeywordDashboardService(
        client: MockClient((request) async {
          requestedUri = request.url;
          return http.Response(jsonEncode({'group_by': []}), 200);
        }),
      );

      final points = await service.fetchKeywordTrend(
        keywordId: 'test-keyword',
        startYear: 2013,
        endYear: 2026,
      );

      expect(
        requestedUri!.queryParameters['filter'],
        'keywords.id:test-keyword,from_publication_date:2013-01-01,to_publication_date:2026-12-31',
      );
      expect(points.first.year, 2013);
      expect(points.last.year, 2026);
    });

    test('changing end year updates the API filter and mapped range', () async {
      Uri? requestedUri;
      final service = KeywordDashboardService(
        client: MockClient((request) async {
          requestedUri = request.url;
          return http.Response(jsonEncode({'group_by': []}), 200);
        }),
      );

      final points = await service.fetchKeywordTrend(
        keywordId: 'test-keyword',
        startYear: 2011,
        endYear: 2024,
      );

      final filter = requestedUri!.queryParameters['filter']!;
      expect(
        filter,
        'keywords.id:test-keyword,from_publication_date:2011-01-01,to_publication_date:2024-12-31',
      );
      expect(filter, isNot(contains('publication_year:')));
      expect(filter, isNot(contains('2017')));
      expect(points.first.year, 2011);
      expect(points.last.year, 2024);
    });
  });
}
