import 'dart:async';

import 'package:flutter/material.dart';

import '../models/keyword/keyword_analysis_result.dart';
import '../services/openalex_keyword_service.dart';
import '../services/suggestion_service.dart';

class KeywordAnalyzerViewModel extends ChangeNotifier {
  final OpenAlexKeywordService _service;
  final SuggestionService _suggestionService;

  KeywordAnalyzerViewModel(
    this._service, {
    SuggestionService? suggestionService,
  }) : _suggestionService = suggestionService ?? SuggestionService();

  String _keyword = '';
  bool _isLoading = false;
  String? _errorMessage;
  KeywordAnalysisResult? _result;
  List<String> _keywordSuggestions = [];
  bool _showKeywordSuggestions = false;
  Timer? _debounce;

  int _selectedFromYear = 2011;
  int _selectedToYear = DateTime.now().year;
  bool _isLoadingTrend = false;
  bool _hasTrendError = false;

  String get keyword => _keyword;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  KeywordAnalysisResult? get result => _result;
  List<String> get keywordSuggestions => _keywordSuggestions;
  bool get showKeywordSuggestions => _showKeywordSuggestions;

  int get selectedFromYear => _selectedFromYear;
  int get selectedToYear => _selectedToYear;
  bool get isLoadingTrend => _isLoadingTrend;
  bool get hasTrendError => _hasTrendError;

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

  void onQueryChanged(String query) {
    _debounce?.cancel();

    final trimmedQuery = query.trim();

    if (trimmedQuery.isEmpty) {
      _keywordSuggestions = [];
      _showKeywordSuggestions = false;
      notifyListeners();
      return;
    }

    _showKeywordSuggestions = true;
    notifyListeners();

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        _keywordSuggestions = await _suggestionService.fetchKeywordSuggestions(
          trimmedQuery,
        );
      } catch (_) {
        _keywordSuggestions = [];
      }

      notifyListeners();
    });
  }

  void hideKeywordSuggestions() {
    _showKeywordSuggestions = false;
    notifyListeners();
  }

  Future<void> analyze(String keyword) async {
    final trimmedKeyword = keyword.trim();
    _debounce?.cancel();
    _keywordSuggestions = [];
    _showKeywordSuggestions = false;

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

  Future<void> retry() async {
    if (_keyword.trim().isEmpty) return;
    await analyze(_keyword);
  }

  void clear() {
    _debounce?.cancel();
    _keyword = '';
    _isLoading = false;
    _errorMessage = null;
    _result = null;
    _keywordSuggestions = [];
    _showKeywordSuggestions = false;
    _isLoadingTrend = false;
    _hasTrendError = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
