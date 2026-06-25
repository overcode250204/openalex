import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/models/publication/publication.dart';
import 'package:openalex/models/trend/trend_report_snapshot.dart';
import 'package:openalex/services/pdf_export_service.dart';
import 'package:openalex/services/pdf_report_layout_service.dart';

void main() {
  group('PdfExportService', () {
    late Directory tempDirectory;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'openalex_pdf_export_test_',
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test(
      'writes a dashboard PDF report to the resolved export directory',
      () async {
        final service = PdfExportService(
          layoutService: const PdfReportLayoutService(),
          directoryResolver: () async => tempDirectory,
        );

        final result = await service.exportDashboardPdfReport(
          _sampleReport(),
          generatedAt: DateTime(2026, 6, 25, 14, 20, 30),
        );

        expect(await result.file.exists(), isTrue);
        expect(
          result.file.path,
          endsWith('trend-report-artificial-intelligence-20260625-142030.pdf'),
        );
        expect(result.byteLength, greaterThan(1000));
        expect(await result.file.length(), result.byteLength);
        expect(
          await result.file.openRead(0, 5).first,
          equals('%PDF-'.codeUnits),
        );
      },
    );
  });
}

TrendReportSnapshot _sampleReport() {
  final publication = Publication(
    id: 'W1',
    title: 'Reliable Research',
    publicationYear: 2024,
    citedByCount: 42,
    journalName: 'Journal of Tests',
    doi: null,
    abstractText: null,
    authors: const ['Ada Lovelace'],
    relatedWorkIds: const [],
    referencedWorkIds: const [],
  );

  return TrendReportSnapshot(
    topic: 'Artificial Intelligence',
    publications: [publication],
    publicationCountByYear: const {2024: 1},
    topInfluentialPapers: [publication],
    topJournals: const {'Journal of Tests': 1},
    topAuthors: const {'Ada Lovelace': 1},
    totalPublications: 1,
    averageCitationCount: 42,
    mostActiveYear: 2024,
    topJournal: 'Journal of Tests',
    topAuthor: 'Ada Lovelace',
    mostInfluentialPaper: publication,
  );
}
