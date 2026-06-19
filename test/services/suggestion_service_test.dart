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
}
