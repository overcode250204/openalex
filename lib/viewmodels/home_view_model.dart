import 'package:flutter/material.dart';
import 'package:openalex/models/search/search_filter.dart';
import 'package:openalex/models/topic/topic.dart';
import 'package:openalex/services/history_service.dart';
import 'package:openalex/services/suggestion_service.dart';
import 'package:openalex/viewmodels/selected_topic_view_model.dart';

import '../models/publication/publication.dart';
import '../models/trend/trend_report_snapshot.dart';
import '../services/openalex_service.dart';

class HomeViewModel extends ChangeNotifier {
  final OpenAlexService _openAlexService;
  final SearchHistoryService _historyService;
  final SuggestionService _suggestionService;
  final SelectedTopicViewModel? _selectedTopicViewModel;

  HomeViewModel(
    this._openAlexService, {
    SearchHistoryService? historyService,
    SuggestionService? suggestionService,
    SelectedTopicViewModel? selectedTopicViewModel,
  }) : _historyService = historyService ?? SearchHistoryService(),
       _suggestionService = suggestionService ?? SuggestionService(),
       _selectedTopicViewModel = selectedTopicViewModel;

  List<Publication> _publications = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _currentTopic = '';
  String? _currentTopicId;

  // Lưu topic OpenAlex đã resolve để loadMore/filter không làm mất topicId.
  TopicSuggestion? _selectedTopic;

  SearchFilter _filter = const SearchFilter();
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  int _totalResults = 0;
  List<String> _searchHistory = [];
  List<TopicSuggestion> _conceptSuggestions = [];
  List<String> _relatedKeywords = [];
  bool _showSuggestions = false;

  List<Publication> get publications => _publications;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  String get currentTopic => _currentTopic;
  String? get currentTopicId => _currentTopicId;

  SearchFilter get filter => _filter;
  bool get hasMore => _hasMore;
  int get totalResults => _totalResults;
  bool get isLoadingMore => _isLoadingMore;
  List<String> get searchHistory => _searchHistory;
  List<TopicSuggestion> get conceptSuggestions => _conceptSuggestions;
  List<String> get relatedKeywords => _relatedKeywords;
  bool get showSuggestions => _showSuggestions;
  Future<TopicSuggestion?> _resolveTopic(
    String keyword,
    TopicSuggestion? selectedTopic,
  ) async {
    // User bấm suggestion: dùng chính xác topic đó.
    if (selectedTopic != null) {
      return selectedTopic;
    }

    final normalizedKeyword = keyword.trim().toLowerCase();
    if (normalizedKeyword.isEmpty) return null;

    // Tìm topic suggestion từ OpenAlex.
    final suggestions = await _suggestionService.fetchTopicSuggestions(keyword);

    if (suggestions.isEmpty) return null;

    // Ưu tiên topic trùng tên chính xác.
    for (final suggestion in suggestions) {
      if (suggestion.displayName.trim().toLowerCase() == normalizedKeyword) {
        return suggestion;
      }
    }

    // Không trùng tuyệt đối thì dùng suggestion đầu tiên,
    // vì đây là topic OpenAlex hợp lệ có ID thật.
    return suggestions.first;
  }

  Future<void> searchPublications({
    required String keyword,
    TopicSuggestion? topic,
  }) async {
    final trimmedKeyword = keyword.trim();

    if (trimmedKeyword.isEmpty) {
      _errorMessage = 'Please enter a research topic.';
      notifyListeners();
      return;
    }

    _currentPage = 1;
    _publications = [];
    _totalResults = 0;
    _hasMore = true;
    _isLoadingMore = false;

    _showSuggestions = false;
    _isLoading = true;
    _errorMessage = null;

    await _historyService.addHistory(trimmedKeyword);
    _searchHistory = await _historyService.getHistory();

    notifyListeners();

    try {
      final resolvedTopic = await _resolveTopic(trimmedKeyword, topic);

      _selectedTopic = resolvedTopic;

      _currentTopic = resolvedTopic?.displayName ?? trimmedKeyword;
      _currentTopicId = resolvedTopic?.id.replaceAll(
        'https://openalex.org/',
        '',
      );

      _selectedTopicViewModel?.setTopic(
        _currentTopic,
        suggestion: resolvedTopic,
      );

      final topicIds = _currentTopicId == null
          ? <String>[]
          : <String>[_currentTopicId!];

      final (total, result) = await _openAlexService.searchPublications(
        keyword: _currentTopic,
        topicIds: topicIds,
      );

      _totalResults = total;
      _publications = result;
      _hasMore = result.length >= 50;

      // Page đầu tiên xong, lần loadMore tiếp theo phải load page 2.
      _currentPage = 2;
    } catch (_) {
      _currentTopicId = null;
      _selectedTopic = null;
      _publications = [];
      _totalResults = 0;
      _errorMessage = 'Cannot load publications. Please try again.';
    } finally {
      _isLoading = false;

      try {
        _relatedKeywords = await _suggestionService.fetchRelatedKeywords(
          _currentTopic,
        );
      } catch (_) {
        _relatedKeywords = [];
      }

      notifyListeners();
    }
  }

  Map<int, int> get publicationCountByYear {
    final Map<int, int> result = {};

    for (final publication in _publications) {
      final year = publication.publicationYear;

      if (year != null) {
        result[year] = (result[year] ?? 0) + 1;
      }
    }

    final sortedEntries = result.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Map.fromEntries(sortedEntries);
  }

  List<Publication> get topInfluentialPapers {
    final sorted = [..._publications]
      ..sort((a, b) => b.citedByCount.compareTo(a.citedByCount));

    return sorted.take(10).toList();
  }

  Map<String, int> get topJournals {
    final Map<String, int> result = {};

    for (final publication in _publications) {
      final journal = publication.journalName ?? 'Unknown journal';
      result[journal] = (result[journal] ?? 0) + 1;
    }

    final sortedEntries = result.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sortedEntries.take(10));
  }

  Map<String, int> get topAuthors {
    final Map<String, int> result = {};

    for (final publication in _publications) {
      for (final author in publication.authors) {
        result[author] = (result[author] ?? 0) + 1;
      }
    }

    final sortedEntries = result.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sortedEntries.take(10));
  }

  int get totalPublications {
    return _publications.length;
  }

  double get averageCitationCount {
    if (_publications.isEmpty) {
      return 0;
    }

    final totalCitations = _publications.fold<int>(
      0,
      (sum, publication) => sum + publication.citedByCount,
    );

    return totalCitations / _publications.length;
  }

  int? get mostActiveYear {
    final data = publicationCountByYear;

    if (data.isEmpty) {
      return null;
    }

    return data.entries.reduce((a, b) {
      return a.value >= b.value ? a : b;
    }).key;
  }

  String? get topJournal {
    final data = topJournals;

    if (data.isEmpty) {
      return null;
    }

    final knownJournal = data.entries
        .where((entry) => entry.key.trim().toLowerCase() != 'unknown journal')
        .firstOrNull;

    return knownJournal?.key ?? data.entries.first.key;
  }

  String? get topAuthor {
    final data = topAuthors;

    if (data.isEmpty) {
      return null;
    }

    return data.entries.first.key;
  }

  Publication? get mostInfluentialPaper {
    if (_publications.isEmpty) {
      return null;
    }

    return topInfluentialPapers.first;
  }

  TrendReportSnapshot get trendReportSnapshot {
    return TrendReportSnapshot(
      topic: _currentTopic,
      publications: _publications,
      publicationCountByYear: publicationCountByYear,
      topInfluentialPapers: topInfluentialPapers,
      topJournals: topJournals,
      topAuthors: topAuthors,
      totalPublications: totalPublications,
      averageCitationCount: averageCitationCount,
      mostActiveYear: mostActiveYear,
      topJournal: topJournal,
      topAuthor: topAuthor,
      mostInfluentialPaper: mostInfluentialPaper,
    );
  }

  // Apply filter
  Future<void> updateFilter(SearchFilter newFilter) async {
    _filter = newFilter;
    if (_currentTopic.isNotEmpty) {
      await searchWithFilter(_currentTopic, null, resetPage: true);
    }
    notifyListeners();
  }

  Future<void> searchWithFilter(
    String keyword,
    TopicSuggestion? topic, {
    bool resetPage = true,
  }) async {
    if (resetPage) {
      _currentPage = 1;
      _publications = [];
      _isLoading = true;
      _isLoadingMore = false;
    } else {
      _isLoadingMore = true;
    }

    _errorMessage = null;
    notifyListeners();

    try {
      // Khi user bấm filter hoặc chọn topic mới.
      // Khi loadMore() thì topic null và phải giữ topic đã resolve trước đó.
      final resolvedTopic = topic ?? _selectedTopic;

      // Chỉ resolve từ OpenAlex khi app chưa có topic đã chọn.
      final effectiveTopic =
          resolvedTopic ?? await _resolveTopic(keyword, null);

      _selectedTopic = effectiveTopic;

      _currentTopic = effectiveTopic?.displayName ?? keyword.trim();
      _currentTopicId = effectiveTopic?.id.replaceAll(
        'https://openalex.org/',
        '',
      );

      _selectedTopicViewModel?.setTopic(
        _currentTopic,
        suggestion: effectiveTopic,
      );

      final topicIds = _currentTopicId == null
          ? <String>[]
          : <String>[_currentTopicId!];

      final params = _filter.toQueryParams(_currentTopic, topicIds);
      params['page'] = _currentPage.toString();

      final (total, result) = await _openAlexService.searchWithFilter(params);

      _totalResults = total;

      if (resetPage) {
        _publications = result;
      } else {
        final existingIds = _publications
            .map((publication) => publication.id)
            .toSet();

        _publications.addAll(
          result.where((publication) => existingIds.add(publication.id)),
        );
      }

      _hasMore = result.length >= 50;
      _currentPage++;
    } catch (_) {
      if (resetPage) {
        _currentTopicId = null;
        _selectedTopic = null;
        _publications = [];
        _totalResults = 0;
      }

      _errorMessage = 'Cannot load publications. Please try again.';
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoading) return;
    await searchWithFilter(_currentTopic, null, resetPage: false);
  }

  void resetFilter() {
    _filter = const SearchFilter();
    notifyListeners();
  }

  // HISTORY - SUGGESTION
  Future<void> loadHistory() async {
    _searchHistory = await _historyService.getHistory();
    notifyListeners();
  }

  Future<void> onQueryChanged(String query) async {
    if (query.trim().isEmpty) {
      _conceptSuggestions = [];
      _showSuggestions = true;
      notifyListeners();
      return;
    }
    _showSuggestions = true;
    _conceptSuggestions = await _suggestionService.fetchTopicSuggestions(query);
    notifyListeners();
  }

  void hideSuggestions() {
    _showSuggestions = false;
    notifyListeners();
  }

  Future<void> removeHistory(String keyword) async {
    await _historyService.removeHistory(keyword);
    _searchHistory = await _historyService.getHistory();
    notifyListeners();
  }

  Future<void> clearHistory() async {
    await _historyService.clearHistory();
    _searchHistory = [];
    notifyListeners();
  }
}
