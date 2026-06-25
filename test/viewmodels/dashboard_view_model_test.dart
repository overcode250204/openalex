import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/models/trend/trend_report_snapshot.dart';
import 'package:openalex/services/pdf_export_service.dart';
import 'package:openalex/services/pdf_report_layout_service.dart';
import 'package:openalex/services/trend_report_export_service.dart';
import 'package:openalex/viewmodels/dashboard_view_model.dart';

void main() {
  group('DashboardViewModel', () {
    test('exposes loading state while exporting dashboard PDF', () async {
      final completer = Completer<PdfExportResult>();
      final viewModel = DashboardViewModel(
        exportService: const TrendReportExportService(),
        pdfExportService: _ControlledPdfExportService(completer),
      );

      final exportFuture = viewModel.exportDashboardPdfReport(_emptyReport());

      expect(viewModel.isExporting, isTrue);

      completer.complete(
        PdfExportResult(
          file: File('dashboard.pdf'),
          byteLength: 128,
          generatedAt: DateTime(2026, 6, 25),
        ),
      );
      final result = await exportFuture;

      expect(result.file.path, 'dashboard.pdf');
      expect(viewModel.isExporting, isFalse);
    });

    test('resets loading state when dashboard PDF export fails', () async {
      final completer = Completer<PdfExportResult>();
      final viewModel = DashboardViewModel(
        exportService: const TrendReportExportService(),
        pdfExportService: _ControlledPdfExportService(completer),
      );

      final exportFuture = viewModel.exportDashboardPdfReport(_emptyReport());

      expect(viewModel.isExporting, isTrue);

      completer.completeError(Exception('disk full'));

      await expectLater(exportFuture, throwsException);
      expect(viewModel.isExporting, isFalse);
    });
  });
}

class _ControlledPdfExportService extends PdfExportService {
  final Completer<PdfExportResult> _completer;

  _ControlledPdfExportService(this._completer)
    : super(layoutService: const PdfReportLayoutService());

  @override
  Future<PdfExportResult> exportDashboardPdfReport(
    TrendReportSnapshot report, {
    DateTime? generatedAt,
  }) {
    return _completer.future;
  }
}

TrendReportSnapshot _emptyReport() {
  return const TrendReportSnapshot(
    topic: 'AI',
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
  );
}
