import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/models/keyword/keyword_analysis_paper.dart';
import 'package:openalex/models/keyword/keyword_analysis_result.dart';
import 'package:openalex/models/keyword/keyword_trend_point.dart';
import 'package:openalex/models/keyword/openalex_keyword.dart';

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

KeywordAnalysisPaper _paper({
  String id = 'W1',
  String title = 'Test Paper',
  int citations = 10,
  bool isOa = false,
}) {
  return KeywordAnalysisPaper(
    id: id,
    title: title,
    publicationYear: 2024,
    publicationDate: '2024-01-01',
    sourceName: 'Journal',
    doi: null,
    landingPageUrl: null,
    pdfUrl: null,
    citedByCount: citations,
    isOpenAccess: isOa,
  );
}

KeywordAnalysisResult _emptyResult() {
  return const KeywordAnalysisResult(
    keyword: 'AI',
    trend: [],
    relevantPapers: [],
    mostCitedPapers: [],
    latestPapers: [],
    openAccessPapers: [],
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('KeywordAnalysisResult.isEmpty', () {
    test('returns true when all lists are empty', () {
      expect(_emptyResult().isEmpty, isTrue);
    });

    test('returns false when trend has data', () {
      final result = KeywordAnalysisResult(
        keyword: 'AI',
        trend: const [KeywordTrendPoint(year: 2024, count: 5)],
        relevantPapers: const [],
        mostCitedPapers: const [],
        latestPapers: const [],
        openAccessPapers: const [],
      );
      expect(result.isEmpty, isFalse);
    });

    test('returns false when any paper list has data', () {
      final result = KeywordAnalysisResult(
        keyword: 'AI',
        trend: const [],
        relevantPapers: [_paper()],
        mostCitedPapers: const [],
        latestPapers: const [],
        openAccessPapers: const [],
      );
      expect(result.isEmpty, isFalse);
    });
  });

  group('KeywordAnalysisResult.totalPublications', () {
    test('uses resolvedKeyword.worksCount when available', () {
      final result = KeywordAnalysisResult(
        keyword: 'AI',
        resolvedKeyword: const OpenAlexKeyword(
          id: 'C1',
          displayName: 'AI',
          worksCount: 5000,
          citedByCount: 999,
        ),
        trend: const [KeywordTrendPoint(year: 2024, count: 1)],
        relevantPapers: const [],
        mostCitedPapers: const [],
        latestPapers: const [],
        openAccessPapers: const [],
      );

      expect(result.totalPublications, 5000);
    });

    test('sums trend counts when resolvedKeyword is null', () {
      final result = KeywordAnalysisResult(
        keyword: 'AI',
        trend: const [
          KeywordTrendPoint(year: 2022, count: 10),
          KeywordTrendPoint(year: 2023, count: 20),
          KeywordTrendPoint(year: 2024, count: 30),
        ],
        relevantPapers: const [],
        mostCitedPapers: const [],
        latestPapers: const [],
        openAccessPapers: const [],
      );

      expect(result.totalPublications, 60);
    });

    test('returns zero for empty trend and no resolvedKeyword', () {
      expect(_emptyResult().totalPublications, 0);
    });
  });

  group('KeywordAnalysisResult.peakYear', () {
    test('returns null when trend is empty', () {
      expect(_emptyResult().peakYear, isNull);
    });

    test('returns the point with the highest count', () {
      final result = KeywordAnalysisResult(
        keyword: 'AI',
        trend: const [
          KeywordTrendPoint(year: 2022, count: 5),
          KeywordTrendPoint(year: 2023, count: 99),
          KeywordTrendPoint(year: 2024, count: 50),
        ],
        relevantPapers: const [],
        mostCitedPapers: const [],
        latestPapers: const [],
        openAccessPapers: const [],
      );

      expect(result.peakYear?.year, 2023);
      expect(result.peakYear?.count, 99);
    });

    test('returns first when multiple points share the max count', () {
      final result = KeywordAnalysisResult(
        keyword: 'AI',
        trend: const [
          KeywordTrendPoint(year: 2022, count: 50),
          KeywordTrendPoint(year: 2023, count: 50),
        ],
        relevantPapers: const [],
        mostCitedPapers: const [],
        latestPapers: const [],
        openAccessPapers: const [],
      );

      // reduce picks the first equal element (a.count >= b.count → keeps a)
      expect(result.peakYear?.year, 2022);
    });
  });

  group('KeywordAnalysisResult.mostCitedPaper', () {
    test('returns null when mostCitedPapers is empty', () {
      expect(_emptyResult().mostCitedPaper, isNull);
    });

    test('returns the paper with the highest citedByCount', () {
      final result = KeywordAnalysisResult(
        keyword: 'AI',
        trend: const [],
        relevantPapers: const [],
        mostCitedPapers: [
          _paper(id: 'W1', citations: 10),
          _paper(id: 'W2', citations: 500),
          _paper(id: 'W3', citations: 200),
        ],
        latestPapers: const [],
        openAccessPapers: const [],
      );

      expect(result.mostCitedPaper?.id, 'W2');
      expect(result.mostCitedPaper?.citedByCount, 500);
    });

    test('returns single paper when list has one element', () {
      final result = KeywordAnalysisResult(
        keyword: 'AI',
        trend: const [],
        relevantPapers: const [],
        mostCitedPapers: [_paper(id: 'W1', citations: 7)],
        latestPapers: const [],
        openAccessPapers: const [],
      );

      expect(result.mostCitedPaper?.id, 'W1');
    });
  });

  group('KeywordAnalysisResult default optional fields', () {
    test('topAuthors and topSources default to empty maps', () {
      final result = _emptyResult();
      expect(result.topAuthors, isEmpty);
      expect(result.topSources, isEmpty);
    });

    test('resolvedKeyword defaults to null', () {
      expect(_emptyResult().resolvedKeyword, isNull);
    });
  });
}
