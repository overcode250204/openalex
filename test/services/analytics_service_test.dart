import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:openalex/models/search/search_filter.dart';
import 'package:openalex/services/analytics/analytics_service.dart';

class MockClient extends Mock implements http.Client {}

void main() {
  late MockClient client;
  late AnalyticsService service;
  late List<Uri> requestedUris;

  setUpAll(() {
    registerFallbackValue(Uri.parse('https://api.openalex.org/works'));
  });

  setUp(() {
    client = MockClient();
    service = AnalyticsService(client: client);
    requestedUris = [];

    when(() => client.get(any())).thenAnswer((invocation) async {
      final uri = invocation.positionalArguments.first as Uri;
      requestedUris.add(uri);
      final groupBy = uri.queryParameters['group_by'];
      if (groupBy != null) {
        final groups = switch (groupBy) {
          'publication_year' => [
            {'key': '2022', 'key_display_name': '2022', 'count': 4},
            {'key': '2024', 'key_display_name': '2024', 'count': 4},
          ],
          'authorships.author.id' => [
            {'key': 'A1', 'key_display_name': 'Ada Lovelace', 'count': 3},
          ],
          'primary_location.source.id' => [
            {'key': 'S1', 'key_display_name': 'Journal One', 'count': 2},
          ],
          'cited_by_count' => [
            {'key': '20', 'key_display_name': '20', 'count': 1},
            {'key': '10', 'key_display_name': '10', 'count': 1},
            {'key': '0', 'key_display_name': '0', 'count': 1},
          ],
          _ => <Map<String, Object>>[],
        };
        return http.Response(
          jsonEncode({
            'meta': {'next_cursor': null},
            'group_by': groups,
          }),
          200,
        );
      }

      return http.Response(
        jsonEncode({
          'meta': {'count': 3},
          'results': [
            {
              'id': 'https://openalex.org/W1',
              'doi': 'https://doi.org/10.1/top',
              'display_name': 'Most Influential',
              'publication_year': 2024,
              'cited_by_count': 20,
            },
          ],
        }),
        200,
      );
    });
  });

  test(
    'calculates all summary metrics from the selected topic dataset',
    () async {
      final result = await service.fetchSummary(
        'Artificial Intelligence',
        const SearchFilter(yearFrom: 2020, yearTo: 2024),
        topicId: 'https://openalex.org/T1',
      );

      expect(result.totalWorks, 3);
      expect(result.analyzedWorks, 3);
      expect(result.totalCitations, 30);
      expect(result.averageCitations, 10);
      expect(result.publicationTrend, {2022: 4, 2024: 4});
      expect(result.topAuthors, {'Ada Lovelace': 3});
      expect(result.topJournals, {'Journal One': 2});
      expect(result.mostInfluentialPaper?.title, 'Most Influential');
      expect(result.mostInfluentialPaper?.citedByCount, 20);
      expect(result.mostInfluentialPaper?.publicationYear, 2024);
      expect(result.mostInfluentialPaper?.id, 'https://openalex.org/W1');
      expect(result.mostInfluentialPaper?.doi, 'https://doi.org/10.1/top');

      for (final uri in requestedUris) {
        expect(uri.queryParameters.containsKey('search'), isFalse);
        expect(uri.queryParameters['filter'], contains('primary_topic.id:T1'));
        expect(
          uri.queryParameters['filter'],
          contains('publication_year:2020-2024'),
        );
      }
    },
  );

  test('returns safe empty metrics for an empty dataset', () async {
    when(() => client.get(any())).thenAnswer((invocation) async {
      final uri = invocation.positionalArguments.first as Uri;
      final groupBy = uri.queryParameters['group_by'];
      if (groupBy != null) {
        return http.Response(
          jsonEncode({
            'meta': {'next_cursor': null},
            'group_by': [],
          }),
          200,
        );
      }
      return http.Response(
        jsonEncode({
          'meta': {'count': 0, 'next_cursor': null},
          'results': [],
        }),
        200,
      );
    });

    final result = await service.fetchSummary('Empty', const SearchFilter());

    expect(result.totalWorks, 0);
    expect(result.averageCitations, isNull);
    expect(result.publicationTrend, isEmpty);
    expect(result.topAuthors, isEmpty);
    expect(result.topJournals, isEmpty);
    expect(result.mostInfluentialPaper, isNull);
  });

  test('handles missing author, journal, year, and citation fields', () async {
    when(() => client.get(any())).thenAnswer((invocation) async {
      final uri = invocation.positionalArguments.first as Uri;
      final groupBy = uri.queryParameters['group_by'];
      if (groupBy != null) {
        return http.Response(
          jsonEncode({
            'meta': {'next_cursor': null},
            'group_by': groupBy == 'cited_by_count'
                ? [
                    {'key': '0', 'key_display_name': '0', 'count': 1},
                  ]
                : [],
          }),
          200,
        );
      }
      return http.Response(
        jsonEncode({
          'meta': {'count': 1, 'next_cursor': null},
          'results': [
            {
              'id': 'https://openalex.org/W1',
              'display_name': 'Incomplete Work',
              'publication_year': null,
              'cited_by_count': null,
            },
          ],
        }),
        200,
      );
    });

    final result = await service.fetchSummary(
      'Incomplete',
      const SearchFilter(),
    );

    expect(result.totalWorks, 1);
    expect(result.averageCitations, 0);
    expect(result.publicationTrend, isEmpty);
    expect(result.topAuthors, isEmpty);
    expect(result.topJournals, isEmpty);
    expect(result.mostInfluentialPaper?.publicationYear, isNull);
    expect(result.mostInfluentialPaper?.citedByCount, 0);
  });

  test('keeps available summary metrics when one request fails', () async {
    when(() => client.get(any())).thenAnswer((invocation) async {
      final uri = invocation.positionalArguments.first as Uri;
      final groupBy = uri.queryParameters['group_by'];
      if (groupBy == 'authorships.author.id') {
        return http.Response('Error', 500);
      }
      if (groupBy != null) {
        return http.Response(
          jsonEncode({
            'meta': {'next_cursor': null},
            'group_by': groupBy == 'publication_year'
                ? [
                    {'key': '2024', 'key_display_name': '2024', 'count': 2},
                  ]
                : [],
          }),
          200,
        );
      }
      return http.Response(
        jsonEncode({
          'meta': {'count': 2},
          'results': [
            {'id': 'W1', 'display_name': 'Top Work', 'cited_by_count': 5},
          ],
        }),
        200,
      );
    });

    final result = await service.fetchSummary(
      'AI',
      const SearchFilter(yearFrom: 2024, yearTo: 2024),
    );

    expect(result.totalWorks, 2);
    expect(result.publicationTrend, {2024: 2});
    expect(result.topAuthors, isEmpty);
    expect(result.mostInfluentialPaper?.title, 'Top Work');
  });

  test('adds an OpenAlex API key when configured', () async {
    final keyedClient = MockClient();
    final keyedService = AnalyticsService(
      client: keyedClient,
      apiKey: 'test-key',
    );
    final uris = <Uri>[];
    when(() => keyedClient.get(any())).thenAnswer((invocation) async {
      final uri = invocation.positionalArguments.first as Uri;
      uris.add(uri);
      if (uri.queryParameters.containsKey('group_by')) {
        return http.Response(
          jsonEncode({
            'meta': {'next_cursor': null},
            'group_by': [],
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
    });

    await keyedService.fetchSummary('AI', const SearchFilter());

    expect(uris, isNotEmpty);
    expect(
      uris.every((uri) => uri.queryParameters['api_key'] == 'test-key'),
      isTrue,
    );
  });

  test('throws on a non-success OpenAlex response', () async {
    when(
      () => client.get(any()),
    ).thenAnswer((_) async => http.Response('Error', 500));

    await expectLater(
      service.fetchAll('test', const SearchFilter()),
      throwsException,
    );
  });

  test('throws when the client fails', () async {
    when(() => client.get(any())).thenThrow(Exception('Network Error'));

    await expectLater(
      service.fetchAll('test', const SearchFilter()),
      throwsException,
    );
  });
}
