import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/models/publication/publication.dart';
import 'package:openalex/models/trend/trend_report_snapshot.dart';
import 'package:openalex/services/pdf_report_layout_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PdfReportLayoutService', () {
    test('builds a deterministic dashboard PDF layout result', () async {
      const service = PdfReportLayoutService();

      final result = await service.buildDashboardReport(
        _sampleReport(),
        generatedAt: DateTime(2026, 6, 25, 9, 30, 45),
      );

      final pdfText = latin1.decode(result.bytes, allowInvalid: true);

      expect(result.bytes.take(5), equals('%PDF-'.codeUnits));
      expect(
        result.fileName,
        equals('trend-report-artificial-intelligence-20260625-093045.pdf'),
      );
      expect(result.generatedAt, DateTime(2026, 6, 25, 9, 30, 45));
      expect(pdfText, contains('/ToUnicode'));
      expect(pdfText, contains('/FontFile2'));
    });

    test('renders empty states without throwing', () async {
      const service = PdfReportLayoutService();

      final result = await service.buildDashboardReport(
        const TrendReportSnapshot(
          topic: '',
          publications: [],
          publicationCountByYear: {},
          topInfluentialPapers: [],
          topJournals: {},
          topAuthors: {},
          totalPublications: 0,
          averageCitationCount: 0,
          mostActiveYear: null,
          topJournal: null,
          topAuthor: null,
          mostInfluentialPaper: null,
        ),
        generatedAt: DateTime(2026, 6, 25),
      );

      final pdfText = latin1.decode(result.bytes, allowInvalid: true);

      expect(result.bytes.length, greaterThan(1000));
      expect(result.fileName, equals('trend-report-topic-20260625-000000.pdf'));
      expect(pdfText, contains('/ToUnicode'));
      expect(pdfText, contains('/FontFile2'));
    });

    test(
      'embeds Unicode glyph mappings for smart quotes and accents',
      () async {
        const service = PdfReportLayoutService();
        final publication = _publication(
          title: 'Opinion Paper: “So what if ChatGPT wrote it?”',
          citations: 10,
          year: 2024,
          journal: 'Journal of AI',
          authors: const ['Siobhán O’Connor'],
        );

        final result = await service.buildDashboardReport(
          TrendReportSnapshot(
            topic: 'Artificial Intelligence',
            publications: [publication],
            publicationCountByYear: const {2024: 1},
            topInfluentialPapers: [publication],
            topJournals: const {'Journal of AI': 1},
            topAuthors: const {'Siobhán O’Connor': 1},
            totalPublications: 1,
            averageCitationCount: 10,
            mostActiveYear: 2024,
            topJournal: 'Journal of AI',
            topAuthor: 'Siobhán O’Connor',
            mostInfluentialPaper: publication,
          ),
          generatedAt: DateTime(2026, 6, 25),
        );

        final pdfText = latin1.decode(result.bytes, allowInvalid: true);

        expect(pdfText, contains('<201C>'));
        expect(pdfText, contains('<201D>'));
        expect(pdfText, contains('<00E1>'));
        expect(pdfText, contains('<2019>'));
      },
    );
  });
}

TrendReportSnapshot _sampleReport() {
  final publications = [
    _publication(
      title: 'High Impact Paper',
      citations: 50,
      year: 2023,
      journal: 'Journal A',
      authors: ['Ada Lovelace'],
    ),
    _publication(
      title: 'Recent Paper',
      citations: 10,
      year: 2024,
      journal: 'Journal B',
      authors: ['Grace Hopper'],
    ),
  ];

  return TrendReportSnapshot(
    topic: 'Artificial Intelligence',
    publications: publications,
    publicationCountByYear: const {2023: 1, 2024: 1},
    topInfluentialPapers: publications,
    topJournals: const {'Journal A': 1, 'Journal B': 1},
    topAuthors: const {'Ada Lovelace': 1, 'Grace Hopper': 1},
    totalPublications: 2,
    averageCitationCount: 30,
    mostActiveYear: 2023,
    topJournal: 'Journal A',
    topAuthor: 'Ada Lovelace',
    mostInfluentialPaper: publications.first,
  );
}

Publication _publication({
  required String title,
  required int citations,
  required int year,
  required String journal,
  required List<String> authors,
}) {
  return Publication(
    id: title,
    title: title,
    publicationYear: year,
    citedByCount: citations,
    journalName: journal,
    doi: null,
    abstractText: null,
    authors: authors,
    relatedWorkIds: const [],
    referencedWorkIds: const [],
  );
}
