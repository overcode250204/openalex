import 'package:flutter/foundation.dart';

import '../../models/report/uploaded_report.dart';
import '../../services/admin/admin_service.dart';

class AdminReportsViewModel extends ChangeNotifier {
  AdminReportsViewModel(this._service);

  final AdminService _service;

  List<UploadedReport> _reports = [];
  String? _nextCursor;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;

  List<UploadedReport> get reports => List.unmodifiable(_reports);
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _nextCursor != null;
  String? get errorMessage => _errorMessage;

  Future<void> loadFirstPage() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final page = await _service.listAllReports();
      _reports = page.reports;
      _nextCursor = page.nextCursor;
    } catch (_) {
      _errorMessage = 'Could not load reports.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || _nextCursor == null) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final page = await _service.listAllReports(cursor: _nextCursor);
      _reports = [..._reports, ...page.reports];
      _nextCursor = page.nextCursor;
    } catch (_) {
      _errorMessage = 'Could not load more reports.';
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }
}
