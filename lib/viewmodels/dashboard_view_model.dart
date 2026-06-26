import 'package:flutter/foundation.dart';

import '../models/report/report_upload_result.dart';
import '../models/trend/trend_report_snapshot.dart';
import '../services/pdf_export_service.dart';
import '../services/report/report_storage_service.dart';
import '../services/trend_report_export_service.dart';

class DashboardPdfUploadResult {
  final PdfExportResult exportResult;
  final ReportUploadResult uploadResult;

  const DashboardPdfUploadResult({
    required this.exportResult,
    required this.uploadResult,
  });
}

class DashboardViewModel extends ChangeNotifier {
  final TrendReportExportService _exportService;
  final PdfExportService _pdfExportService;
  final ReportStorageService _reportStorageService;

  DashboardViewModel({
    required TrendReportExportService exportService,
    required PdfExportService pdfExportService,
    required ReportStorageService reportStorageService,
  }) : _exportService = exportService,
       _pdfExportService = pdfExportService,
       _reportStorageService = reportStorageService;

  bool _isExporting = false;
  bool get isExporting => _isExporting;

  Future<TrendReportExportResult> exportTrendReport(
    TrendReportSnapshot report,
  ) async {
    _isExporting = true;
    notifyListeners();
    try {
      return await _exportService.exportMarkdownReport(report);
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }

  Future<PdfExportResult> exportDashboardPdfReport(
    TrendReportSnapshot report,
  ) async {
    _isExporting = true;
    notifyListeners();
    try {
      return await _pdfExportService.exportDashboardPdfReport(report);
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }

  Future<DashboardPdfUploadResult> exportAndUploadDashboardPdfReport(
    TrendReportSnapshot report,
  ) async {
    _isExporting = true;
    notifyListeners();
    try {
      final exportResult = await _pdfExportService.exportDashboardPdfReport(
        report,
      );
      final fileName = exportResult.file.uri.pathSegments.isNotEmpty
          ? exportResult.file.uri.pathSegments.last
          : 'dashboard-report.pdf';
      final uploadResult = await _reportStorageService.uploadReport(
        bytes: exportResult.bytes,
        fileName: fileName,
        contentType: 'application/pdf',
        topic: report.topic,
        uploadedAt: exportResult.generatedAt,
      );

      return DashboardPdfUploadResult(
        exportResult: exportResult,
        uploadResult: uploadResult,
      );
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }
}
