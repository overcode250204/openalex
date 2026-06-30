import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/report/report_upload_result.dart';
import '../models/trend/trend_report_snapshot.dart';
import '../services/analytics/app_analytics_service.dart';
import '../services/analytics/no_op_analytics_service.dart';
import '../services/trend_report_export_service.dart';

typedef CurrentUserIdResolver = String? Function();

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
  final AppAnalyticsService _analyticsService;

  DashboardViewModel({
    required TrendReportExportService exportService,
    AppAnalyticsService analyticsService = const NoOpAnalyticsService(),
  }) : _exportService = exportService,
       _analyticsService = analyticsService;

  bool _isExporting = false;
  bool get isExporting => _isExporting;

  ReportUploadResult? _lastUploadedPdfReport;
  ReportUploadResult? get lastUploadedPdfReport => _lastUploadedPdfReport;

  void clearUploadedPdfReport() {
    if (_lastUploadedPdfReport == null) return;

    _lastUploadedPdfReport = null;
    notifyListeners();
  }

  Future<TrendReportExportResult> exportTrendReport(
    TrendReportSnapshot report,
  ) async {
    _isExporting = true;
    notifyListeners();
    try {
      final result = await _exportService.exportMarkdownReport(report);
      // Log export_pdf event on success
      unawaited(
        _analyticsService.logExportPdf(
          topic: report.topic,
          publicationCount: report.totalPublications,
        ),
      );
      return result;
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
      await _reportMetadataService.saveUploadedReport(
        uploadResult: uploadResult,
        topic: report.topic,
        userId: _currentUserIdResolver(),
      );
      await _logPdfExport(report: report, uploadResult: uploadResult);
      _lastUploadedPdfReport = uploadResult;

      return DashboardPdfUploadResult(
        exportResult: exportResult,
        uploadResult: uploadResult,
      );
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }

  Future<void> _logPdfExport({
    required TrendReportSnapshot report,
    required ReportUploadResult uploadResult,
  }) async {
    try {
      await _analyticsService.logPdfExport(
        topic: report.topic,
        exportType: 'dashboard_pdf',
        provider: uploadResult.provider,
        bucket: uploadResult.bucket,
        fileName: uploadResult.fileName,
        sizeBytes: uploadResult.sizeBytes,
        hasUploadedLink: uploadResult.downloadUrl.trim().isEmpty ? 0 : 1,
      );
    } catch (error, stackTrace) {
      debugPrint('Unable to log PDF export analytics: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
