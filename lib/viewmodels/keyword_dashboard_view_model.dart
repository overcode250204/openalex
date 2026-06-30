import 'package:flutter/foundation.dart';

import '../models/keyword/keyword_dashboard_result.dart';
import '../services/firebase/remote_config_service.dart';
import '../services/keyword_dashboard_service.dart';

enum KeywordDashboardState {
  initial,
  loading,
  loaded,
  empty,
  error,
  refreshing,
}

class KeywordDashboardViewModel extends ChangeNotifier {
  final KeywordDashboardService _service;
  final AppRemoteConfigService _remoteConfigService;

  KeywordDashboardViewModel(
    this._service, {
    AppRemoteConfigService remoteConfigService =
        const NoOpRemoteConfigService(),
  }) : _remoteConfigService = remoteConfigService;

  KeywordDashboardState _state = KeywordDashboardState.initial;
  KeywordDashboardResult? _result;
  String? _errorMessage;
  int _selectedFromYear = 2011;
  int _selectedToYear = DateTime.now().year;

  KeywordDashboardState get state => _state;
  KeywordDashboardResult? get result =>
      _result == null ? null : _applyLimits(_result!);
  String? get errorMessage => _errorMessage;
  bool get hasData => _result != null && !_result!.isEmpty;
  int get selectedFromYear => _selectedFromYear;
  int get selectedToYear => _selectedToYear;

  Future<void> load() async {
    if (_state != KeywordDashboardState.initial || _result != null) return;
    await _fetch(forceRefresh: false, refreshing: false);
  }

  Future<void> refresh() async {
    if (_isFetching) {
      return;
    }
    await _fetch(forceRefresh: true, refreshing: true);
  }

  Future<void> retry() async {
    if (_state != KeywordDashboardState.error) return;
    await _fetch(forceRefresh: true, refreshing: false);
  }

  Future<void> updateTrendYearRange(int fromYear, int toYear) async {
    if (_isFetching) {
      return;
    }
    _selectedFromYear = fromYear < toYear ? fromYear : toYear;
    _selectedToYear = fromYear < toYear ? toYear : fromYear;
    await _fetch(forceRefresh: true, refreshing: true);
  }

  bool get _isFetching =>
      _state == KeywordDashboardState.loading ||
      _state == KeywordDashboardState.refreshing;

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
        trendStartYear: _selectedFromYear,
        trendEndYear: _selectedToYear,
        forceRefresh: forceRefresh,
      );

      _state = result!.isEmpty
          ? KeywordDashboardState.empty
          : KeywordDashboardState.loaded;
    } catch (_) {
      _errorMessage = 'Unable to load keyword activity. Please try again.';
      _state = KeywordDashboardState.error;
    }
    notifyListeners();
  }

  KeywordDashboardResult _applyLimits(KeywordDashboardResult rawResult) {
    final limit = _remoteConfigService.maxKeywordsDisplayed;
    return rawResult.copyWith(
      mostFrequentKeywords: _limitedList(rawResult.mostFrequentKeywords, limit),
      trendingKeywords: _limitedList(rawResult.trendingKeywords, limit),
    );
  }

  List<T> _limitedList<T>(List<T> items, int limit) {
    if (items.length <= limit) return items;
    return items.sublist(0, limit);
  }
}
