import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/models/keyword/keyword_analysis_paper.dart';

void main() {
  group('KeywordAnalysisPaper', () {
    test('parses full OpenAlex work JSON', () {
      final paper = KeywordAnalysisPaper.fromJson({
        'id': 'https://openalex.org/W1',
        'display_name': 'Machine Learning Paper',
        'publication_year': 2024,
        'publication_date': '2024-05-10',
        'cited_by_count': 42,
        'doi': 'https://doi.org/10.1000/ml',
        'primary_location': {
          'landing_page_url': 'https://example.com/paper',
          'pdf_url': 'https://example.com/primary.pdf',
          'source': {'display_name': 'Journal of AI'},
        },
        'best_oa_location': {'pdf_url': 'https://example.com/best.pdf'},
        'open_access': {'is_oa': true},
      });

      expect(paper.id, 'https://openalex.org/W1');
      expect(paper.title, 'Machine Learning Paper');
      expect(paper.publicationYear, 2024);
      expect(paper.publicationDate, '2024-05-10');
      expect(paper.sourceName, 'Journal of AI');
      expect(paper.doi, 'https://doi.org/10.1000/ml');
      expect(paper.landingPageUrl, 'https://example.com/paper');
      expect(paper.pdfUrl, 'https://example.com/best.pdf');
      expect(paper.citedByCount, 42);
      expect(paper.isOpenAccess, isTrue);
    });

    test('parses missing source, null DOI, null citations safely', () {
      final paper = KeywordAnalysisPaper.fromJson({
        'id': 'W2',
        'display_name': 'Sparse Paper',
        'publication_year': null,
        'cited_by_count': null,
        'doi': null,
        'open_access': {'is_oa': false},
      });

      expect(paper.sourceName, isNull);
      expect(paper.displaySource, 'Unknown source');
      expect(paper.doi, isNull);
      expect(paper.citedByCount, 0);
      expect(paper.isOpenAccess, isFalse);
    });

    test('falls back to root is_oa flag', () {
      final paper = KeywordAnalysisPaper.fromJson({
        'id': 'W3',
        'display_name': 'OA Paper',
        'is_oa': true,
      });

      expect(paper.isOpenAccess, isTrue);
    });
  });
}
