import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/models/journal_suggestion.dart';

void main() {
  group('JournalSuggestion', () {
    test('fromJson parses correctly with all fields', () {
      final json = {
        'id': 'https://openalex.org/S12345',
        'display_name': 'Nature',
        'works_count': 1000,
        'issn_l': '0028-0836',
        'host_organization_name': 'Springer Nature',
      };

      final suggestion = JournalSuggestion.fromJson(json);

      expect(suggestion.id, 'https://openalex.org/S12345');
      expect(suggestion.shortId, 'S12345');
      expect(suggestion.displayName, 'Nature');
      expect(suggestion.worksCount, 1000);
      expect(suggestion.issnL, '0028-0836');
      expect(suggestion.publisher, 'Springer Nature');
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 'https://openalex.org/S67890',
        'display_name': 'Science',
        'works_count': 500,
      };

      final suggestion = JournalSuggestion.fromJson(json);

      expect(suggestion.id, 'https://openalex.org/S67890');
      expect(suggestion.shortId, 'S67890');
      expect(suggestion.displayName, 'Science');
      expect(suggestion.worksCount, 500);
      expect(suggestion.issnL, isNull);
      expect(suggestion.publisher, isNull);
    });

    test('fromJson defaults worksCount to 0 if missing', () {
      final json = {
        'id': 'https://openalex.org/S11111',
        'display_name': 'Unknown Journal',
      };

      final suggestion = JournalSuggestion.fromJson(json);

      expect(suggestion.worksCount, 0);
    });
  });
}
