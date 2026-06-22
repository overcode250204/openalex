import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/models/app/app_page.dart';
import 'package:openalex/models/topic/topic.dart';

void main() {
  group('AppPage enum', () {
    test('contains all expected navigation pages', () {
      const allValues = AppPage.values;

      expect(allValues, contains(AppPage.home));
      expect(allValues, contains(AppPage.searchTopic));
      expect(allValues, contains(AppPage.trends));
      expect(allValues, contains(AppPage.journals));
    });

    test('has exactly 4 values', () {
      expect(AppPage.values.length, 4);
    });

    test('supports equality comparison', () {
      const page = AppPage.journals;
      expect(page == AppPage.journals, isTrue);
      expect(page == AppPage.home, isFalse);
    });
  });

  group('TopicSuggestion', () {
    test('parses a full OpenAlex topic payload', () {
      final suggestion = TopicSuggestion.fromJson({
        'id': 'https://openalex.org/T10616',
        'display_name': 'Artificial Intelligence',
        'works_count': 9999,
      });

      expect(suggestion.id, 'https://openalex.org/T10616');
      expect(suggestion.displayName, 'Artificial Intelligence');
      expect(suggestion.workCount, 9999);
    });

    test('defaults works_count to zero when missing', () {
      final suggestion = TopicSuggestion.fromJson({
        'id': 'https://openalex.org/T1',
        'display_name': 'Topic',
      });

      expect(suggestion.workCount, 0);
    });

    test('defaults works_count to zero when null', () {
      final suggestion = TopicSuggestion.fromJson({
        'id': 'T1',
        'display_name': 'Topic',
        'works_count': null,
      });

      expect(suggestion.workCount, 0);
    });
  });
}
