import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/trend/trend_report_snapshot.dart';
import '../services/analytics/app_analytics_service.dart';
import '../services/analytics/no_op_analytics_service.dart';
import '../services/trend_report_export_service.dart';

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
}
