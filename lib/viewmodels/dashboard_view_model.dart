import 'package:flutter/foundation.dart';

import '../models/trend/trend_report_snapshot.dart';
import '../services/trend_report_export_service.dart';

class DashboardViewModel extends ChangeNotifier {
  final TrendReportExportService _exportService;

  DashboardViewModel({required TrendReportExportService exportService})
    : _exportService = exportService;

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
}
