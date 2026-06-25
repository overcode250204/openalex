import 'dart:async';

import 'package:flutter/material.dart';

import '../models/keyword/keyword_analysis_result.dart';
import '../models/keyword/openalex_keyword.dart';
import '../services/analytics/app_analytics_service.dart';
import '../services/analytics/no_op_analytics_service.dart';
import '../services/firebase/remote_config_service.dart';
import '../services/openalex_keyword_service.dart';

class KeywordAnalyzerViewModel extends ChangeNotifier {
  final OpenAlexKeywordService _service;
  final AppAnalyticsService _analyticsService;
  final AppRemoteConfigService _remoteConfigService;

  KeywordAnalyzerViewModel(
    this._service, {
    AppAnalyticsService analyticsService = const NoOpAnalyticsService(),
    AppRemoteConfigService remoteConfigService = const NoOpRemoteConfigService(),
  }) : _analyticsService = analyticsService,
       _remoteConfigService = remoteConfigService;

  String _keyword = '';
  bool _isLoading = false;
  String? _errorMessage;
  KeywordAnalysisResult? _result;

  int _selectedFromYear = 2011;
  int _selectedToYear = DateTime.now().year;
  bool _isLoadingTrend = false;
  bool _hasTrendError = false;
  bool _isResolvingKeyword = false;

  String get keyword => _keyword;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  KeywordAnalysisResult? get result => _result;

  int get selectedFromYear => _selectedFromYear;
  int get selectedToYear => _selectedToYear;
  bool get isLoadingTrend => _isLoadingTrend;
  bool get hasTrendError => _hasTrendError;
  bool get isResolvingKeyword => _isResolvingKeyword;

  Future<OpenAlexKeyword?> resolveKeyword(String keyword) async {
    final trimmedKeyword = keyword.trim();
    if (trimmedKeyword.isEmpty) return null;

    _isResolvingKeyword = true;
    notifyListeners();
    try {
      return await _service.resolveKeyword(trimmedKeyword);
    } finally {
      _isResolvingKeyword = false;
      notifyListeners();
    }
  }

  Future<void> updateKeywordTrendYearRange({
    required int fromYear,
    required int toYear,
  }) async {
    _selectedFromYear = fromYear;
    _selectedToYear = toYear;

    if (_selectedFromYear > _selectedToYear) {
      final temp = _selectedFromYear;
      _selectedFromYear = _selectedToYear;
      _selectedToYear = temp;
    }

    notifyListeners();

    final trimmedKeyword = keyword.trim();

    if (trimmedKeyword.isEmpty) {
      return;
    }

    await reloadKeywordTrend();
  }

  Future<void> reloadKeywordTrend() async {
    final trimmedKeyword = keyword.trim();

    if (trimmedKeyword.isEmpty) {
      return;
    }

    _isLoadingTrend = true;
    _hasTrendError = false;
    notifyListeners();

    try {
      final trend = await _service.fetchKeywordTrend(
        keyword: trimmedKeyword,
        fromYear: _selectedFromYear,
        toYear: _selectedToYear,
      );

      _result = _result?.copyWith(trend: trend);
      _isLoadingTrend = false;
    } catch (_) {
      _hasTrendError = true;
      _isLoadingTrend = false;
    }

    notifyListeners();
  }

  Future<void> analyze(String keyword) async {
    final trimmedKeyword = keyword.trim();

    if (trimmedKeyword.isEmpty) {
      _keyword = '';
      _result = null;
      _isLoading = false;
      _errorMessage = 'Please enter an academic keyword.';
      notifyListeners();
      return;
    }

    _keyword = trimmedKeyword;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final rawResult = await _service.analyzeKeyword(
        trimmedKeyword,
        fromYear: _selectedFromYear,
        toYear: _selectedToYear,
      );

      _result = _applyLimits(rawResult);
    } on KeywordNotFoundException catch (e) {
      _result = null;
      _errorMessage = e.message;
    } catch (_) {
      _result = null;
      _errorMessage = 'Unable to analyze keyword. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> analyzeResolvedKeyword(
    String keyword,
    OpenAlexKeyword resolvedKeyword,
  ) async {
    final trimmedKeyword = keyword.trim();
    _keyword = trimmedKeyword;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final rawResult = await _service.analyzeResolvedKeyword(
        trimmedKeyword,
        resolvedKeyword,
        fromYear: _selectedFromYear,
        toYear: _selectedToYear,
      );
      _result = _applyLimits(rawResult);
    } catch (_) {
      _result = null;
      _errorMessage = 'Unable to analyze keyword. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  KeywordAnalysisResult _applyLimits(KeywordAnalysisResult result) {
    final limit = _remoteConfigService.maxKeywordsDisplayed;
    return result.copyWith(
      relevantPapers:
          result.relevantPapers.length > limit
              ? result.relevantPapers.sublist(0, limit)
              : result.relevantPapers,
      mostCitedPapers:
          result.mostCitedPapers.length > limit
              ? result.mostCitedPapers.sublist(0, limit)
              : result.mostCitedPapers,
      latestPapers:
          result.latestPapers.length > limit
              ? result.latestPapers.sublist(0, limit)
              : result.latestPapers,
      openAccessPapers:
          result.openAccessPapers.length > limit
              ? result.openAccessPapers.sublist(0, limit)
              : result.openAccessPapers,
    );
  }

  Future<void> retry() async {
    if (_keyword.trim().isEmpty) return;
    await analyze(_keyword);
  }

  Future<void> logViewEvent(String keyword) async {
    final cleanKeyword = keyword.trim();
    if (cleanKeyword.isNotEmpty) {
      await _analyticsService.logViewKeyword(keyword: cleanKeyword);
    }
  }

  void clear() {
    _keyword = '';
    _isLoading = false;
    _errorMessage = null;
    _result = null;
    _isLoadingTrend = false;
    _hasTrendError = false;
    notifyListeners();
  }
}
