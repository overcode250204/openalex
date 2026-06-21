import 'package:flutter/foundation.dart';

import '../models/keyword/keyword_dashboard_result.dart';
import '../services/keyword_dashboard_service.dart';

enum KeywordDashboardState {
  initial,
  loading,
  loaded,
  empty,
  error,
  refreshing,
}

class KeywordDashboardProvider extends ChangeNotifier {
  final KeywordDashboardService _service;

  KeywordDashboardProvider(this._service);

  KeywordDashboardState _state = KeywordDashboardState.initial;
  KeywordDashboardResult? _result;
  String? _errorMessage;

  KeywordDashboardState get state => _state;
  KeywordDashboardResult? get result => _result;
  String? get errorMessage => _errorMessage;
  bool get hasData => _result != null && !_result!.isEmpty;

  Future<void> load() async {
    if (_state == KeywordDashboardState.loading ||
        _state == KeywordDashboardState.refreshing) {
      return;
    }
    if (_result != null) {
      _state = _result!.isEmpty
          ? KeywordDashboardState.empty
          : KeywordDashboardState.loaded;
      notifyListeners();
      return;
    }
    await _fetch(forceRefresh: false, refreshing: false);
  }

  Future<void> refresh() => _fetch(forceRefresh: true, refreshing: true);

  Future<void> _fetch({
    required bool forceRefresh,
    required bool refreshing,
  }) async {
    _state = refreshing && _result != null
        ? KeywordDashboardState.refreshing
        : KeywordDashboardState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _result = await _service.fetchKeywordDashboard(
        forceRefresh: forceRefresh,
      );
      _state = _result!.isEmpty
          ? KeywordDashboardState.empty
          : KeywordDashboardState.loaded;
    } catch (_) {
      _errorMessage = 'Unable to load keyword activity. Please try again.';
      _state = KeywordDashboardState.error;
    }
    notifyListeners();
  }
}
