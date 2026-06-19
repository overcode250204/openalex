import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openalex/services/suggestion_service.dart';

void main() {
  group('SuggestionService keyword suggestions', () {
    test('returns empty for short query without calling HTTP', () async {
      var called = false;
      final service = SuggestionService(
        client: MockClient((request) async {
          called = true;
          return http.Response('{}', 200);
        }),
      );

      final result = await service.fetchKeywordSuggestions('a');

      expect(result, isEmpty);
      expect(called, isFalse);
    });

    test('calls OpenAlex keywords endpoint and parses display names', () async {
      Uri? requestedUri;
      final service = SuggestionService(
        client: MockClient((request) async {
          requestedUri = request.url;
          return http.Response(
            jsonEncode({
              'results': [
                {'display_name': 'Machine learning'},
                {'display_name': ''},
                {'display_name': 'Artificial intelligence'},
              ],
            }),
            200,
          );
        }),
      );

      final result = await service.fetchKeywordSuggestions(' machine ');

      expect(requestedUri?.path, '/keywords');
      expect(requestedUri?.queryParameters['search'], 'machine');
      expect(requestedUri?.queryParameters['per_page'], '6');
      expect(
        requestedUri?.queryParameters['select'],
        'id,display_name,works_count',
      );
      expect(
        requestedUri?.queryParameters['mailto'],
        'truongtuan20042004@gmail.com',
      );
      expect(result, ['Machine learning', 'Artificial intelligence']);
    });

    test('returns empty for non-200 and errors', () async {
      final errorStatusService = SuggestionService(
        client: MockClient((request) async => http.Response('nope', 500)),
      );
      final throwingService = SuggestionService(
        client: MockClient((request) async => throw Exception('boom')),
      );

      expect(
        await errorStatusService.fetchKeywordSuggestions('machine'),
        isEmpty,
      );
      expect(await throwingService.fetchKeywordSuggestions('machine'), isEmpty);
    });
  });

  group('SuggestionService topic suggestions', () {
    test('returns empty for short query without calling HTTP', () async {
      var called = false;
      final service = SuggestionService(
        client: MockClient((request) async {
          called = true;
          return http.Response('{}', 200);
        }),
      );

      final result = await service.fetchTopicSuggestions('a');

      expect(result, isEmpty);
      expect(called, isFalse);
    });

    test('calls OpenAlex topics endpoint and parses results', () async {
      Uri? requestedUri;
      final service = SuggestionService(
        client: MockClient((request) async {
          requestedUri = request.url;
          return http.Response(
            jsonEncode({
              'results': [
                {'id': 'T123', 'display_name': 'Topic 1', 'works_count': 100},
                {'id': 'T456', 'display_name': 'Topic 2', 'works_count': 200},
              ],
            }),
            200,
          );
        }),
      );

      final result = await service.fetchTopicSuggestions('topic');

      expect(requestedUri?.path, '/topics');
      expect(requestedUri?.queryParameters['search'], 'topic');
      expect(result.length, 2);
      expect(result[0].displayName, 'Topic 1');
      expect(result[1].worksCount, 200);
    });

    test('returns empty on error', () async {
      final service = SuggestionService(
        client: MockClient((request) async => http.Response('Error', 500)),
      );
      expect(await service.fetchTopicSuggestions('topic'), isEmpty);
    });
  });

  group('SuggestionService journal suggestions', () {
    test('returns empty for short query without calling HTTP', () async {
      var called = false;
      final service = SuggestionService(
        client: MockClient((request) async {
          called = true;
          return http.Response('{}', 200);
        }),
      );

      final result = await service.fetchJournalSuggestions('a');

      expect(result, isEmpty);
      expect(called, isFalse);
    });

    test('calls OpenAlex sources endpoint and parses results', () async {
      Uri? requestedUri;
      final service = SuggestionService(
        client: MockClient((request) async {
          requestedUri = request.url;
          return http.Response(
            jsonEncode({
              'results': [
                {
                  'id': 'S123',
                  'display_name': 'Nature',
                  'works_count': 100,
                  'issn_l': '1234',
                  'host_organization_name': 'Publisher'
                },
              ],
            }),
            200,
          );
        }),
      );

      final result = await service.fetchJournalSuggestions('nature');

      expect(requestedUri?.path, '/sources');
      expect(requestedUri?.queryParameters['search'], 'nature');
      expect(requestedUri?.queryParameters['filter'], 'type:journal');
      expect(result.length, 1);
      expect(result[0].displayName, 'Nature');
    });

    test('returns empty on error', () async {
      final service = SuggestionService(
        client: MockClient((request) async => http.Response('Error', 500)),
      );
      expect(await service.fetchJournalSuggestions('nature'), isEmpty);
    });
  });

  group('SuggestionService related keywords', () {
    test('fetches works and extracts top concepts over threshold', () async {
      Uri? requestedUri;
      final service = SuggestionService(
        client: MockClient((request) async {
          requestedUri = request.url;
          return http.Response(
            jsonEncode({
              'results': [
                {
                  'concepts': [
                    {'display_name': 'AI', 'score': 0.8},
                    {'display_name': 'Machine Learning', 'score': 0.9}, // match
                    {'display_name': 'Deep Learning', 'score': 0.4},
                  ]
                },
                {
                  'concepts': [
                    {'display_name': 'Deep Learning', 'score': 0.5},
                    {'display_name': 'AI', 'score': 0.2}, // Below threshold 0.3
                    {'display_name': 'Data Science', 'score': 0.6},
                  ]
                }
              ],
            }),
            200,
          );
        }),
      );

      final result = await service.fetchRelatedKeywords('Machine Learning');

      expect(requestedUri?.path, '/works');
      expect(requestedUri?.queryParameters['search'], 'Machine Learning');
      expect(requestedUri?.queryParameters['select'], 'concepts');
      
      // AI appears once >0.3, Deep Learning appears twice >0.3, Data Science once >0.3
      // Sort should prioritize count (Deep Learning = 2, AI = 1, Data Science = 1)
      expect(result.first, 'Deep Learning');
      expect(result.length, 3);
      expect(result.contains('AI'), isTrue);
      expect(result.contains('Data Science'), isTrue);
      expect(result.contains('Machine Learning'), isFalse); // filters out self
    });

    test('returns empty on error', () async {
      final service = SuggestionService(
        client: MockClient((request) async => http.Response('Error', 500)),
      );
      expect(await service.fetchRelatedKeywords('keyword'), isEmpty);
    });
  });
}
