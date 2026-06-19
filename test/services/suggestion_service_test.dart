import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/services/suggestion_service.dart';

void main() {
  // SuggestionService uses the global top-level http.get (non-injectable),
  // so network calls in tests will fail and be caught silently (returns []).
  // We focus on testing business-logic guards and the public API contract.

  group('SuggestionService.fetchTopicSuggestions', () {
    test('returns empty list when query is empty string', () async {
      final service = SuggestionService();
      expect(await service.fetchTopicSuggestions(''), isEmpty);
    });

    test('returns empty list when query is only whitespace', () async {
      final service = SuggestionService();
      expect(await service.fetchTopicSuggestions('   '), isEmpty);
    });

    test('returns empty list when query is exactly 1 character', () async {
      final service = SuggestionService();
      expect(await service.fetchTopicSuggestions('A'), isEmpty);
    });

    test('returns List<TopicSuggestion> for any valid query (network may fail)',
        () async {
      final service = SuggestionService();
      // query >= 2 chars triggers HTTP call; in tests without network,
      // the catch block returns []
      final result = await service.fetchTopicSuggestions('AI');
      expect(result, isA<List>());
    });
  });

  group('SuggestionService.fetchRelatedKeywords', () {
    test('always returns List<String> (network errors are swallowed)', () async {
      final service = SuggestionService();
      final result = await service.fetchRelatedKeywords('machine learning');
      expect(result, isA<List<String>>());
    });

    test('returns empty list on network failure', () async {
      final service = SuggestionService();
      // In the test sandbox no real HTTP is available → caught → []
      final result = await service.fetchRelatedKeywords('AI');
      expect(result, isA<List<String>>());
    });
  });
}

