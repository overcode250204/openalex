import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/keyword/keyword_analysis_result.dart';
import '../models/keyword/openalex_keyword.dart';
import '../services/openalex_keyword_service.dart';
import '../services/suggestion_service.dart';

enum KeywordDetailState {
  idle,
  searching,
  resolved,
  loading,
  loaded,
  error,
}

class KeywordDetailProvider extends ChangeNotifier {
  final OpenAlexKeywordService _service;
  final SuggestionService _suggestionService;

  KeywordDetailProvider(
    this._service, {
    SuggestionService? suggestionService,
  }) : _suggestionService = suggestionService ?? SuggestionService();

  KeywordDetailState _state = KeywordDetailState.idle;
  String _keyword = '';
  String? _errorMessage;
  OpenAlexKeyword? _resolvedKeyword;
  KeywordAnalysisResult? _result;
  List<String> _keywordSuggestions = [];
  bool _showKeywordSuggestions = false;
  Timer? _debounce;
  int _selectedFromYear = 2011;
  int _selectedToYear = DateTime.now().year;
  bool _isLoadingTrend = false;
  bool _hasTrendError = false;

  KeywordDetailState get state => _state;
  String get keyword => _keyword;
  String? get errorMessage => _errorMessage;
  OpenAlexKeyword? get resolvedKeyword => _resolvedKeyword;
  KeywordAnalysisResult? get result => _result;
  List<String> get keywordSuggestions => _keywordSuggestions;
  bool get showKeywordSuggestions => _showKeywordSuggestions;
  int get selectedFromYear => _selectedFromYear;
  int get selectedToYear => _selectedToYear;
  bool get isLoadingTrend => _isLoadingTrend;
  bool get hasTrendError => _hasTrendError;
  bool get isLoading => _state == KeywordDetailState.searching ||
      _state == KeywordDetailState.resolved ||
      _state == KeywordDetailState.loading;

  Future<void> analyze(String keyword) async {
    final trimmed = keyword.trim();
    _debounce?.cancel();
    _keywordSuggestions = [];
    _showKeywordSuggestions = false;

    if (trimmed.isEmpty) {
      _keyword = '';
      _result = null;
      _resolvedKeyword = null;
      _errorMessage = 'Please enter an academic keyword.';
      _state = KeywordDetailState.error;
      notifyListeners();
      return;
    }

    _keyword = trimmed;
    _result = null;
    _resolvedKeyword = null;
    _errorMessage = null;
    _state = KeywordDetailState.searching;
    notifyListeners();

    try {
      final resolved = await _service.resolveKeyword(trimmed);
      if (resolved == null || resolved.id.isEmpty) {
        throw KeywordNotFoundException('No matching OpenAlex keyword found.');
      }
      _resolvedKeyword = resolved;
      _state = KeywordDetailState.resolved;
      notifyListeners();

      _state = KeywordDetailState.loading;
      notifyListeners();
      _result = await _service.analyzeResolvedKeyword(
        trimmed,
        resolved,
        fromYear: _selectedFromYear,
        toYear: _selectedToYear,
      );
      _state = KeywordDetailState.loaded;
    } on KeywordNotFoundException catch (error) {
      _errorMessage = error.message;
      _state = KeywordDetailState.error;
    } catch (_) {
      _errorMessage = 'Unable to analyze keyword. Please try again.';
      _state = KeywordDetailState.error;
    }
    notifyListeners();
  }

  Future<void> retry() => analyze(_keyword);

  Future<void> updateKeywordTrendYearRange({
    required int fromYear,
    required int toYear,
  }) async {
    _selectedFromYear = mathMin(fromYear, toYear);
    _selectedToYear = mathMax(fromYear, toYear);
    notifyListeners();
    await reloadKeywordTrend();
  }

  Future<void> reloadKeywordTrend() async {
    if (_keyword.isEmpty || _result == null) return;
    _isLoadingTrend = true;
    _hasTrendError = false;
    notifyListeners();
    try {
      final trend = await _service.fetchKeywordTrend(
        keyword: _keyword,
        fromYear: _selectedFromYear,
        toYear: _selectedToYear,
      );
      _result = _result?.copyWith(trend: trend);
    } catch (_) {
      _hasTrendError = true;
    } finally {
      _isLoadingTrend = false;
      notifyListeners();
    }
  }

  void onQueryChanged(String query) {
    _debounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      _keywordSuggestions = [];
      _showKeywordSuggestions = false;
      notifyListeners();
      return;
    }
    _showKeywordSuggestions = true;
    notifyListeners();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        _keywordSuggestions =
            await _suggestionService.fetchKeywordSuggestions(trimmed);
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

  void clear() {
    _debounce?.cancel();
    _state = KeywordDetailState.idle;
    _keyword = '';
    _errorMessage = null;
    _resolvedKeyword = null;
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

int mathMin(int a, int b) => a < b ? a : b;
int mathMax(int a, int b) => a > b ? a : b;
