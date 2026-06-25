import 'package:flutter/foundation.dart';

import '../models/trend/trend_report_snapshot.dart';
import '../services/pdf_export_service.dart';
import '../services/trend_report_export_service.dart';

class DashboardViewModel extends ChangeNotifier {
  final TrendReportExportService _exportService;
  final PdfExportService _pdfExportService;

  DashboardViewModel({
    required TrendReportExportService exportService,
    required PdfExportService pdfExportService,
  }) : _exportService = exportService,
       _pdfExportService = pdfExportService;

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
}
