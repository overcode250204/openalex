import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/models/keyword/openalex_keyword.dart';

void main() {
  group('OpenAlexKeyword', () {
    test('parses a complete OpenAlex keyword JSON payload', () {
      final keyword = OpenAlexKeyword.fromJson({
        'id': 'https://openalex.org/keywords/artificial-intelligence',
        'display_name': 'Artificial intelligence',
        'works_count': 12911371,
        'cited_by_count': 199170687,
      });

      expect(
        keyword.id,
        'https://openalex.org/keywords/artificial-intelligence',
      );
      expect(keyword.displayName, 'Artificial intelligence');
      expect(keyword.worksCount, 12911371);
      expect(keyword.citedByCount, 199170687);
    });

    test('applies default fallbacks for null/missing fields', () {
      final keyword = OpenAlexKeyword.fromJson({});

      expect(keyword.id, '');
      expect(keyword.displayName, 'Unknown keyword');
      expect(keyword.worksCount, 0);
      expect(keyword.citedByCount, 0);
    });

    test('treats non-int works_count and cited_by_count as zero', () {
      final keyword = OpenAlexKeyword.fromJson({
        'id': 'K1',
        'display_name': 'ML',
        'works_count': 'many',
        'cited_by_count': null,
      });

      expect(keyword.worksCount, 0);
      expect(keyword.citedByCount, 0);
    });

    test('accepts zero counts as valid values', () {
      final keyword = OpenAlexKeyword.fromJson({
        'id': 'K2',
        'display_name': 'New Keyword',
        'works_count': 0,
        'cited_by_count': 0,
      });

      expect(keyword.worksCount, 0);
      expect(keyword.citedByCount, 0);
    });
  });
}
