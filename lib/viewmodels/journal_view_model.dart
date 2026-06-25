import 'dart:async';

import 'package:flutter/material.dart';

import '../models/journal/journal_publication.dart';
import '../models/journal/journal_source.dart';
import '../models/journal/journal_suggestion.dart';
import '../services/analytics/app_analytics_service.dart';
import '../services/analytics/no_op_analytics_service.dart';
import '../services/openalex_journal_service.dart';
import '../services/suggestion_service.dart';

class JournalViewModel extends ChangeNotifier {
  static const int publicationsPerPage = 20;

  final OpenAlexJournalService _service;
  final SuggestionService _suggestionService;
  final AppAnalyticsService _analyticsService;

  JournalViewModel(
    this._service, {
    SuggestionService? suggestionService,
    AppAnalyticsService analyticsService = const NoOpAnalyticsService(),
  }) : _suggestionService = suggestionService ?? SuggestionService(),
       _analyticsService = analyticsService;

  String _searchQuery = '';
  List<JournalSource> _journals = [];
  JournalSource? _selectedJournal;
  List<JournalPublication> _publications = [];
  JournalPublication? _highestCitedPaper;
  JournalPublication? _selectedPublication;
  bool _isSearchingJournals = false;
  bool _isLoadingPublications = false;
  bool _isLoadingMorePublications = false;
  bool _isLoadingHighestCited = false;
  String? _errorMessage;
  int _currentPage = 1;

  // ── Journal suggestion state ──────────────────────────────────────────────
  Timer? _debounce;
  List<JournalSuggestion> _journalSuggestions = [];
  bool _showJournalSuggestions = false;
  bool _isLoadingJournalSuggestions = false;
  bool _hasMorePublications = true;

  String get searchQuery => _searchQuery;
  List<JournalSource> get journals => _journals;
  JournalSource? get selectedJournal => _selectedJournal;
  List<JournalPublication> get publications => _publications;
  JournalPublication? get highestCitedPaper => _highestCitedPaper;
  JournalPublication? get selectedPublication => _selectedPublication;
  bool get isSearchingJournals => _isSearchingJournals;
  bool get isLoadingPublications => _isLoadingPublications;
  bool get isLoadingMorePublications => _isLoadingMorePublications;
  bool get isLoadingHighestCited => _isLoadingHighestCited;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  bool get hasMorePublications => _hasMorePublications;

  List<JournalSuggestion> get journalSuggestions => _journalSuggestions;
  bool get showJournalSuggestions => _showJournalSuggestions;
  bool get isLoadingJournalSuggestions => _isLoadingJournalSuggestions;

  Future<void> searchJournals(String query) async {
    final trimmedQuery = query.trim();
    _searchQuery = trimmedQuery;
    _journals = [];
    _selectedJournal = null;
    _publications = [];
    _highestCitedPaper = null;
    _selectedPublication = null;
    _currentPage = 1;
    _hasMorePublications = true;

    if (trimmedQuery.isEmpty) {
      _errorMessage = 'Please enter a journal name.';
      notifyListeners();
      return;
    }

    _isSearchingJournals = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _journals = await _service.searchJournals(trimmedQuery);
      if (_journals.isEmpty) {
        _errorMessage = 'No matching journal found.';
      }
    } catch (_) {
      _errorMessage = 'Cannot load data from OpenAlex. Please try again.';
    } finally {
      _isSearchingJournals = false;
      notifyListeners();
    }
  }

  Future<void> selectJournal(JournalSource journal) async {
    _selectedJournal = journal;
    _publications = [];
    _highestCitedPaper = null;
    _selectedPublication = null;
    _currentPage = 1;
    _hasMorePublications = true;
    _errorMessage = null;
    notifyListeners();

    // Fire analytics event when user views a journal
    unawaited(
      _analyticsService.logViewJournal(
        journalName: journal.displayName,
        journalId: journal.sourceId,
        worksCount: journal.worksCount,
        citedByCount: journal.citedByCount,
      ),
    );

    await Future.wait([
      loadPublications(journal.sourceId),
      loadHighestCitedPaper(journal.sourceId),
    ]);
  }

  Future<void> loadPublications(String sourceId) async {
    _isLoadingPublications = true;
    _currentPage = 1;
    _hasMorePublications = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _service.getJournalPublications(
        sourceId,
        page: _currentPage,
        perPage: publicationsPerPage,
      );
      _publications = result;
      _hasMorePublications = result.length >= publicationsPerPage;
      _currentPage++;

      if (result.isEmpty) {
        _errorMessage = 'This journal has no publications in OpenAlex.';
      }
    } catch (_) {
      _publications = [];
      _errorMessage = 'Cannot load data from OpenAlex. Please try again.';
    } finally {
      _isLoadingPublications = false;
      notifyListeners();
    }
  }

  Future<void> loadMorePublications() async {
    final journal = _selectedJournal;
    if (journal == null ||
        !_hasMorePublications ||
        _isLoadingPublications ||
        _isLoadingMorePublications) {
      return;
    }

    _isLoadingMorePublications = true;
    notifyListeners();

    try {
      final result = await _service.getJournalPublications(
        journal.sourceId,
        page: _currentPage,
        perPage: publicationsPerPage,
      );
      _publications = [..._publications, ...result];
      _hasMorePublications = result.length >= publicationsPerPage;
      _currentPage++;
    } catch (_) {
      _errorMessage =
          'Cannot load more publications from OpenAlex. Please try again.';
    } finally {
      _isLoadingMorePublications = false;
      notifyListeners();
    }
  }

  Future<void> loadHighestCitedPaper(String sourceId) async {
    _isLoadingHighestCited = true;
    notifyListeners();

    try {
      _highestCitedPaper = await _service.getHighestCitedPublication(sourceId);
    } catch (_) {
      _highestCitedPaper = null;
    } finally {
      _isLoadingHighestCited = false;
      notifyListeners();
    }
  }

  void selectPublication(JournalPublication publication) {
    _selectedPublication = publication;
    notifyListeners();
  }

  void clearSelection() {
    _selectedJournal = null;
    _publications = [];
    _highestCitedPaper = null;
    _selectedPublication = null;
    _currentPage = 1;
    _hasMorePublications = true;
    _errorMessage = null;
    notifyListeners();
  }

  // ── Journal suggestion methods ────────────────────────────────────────────

  void onJournalQueryChanged(String query) {
    _debounce?.cancel();

    final trimmedQuery = query.trim();

    if (trimmedQuery.length < 2) {
      _journalSuggestions = [];
      _showJournalSuggestions = false;
      _isLoadingJournalSuggestions = false;
      notifyListeners();
      return;
    }

    _showJournalSuggestions = true;
    _isLoadingJournalSuggestions = true;
    notifyListeners();

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        _journalSuggestions = await _suggestionService.fetchJournalSuggestions(
          trimmedQuery,
        );
      } catch (_) {
        _journalSuggestions = [];
      }

      _isLoadingJournalSuggestions = false;
      notifyListeners();
    });
  }

  void hideJournalSuggestions() {
    _showJournalSuggestions = false;
    notifyListeners();
  }

  void clearJournalSuggestions() {
    _journalSuggestions = [];
    _showJournalSuggestions = false;
    _isLoadingJournalSuggestions = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
