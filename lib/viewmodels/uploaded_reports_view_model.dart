import 'package:flutter/foundation.dart';

import '../models/report/uploaded_report.dart';
import '../services/report/report_metadata_service.dart';

typedef UploadedReportsUserIdResolver = String? Function();

class UploadedReportsViewModel extends ChangeNotifier {
  final ReportMetadataService _metadataService;
  final UploadedReportsUserIdResolver _userIdResolver;

  UploadedReportsViewModel({
    required ReportMetadataService metadataService,
    required UploadedReportsUserIdResolver userIdResolver,
  }) : _metadataService = metadataService,
       _userIdResolver = userIdResolver;

  bool _isLoading = false;
  String? _errorMessage;
  List<UploadedReport> _reports = const [];
  String? _lastLoadedUserId;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<UploadedReport> get reports => List.unmodifiable(_reports);
  bool get hasReports => _reports.isNotEmpty;

  Future<void> load({bool force = false}) async {
    final userId = _userIdResolver();
    if (userId == null || userId.trim().isEmpty) {
      _lastLoadedUserId = null;
      _reports = const [];
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    if (!force && _lastLoadedUserId == userId && _reports.isNotEmpty) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final reports = await _metadataService.fetchUploadedReports(
        userId: userId,
      );
      _lastLoadedUserId = userId;
      _reports = reports;
    } catch (error) {
      _errorMessage = 'Cannot load uploaded PDF reports: $error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load(force: true);
}
