import 'package:flutter/foundation.dart';

import '../../models/admin/admin_dashboard_stats.dart';
import '../../services/admin/admin_service.dart';

class AdminDashboardViewModel extends ChangeNotifier {
  AdminDashboardViewModel(this._service);

  final AdminService _service;

  bool _isLoading = false;
  String? _errorMessage;
  AdminDashboardStats? _stats;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AdminDashboardStats? get stats => _stats;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _stats = await _service.getDashboardStats();
    } catch (_) {
      _errorMessage = 'Could not load dashboard statistics.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
