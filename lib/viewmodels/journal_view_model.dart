import 'package:flutter/material.dart';

import '../models/journal/journal_source.dart';
import '../services/openalex_journal_service.dart';

class JournalViewModel extends ChangeNotifier {
  final OpenAlexJournalService _service;

  JournalViewModel(this._service);

  List<JournalSource> _journals = [];
  bool _isLoading = false;
  String? _error;
  String _query = '';

  List<JournalSource> get journals => List.unmodifiable(_journals);
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get query => _query;

  Future<void> init() async {
    if (_isLoading || _journals.isNotEmpty) return;
    await loadTopJournals();
  }

  Future<void> loadTopJournals() async {
    _query = '';
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _journals = await _service.fetchTopJournals();
    } catch (_) {
      _error = 'Failed to load journals. Please try again.';
      _journals = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      await loadTopJournals();
      return;
    }
    _query = trimmed;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _journals = await _service.searchJournals(trimmed);
    } catch (_) {
      _error = 'Search failed. Please try again.';
      _journals = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
