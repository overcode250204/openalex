import 'package:flutter/material.dart';

import '../models/keyword/keyword_analysis_result.dart';
import '../services/openalex_keyword_service.dart';

class KeywordAnalyzerViewModel extends ChangeNotifier {
  final OpenAlexKeywordService _service;

  KeywordAnalyzerViewModel(this._service);

  String _keyword = '';
  bool _isLoading = false;
  String? _errorMessage;
  KeywordAnalysisResult? _result;

  String get keyword => _keyword;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  KeywordAnalysisResult? get result => _result;

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
      _result = await _service.analyzeKeyword(trimmedKeyword);
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
    notifyListeners();
  }
}
