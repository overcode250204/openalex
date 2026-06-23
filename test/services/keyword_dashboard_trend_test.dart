import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openalex/services/keyword_dashboard_service.dart';

void main() {
  group('KeywordDashboardService trend range', () {
    test(
      'fills missing years with zero when OpenAlex starts at 2017',
      () async {
        Uri? requestedUri;

        final service = KeywordDashboardService(
          client: MockClient((request) async {
            requestedUri = request.url;

            return http.Response(
              jsonEncode({
                'group_by': [
                  {'key': '2017', 'count': 17},
                  {'key': '2026', 'count': 26},
                ],
              }),
              200,
            );
          }),
        );

        final points = await service.fetchKeywordTrend(
          keywordId: 'test-keyword',
          keywordName: 'Test Keyword',
          startYear: 2011,
          endYear: 2026,
        );

        expect(requestedUri, isNotNull);
        expect(requestedUri!.path, '/works');
        expect(requestedUri!.queryParameters['group_by'], 'publication_year');

        expect(
          requestedUri!.queryParameters['filter'],
          'keywords.id:test-keyword,'
          'from_publication_date:2011-01-01,'
          'to_publication_date:2026-12-31',
        );

        expect(points, hasLength(16));

        expect(
          points.map((point) => point.year),
          orderedEquals(List.generate(16, (index) => 2011 + index)),
        );

        for (var year = 2011; year <= 2016; year++) {
          final point = points.firstWhere((item) => item.year == year);
          expect(point.count, 0);
        }

        expect(points.firstWhere((point) => point.year == 2017).count, 17);

        for (var year = 2018; year <= 2025; year++) {
          final point = points.firstWhere((item) => item.year == year);
          expect(point.count, 0);
        }

        expect(points.firstWhere((point) => point.year == 2026).count, 26);
      },
    );

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
        keywordName: 'Test Keyword',
        startYear: 2011,
        endYear: 2026,
      );

      expect(points, hasLength(16));

      for (final point in points) {
        expect(point.count, point.year - 2000);
      }
    });

    test('changing start year updates API filter and mapped range', () async {
      Uri? requestedUri;

      final service = KeywordDashboardService(
        client: MockClient((request) async {
          requestedUri = request.url;

          return http.Response(
            jsonEncode({
              'group_by': [
                {'key': '2013', 'count': 5},
                {'key': '2026', 'count': 20},
              ],
            }),
            200,
          );
        }),
      );

      final points = await service.fetchKeywordTrend(
        keywordId: 'test-keyword',
        keywordName: 'Test Keyword',
        startYear: 2013,
        endYear: 2026,
      );

      expect(requestedUri, isNotNull);
      expect(requestedUri!.queryParameters['group_by'], 'publication_year');

      expect(
        requestedUri!.queryParameters['filter'],
        'keywords.id:test-keyword,'
        'from_publication_date:2013-01-01,'
        'to_publication_date:2026-12-31',
      );

      expect(points, hasLength(14));
      expect(points.first.year, 2013);
      expect(points.last.year, 2026);

      expect(points.first.count, 5);
      expect(points.last.count, 20);

      expect(points.any((point) => point.year < 2013), isFalse);
    });

    test('changing end year updates API filter and mapped range', () async {
      Uri? requestedUri;

      final service = KeywordDashboardService(
        client: MockClient((request) async {
          requestedUri = request.url;

          return http.Response(
            jsonEncode({
              'group_by': [
                {'key': '2011', 'count': 3},
                {'key': '2024', 'count': 24},
              ],
            }),
            200,
          );
        }),
      );

      final points = await service.fetchKeywordTrend(
        keywordId: 'test-keyword',
        keywordName: 'Test Keyword',
        startYear: 2011,
        endYear: 2024,
      );

      expect(requestedUri, isNotNull);
      expect(requestedUri!.queryParameters['group_by'], 'publication_year');

      final filter = requestedUri!.queryParameters['filter'];

      expect(
        filter,
        'keywords.id:test-keyword,'
        'from_publication_date:2011-01-01,'
        'to_publication_date:2024-12-31',
      );

      expect(filter, isNot(contains('publication_year:')));
      expect(filter, isNot(contains('2025')));
      expect(filter, isNot(contains('2026')));

      expect(points, hasLength(14));
      expect(points.first.year, 2011);
      expect(points.last.year, 2024);

      expect(points.first.count, 3);
      expect(points.last.count, 24);

      expect(points.any((point) => point.year > 2024), isFalse);
    });

    test('normalizes reversed year range into ascending points', () async {
      final service = KeywordDashboardService(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'group_by': [
                {'key': '2024', 'count': 4},
                {'key': '2026', 'count': 6},
              ],
            }),
            200,
          ),
        ),
      );

      final points = await service.fetchKeywordTrend(
        keywordId: 'test-keyword',
        keywordName: 'Test Keyword',
        startYear: 2026,
        endYear: 2024,
      );

      expect(points, hasLength(3));
      expect(
        points.map((point) => point.year),
        orderedEquals([2024, 2025, 2026]),
      );

      expect(points[0].count, 4);
      expect(points[1].count, 0);
      expect(points[2].count, 6);
    });

    test('throws exception when OpenAlex trend API returns non-200', () async {
      final service = KeywordDashboardService(
        client: MockClient(
          (_) async => http.Response('Internal Server Error', 500),
        ),
      );

      expect(
        () => service.fetchKeywordTrend(
          keywordId: 'test-keyword',
          startYear: 2011,
          endYear: 2026,
        ),
        throwsException,
      );
    });

    test('throws exception when trend API returns malformed JSON', () async {
      final service = KeywordDashboardService(
        client: MockClient((_) async => http.Response('{invalid json', 200)),
      );

      expect(
        () => service.fetchKeywordTrend(
          keywordId: 'test-keyword',
          startYear: 2011,
          endYear: 2026,
        ),
        throwsException,
      );
    });
  });
}
