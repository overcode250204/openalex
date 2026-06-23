import 'dart:async';

import 'package:flutter/material.dart';

import '../models/keyword/keyword_analysis_result.dart';
import '../models/keyword/openalex_keyword.dart';
import '../services/openalex_keyword_service.dart';

class KeywordAnalyzerViewModel extends ChangeNotifier {
  final OpenAlexKeywordService _service;

  KeywordAnalyzerViewModel(this._service);

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
      _result = await _service.analyzeKeyword(
        trimmedKeyword,
        fromYear: _selectedFromYear,
        toYear: _selectedToYear,
      );
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
      _result = await _service.analyzeResolvedKeyword(
        trimmedKeyword,
        resolvedKeyword,
        fromYear: _selectedFromYear,
        toYear: _selectedToYear,
      );
    } catch (_) {
      _result = null;
      _errorMessage = 'Unable to analyze keyword. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> retry() async {
    if (_keyword.trim().isEmpty) return;
    await analyze(_keyword);
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
