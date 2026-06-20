import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/models/keyword/keyword_analysis_paper.dart';
import 'package:openalex/models/keyword/keyword_analysis_result.dart';
import 'package:openalex/models/keyword/keyword_trend_point.dart';
import 'package:openalex/models/keyword/openalex_keyword.dart';
import 'package:openalex/widgets/keyword/keyword_analysis_summary.dart';

void main() {
  testWidgets(
    'KeywordAnalysisSummary labels top OA shown and formats numbers',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KeywordAnalysisSummary(
              result: KeywordAnalysisResult(
                keyword: 'AI',
                resolvedKeyword: const OpenAlexKeyword(
                  id: 'C123',
                  displayName: 'Artificial intelligence',
                  worksCount: 12911371,
                  citedByCount: 199170687,
                ),
                trend: const [KeywordTrendPoint(year: 2024, count: 221700)],
                relevantPapers: const [],
                mostCitedPapers: const [
                  KeywordAnalysisPaper(
                    id: 'W1',
                    title: 'Most Cited',
                    publicationYear: 2024,
                    publicationDate: '2024-01-01',
                    sourceName: 'Journal',
                    doi: null,
                    landingPageUrl: null,
                    pdfUrl: null,
                    citedByCount: 221700,
                    isOpenAccess: false,
                  ),
                ],
                latestPapers: const [],
                openAccessPapers: const [
                  KeywordAnalysisPaper(
                    id: 'W2',
                    title: 'OA',
                    publicationYear: 2024,
                    publicationDate: '2024-01-01',
                    sourceName: 'Journal',
                    doi: null,
                    landingPageUrl: null,
                    pdfUrl: null,
                    citedByCount: 3,
                    isOpenAccess: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Top OA Papers Shown'), findsOneWidget);
      expect(find.text('12,911,371'), findsOneWidget);
      expect(find.text('221,700'), findsWidgets);
    },
  );
}
