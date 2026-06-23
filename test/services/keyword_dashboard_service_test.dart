import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openalex/services/keyword_dashboard_service.dart';

void main() {
  group('KeywordDashboardService Tests', () {
    test('successful dashboard response', () async {
      final service = KeywordDashboardService(
        minimumCurrentCount: 1,
        client: MockClient((request) async {
          final path = request.url.path;
          final query = request.url.queryParameters;
          final groupBy = query['group_by'];
          final filter = query['filter'] ?? '';

          if (path != '/works') {
            throw StateError('Unhandled request: ${request.url}');
          }

          // Current period: top keywords.
          if (groupBy == 'keywords.id') {
            return http.Response(
              jsonEncode({
                'meta': {'count': 18},
                'group_by': [
                  {
                    'key': 'https://openalex.org/keywords/k1',
                    'key_display_name': 'Keyword 1',
                    'count': 10,
                  },
                  {
                    'key': 'https://openalex.org/keywords/k2',
                    'key_display_name': 'Keyword 2',
                    'count': 8,
                  },
                ],
              }),
              200,
            );
          }

          // Previous-period count for Keyword 1.
          if (filter.contains('keywords.id:keywords/k1')) {
            return http.Response(
              jsonEncode({
                'meta': {'count': 5},
                'results': [
                  {'id': 'https://openalex.org/W1'},
                ],
              }),
              200,
            );
          }

          // Previous-period count for Keyword 2.
          if (filter.contains('keywords.id:keywords/k2')) {
            return http.Response(
              jsonEncode({
                'meta': {'count': 3},
                'results': [
                  {'id': 'https://openalex.org/W2'},
                ],
              }),
              200,
            );
          }

          throw StateError('Unhandled dashboard request: ${request.url}');
        }),
      );

      final result = await service.fetchKeywordDashboard();

      expect(result.mostFrequentKeywords, isNotEmpty);
      expect(result.trendingKeywords, isNotEmpty);

      expect(result.mostFrequentKeywords.first.name, 'Keyword 1');
      expect(result.mostFrequentKeywords.first.currentPeriodCount, 10);
      expect(result.mostFrequentKeywords.first.previousPeriodCount, 5);

      expect(result.trendingKeywords.first.name, 'Keyword 2');
      expect(result.trendingKeywords.first.currentPeriodCount, 8);
      expect(result.trendingKeywords.first.previousPeriodCount, 3);
    });

    test('successful empty response', () async {
      final service = KeywordDashboardService(
        minimumCurrentCount: 1,
        client: MockClient((request) async {
          return http.Response(
            jsonEncode({
              'meta': {'count': 0},
              'group_by': [],
            }),
            200,
          );
        }),
      );

      final result = await service.fetchKeywordDashboard();

      expect(result.mostFrequentKeywords, isEmpty);
      expect(result.trendingKeywords, isEmpty);
      expect(result.hottestKeyword, isNull);
    });

    test('malformed JSON response throws exception', () async {
      final service = KeywordDashboardService(
        client: MockClient((request) async {
          return http.Response('{bad json', 200);
        }),
      );

      expect(() => service.fetchKeywordDashboard(), throwsException);
    });

    test('HTTP 400 bad request throws exception', () async {
      final service = KeywordDashboardService(
        client: MockClient((request) async {
          return http.Response('Bad Request', 400);
        }),
      );

      expect(() => service.fetchKeywordDashboard(), throwsException);
    });

    test('HTTP 401 authentication failure throws exception', () async {
      final service = KeywordDashboardService(
        client: MockClient((request) async {
          return http.Response('Auth Error', 401);
        }),
      );

      expect(() => service.fetchKeywordDashboard(), throwsException);
    });

    test('HTTP 403 authorization failure throws exception', () async {
      final service = KeywordDashboardService(
        client: MockClient((request) async {
          return http.Response('Forbidden', 403);
        }),
      );

      expect(() => service.fetchKeywordDashboard(), throwsException);
    });

    test('HTTP 429 rate limit throws exception', () async {
      final service = KeywordDashboardService(
        client: MockClient((request) async {
          return http.Response('Rate Limit', 429);
        }),
      );

      expect(() => service.fetchKeywordDashboard(), throwsException);
    });

    test('HTTP 500 server failure throws exception', () async {
      final service = KeywordDashboardService(
        client: MockClient((request) async {
          return http.Response('Server Error', 500);
        }),
      );

      expect(() => service.fetchKeywordDashboard(), throwsException);
    });

    test('SocketException network failure throws exception', () async {
      final service = KeywordDashboardService(
        client: MockClient((request) async {
          throw const SocketException('Network error');
        }),
      );

      expect(() => service.fetchKeywordDashboard(), throwsException);
    });

    test('keyword ranking sorts by current period count descending', () async {
      final service = KeywordDashboardService(
        minimumCurrentCount: 1,
        client: MockClient((request) async {
          final path = request.url.path;
          final query = request.url.queryParameters;
          final groupBy = query['group_by'];
          final filter = query['filter'] ?? '';

          if (path != '/works') {
            return http.Response('Not found', 404);
          }

          // Initial keyword ranking for current period.
          if (groupBy == 'keywords.id') {
            return http.Response(
              jsonEncode({
                'meta': {'count': 60},
                'group_by': [
                  {
                    'key': 'https://openalex.org/keywords/k1',
                    'key_display_name': 'Low',
                    'count': 10,
                  },
                  {
                    'key': 'https://openalex.org/keywords/k2',
                    'key_display_name': 'High',
                    'count': 50,
                  },
                ],
              }),
              200,
            );
          }

          // Previous-period count.
          if (filter.contains('keywords.id:keywords/k1')) {
            return http.Response(
              jsonEncode({
                'meta': {'count': 5},
                'results': [],
              }),
              200,
            );
          }

          if (filter.contains('keywords.id:keywords/k2')) {
            return http.Response(
              jsonEncode({
                'meta': {'count': 10},
                'results': [],
              }),
              200,
            );
          }

          return http.Response(
            jsonEncode({
              'meta': {'count': 0},
              'results': [],
            }),
            200,
          );
        }),
      );

      final result = await service.fetchKeywordDashboard();

      expect(result.mostFrequentKeywords, isNotEmpty);
      expect(result.mostFrequentKeywords.length, 2);

      expect(result.mostFrequentKeywords.first.name, 'High');
      expect(result.mostFrequentKeywords.first.currentPeriodCount, 50);

      expect(result.mostFrequentKeywords.last.name, 'Low');
      expect(result.mostFrequentKeywords.last.currentPeriodCount, 10);
    });

    test('keyword trending sorts by growth rate descending', () async {
      final service = KeywordDashboardService(
        minimumCurrentCount: 1,
        client: MockClient((request) async {
          final path = request.url.path;
          final query = request.url.queryParameters;
          final groupBy = query['group_by'];
          final filter = query['filter'] ?? '';

          if (path != '/works') {
            return http.Response('Not found', 404);
          }

          // Current-period counts.
          if (groupBy == 'keywords.id') {
            return http.Response(
              jsonEncode({
                'meta': {'count': 60},
                'group_by': [
                  {
                    'key': 'https://openalex.org/keywords/k1',
                    'key_display_name': 'Stable Keyword',
                    'count': 30,
                  },
                  {
                    'key': 'https://openalex.org/keywords/k2',
                    'key_display_name': 'Fast Growth Keyword',
                    'count': 30,
                  },
                ],
              }),
              200,
            );
          }

          // k1: 30 now vs 25 previous => growth 20%.
          if (filter.contains('keywords.id:keywords/k1')) {
            return http.Response(
              jsonEncode({
                'meta': {'count': 25},
                'results': [],
              }),
              200,
            );
          }

          // k2: 30 now vs 5 previous => growth 500%.
          if (filter.contains('keywords.id:keywords/k2')) {
            return http.Response(
              jsonEncode({
                'meta': {'count': 5},
                'results': [],
              }),
              200,
            );
          }

          return http.Response(
            jsonEncode({
              'meta': {'count': 0},
              'results': [],
            }),
            200,
          );
        }),
      );

      final result = await service.fetchKeywordDashboard();

      expect(result.trendingKeywords, isNotEmpty);
      expect(result.trendingKeywords.length, 2);

      expect(result.trendingKeywords.first.name, 'Fast Growth Keyword');
      expect(result.trendingKeywords.first.currentPeriodCount, 30);
      expect(result.trendingKeywords.first.previousPeriodCount, 5);
      expect(result.trendingKeywords.first.growthRate, 500);

      expect(result.trendingKeywords.last.name, 'Stable Keyword');
      expect(result.trendingKeywords.last.growthRate, 20);
    });

    test('keyword below minimum current count is excluded', () async {
      final service = KeywordDashboardService(
        minimumCurrentCount: 20,
        client: MockClient((request) async {
          final path = request.url.path;
          final query = request.url.queryParameters;
          final groupBy = query['group_by'];
          final filter = query['filter'] ?? '';

          if (path != '/works') {
            return http.Response('Not found', 404);
          }

          if (groupBy == 'keywords.id') {
            return http.Response(
              jsonEncode({
                'meta': {'count': 29},
                'group_by': [
                  {
                    'key': 'https://openalex.org/keywords/k1',
                    'key_display_name': 'Below Threshold',
                    'count': 19,
                  },
                  {
                    'key': 'https://openalex.org/keywords/k2',
                    'key_display_name': 'Eligible Keyword',
                    'count': 20,
                  },
                ],
              }),
              200,
            );
          }

          if (filter.contains('keywords.id:keywords/k1')) {
            return http.Response(
              jsonEncode({
                'meta': {'count': 5},
                'results': [],
              }),
              200,
            );
          }

          if (filter.contains('keywords.id:keywords/k2')) {
            return http.Response(
              jsonEncode({
                'meta': {'count': 10},
                'results': [],
              }),
              200,
            );
          }

          return http.Response(
            jsonEncode({
              'meta': {'count': 0},
              'results': [],
            }),
            200,
          );
        }),
      );

      final result = await service.fetchKeywordDashboard();

      expect(result.mostFrequentKeywords.length, 1);
      expect(result.mostFrequentKeywords.first.name, 'Eligible Keyword');
      expect(result.mostFrequentKeywords.first.currentPeriodCount, 20);

      expect(
        result.mostFrequentKeywords.any(
          (keyword) => keyword.name == 'Below Threshold',
        ),
        isFalse,
      );
    });

    test('calculateGrowthRate handles zero previous count', () {
      expect(KeywordDashboardService.calculateGrowthRate(10, 0), 1000);
    });

    test('calculateGrowthRate calculates percentage correctly', () {
      expect(KeywordDashboardService.calculateGrowthRate(15, 10), 50);

      expect(KeywordDashboardService.calculateGrowthRate(5, 10), -50);
    });

    test('calculateHotScore returns zero when maximum count is zero', () {
      final score = KeywordDashboardService.calculateHotScore(
        currentPeriodCount: 0,
        maxCurrentPeriodCount: 0,
        growthRate: 100,
      );

      expect(score, 0);
    });

    test('normalizeTrend fills missing years with zero values', () {
      final points = KeywordDashboardService.normalizeTrend([], 2024, 2026);

      expect(points.length, 3);
      expect(points[0].year, 2024);
      expect(points[0].count, 0);
      expect(points[1].year, 2025);
      expect(points[1].count, 0);
      expect(points[2].year, 2026);
      expect(points[2].count, 0);
    });
  });
}
