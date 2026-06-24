import 'package:flutter/material.dart';
import 'package:openalex/models/search/search_filter.dart';
import 'package:openalex/models/topic/topic.dart';
import 'package:openalex/services/history_service.dart';
import 'package:openalex/services/suggestion_service.dart';
import 'package:openalex/viewmodels/selected_topic_view_model.dart';

import '../models/publication/publication.dart';
import '../models/trend/trend_report_snapshot.dart';
import '../services/analytics/app_analytics_service.dart';
import '../services/analytics/no_op_analytics_service.dart';
import '../services/openalex_service.dart';

class TopicResolutionResult {
  final String topicName;
  final List<String> topicIds;
  final TopicSuggestion? suggestion;

  const TopicResolutionResult({
    required this.topicName,
    required this.topicIds,
    required this.suggestion,
  });

  String? get topicId => topicIds.isNotEmpty ? topicIds.first : null;
}

class HomeViewModel extends ChangeNotifier {
  final OpenAlexService _openAlexService;
  final SearchHistoryService _historyService;
  final SuggestionService _suggestionService;
  final SelectedTopicViewModel? _selectedTopicViewModel;
  final AppAnalyticsService _analyticsService;

  HomeViewModel(
    this._openAlexService, {
    SearchHistoryService? historyService,
    SuggestionService? suggestionService,
    SelectedTopicViewModel? selectedTopicViewModel,
    AppAnalyticsService analyticsService = const NoOpAnalyticsService(),
  }) : _historyService = historyService ?? SearchHistoryService(),
       _suggestionService = suggestionService ?? SuggestionService(),
       _selectedTopicViewModel = selectedTopicViewModel,
       _analyticsService = analyticsService;

  List<Publication> _publications = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _currentTopic = '';
  String? _currentTopicId;
  List<String> _currentTopicIds = [];

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
  int _searchRequestVersion = 0;

  List<Publication> get publications => _publications;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  String get currentTopic => _currentTopic;
  String? get currentTopicId => _currentTopicId;
  List<String> get currentTopicIds => List.unmodifiable(_currentTopicIds);
  TopicSuggestion? get selectedTopic => _selectedTopic;

  SearchFilter get filter => _filter;
  bool get hasMore => _hasMore;
  int get totalResults => _totalResults;
  bool get isLoadingMore => _isLoadingMore;
  List<String> get searchHistory => _searchHistory;
  List<TopicSuggestion> get conceptSuggestions => _conceptSuggestions;
  List<String> get relatedKeywords => _relatedKeywords;
  bool get showSuggestions => _showSuggestions;

  Future<TopicSuggestion?> resolveTopicForSearch(
    String keyword, {
    TopicSuggestion? selectedTopic,
  }) async {
    if (selectedTopic != null) {
      return selectedTopic;
    }

    final normalizedKeyword = _normalizeTopicText(keyword);
    if (normalizedKeyword.isEmpty) return null;

    final suggestions = await _suggestionService.fetchTopicSuggestions(keyword);

    if (suggestions.isEmpty) return null;

    for (final suggestion in suggestions) {
      if (_normalizeTopicText(suggestion.displayName) == normalizedKeyword) {
        return suggestion;
      }
    }

    final topSuggestion = suggestions.first;
    if (_isHighConfidenceTopicMatch(
      keyword: keyword,
      suggestion: topSuggestion,
      nextSuggestion: suggestions.length > 1 ? suggestions[1] : null,
    )) {
      return topSuggestion;
    }

    return null;
  }

  String _normalizeTopicText(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _isHighConfidenceTopicMatch({
    required String keyword,
    required TopicSuggestion suggestion,
    TopicSuggestion? nextSuggestion,
  }) {
    final normalizedKeyword = _normalizeTopicText(keyword);
    final normalizedSuggestion = _normalizeTopicText(suggestion.displayName);

    if (normalizedKeyword.isEmpty || normalizedSuggestion.isEmpty) {
      return false;
    }

    if (normalizedKeyword == normalizedSuggestion) {
      return true;
    }

    if (normalizedKeyword.length >= 4 &&
        normalizedSuggestion.contains(normalizedKeyword)) {
      return true;
    }

    if (normalizedSuggestion.length >= 4 &&
        normalizedKeyword.contains(normalizedSuggestion)) {
      return true;
    }

    final suggestionTokens = normalizedSuggestion
        .split(' ')
        .where((token) => token.isNotEmpty)
        .toList();
    final keywordTokens = normalizedKeyword
        .split(' ')
        .where((token) => token.isNotEmpty)
        .toList();

    final abbreviation = suggestionTokens
        .where((token) => token.isNotEmpty)
        .map((token) => token[0])
        .join();
    if (normalizedKeyword.replaceAll(' ', '') == abbreviation &&
        abbreviation.length >= 2) {
      return true;
    }

    final meaningfulKeywordTokens = keywordTokens
        .where((token) => token.length >= 3)
        .toList();
    if (meaningfulKeywordTokens.isNotEmpty &&
        meaningfulKeywordTokens.every(suggestionTokens.contains)) {
      return true;
    }

    final overlapCount = meaningfulKeywordTokens
        .where(suggestionTokens.contains)
        .length;
    final overlapRatio = meaningfulKeywordTokens.isEmpty
        ? 0.0
        : overlapCount / meaningfulKeywordTokens.length;
    final clearlyDominant =
        nextSuggestion == null ||
        suggestion.workCount >= nextSuggestion.workCount * 2;

    return overlapRatio >= 0.6 && clearlyDominant;
  }

  String _normalizeTopicId(String topicId) {
    return topicId.replaceAll('https://openalex.org/', '');
  }

  TopicResolutionResult _resolutionFrom(
    String keyword,
    TopicSuggestion? resolvedTopic,
  ) {
    final topicIds = resolvedTopic == null
        ? <String>[]
        : [_normalizeTopicId(resolvedTopic.id)];

    return TopicResolutionResult(
      topicName: resolvedTopic?.displayName ?? keyword.trim(),
      topicIds: topicIds,
      suggestion: resolvedTopic,
    );
  }

  void _commitAnalyzedTopic(TopicResolutionResult result) {
    _selectedTopic = result.suggestion;
    _currentTopic = result.topicName;
    _currentTopicId = result.topicId;
    _currentTopicIds = result.topicIds;

    _selectedTopicViewModel?.setTopic(
      _currentTopic,
      suggestion: result.suggestion,
    );
  }

  void _clearAnalyzedTopicIdForNewSearch() {
    _selectedTopic = null;
    _currentTopicId = null;
    _currentTopicIds = [];
  }

  Future<TopicResolutionResult> resolveAndCommitAnalyzedTopic(
    String keyword, {
    TopicSuggestion? selectedTopic,
    required int requestVersion,
  }) async {
    final resolvedTopic = await resolveTopicForSearch(
      keyword,
      selectedTopic: selectedTopic,
    );
    
    TopicResolutionResult result;
    if (resolvedTopic != null) {
      result = _resolutionFrom(keyword, resolvedTopic);
    } else {
      final topicIds = await _openAlexService.getTopicIdsFromKeyword(keyword.trim());
      result = TopicResolutionResult(
        topicName: keyword.trim(),
        topicIds: topicIds,
        suggestion: null,
      );
    }

    if (requestVersion == _searchRequestVersion) {
      _commitAnalyzedTopic(result);
    }

    return result;
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

    final requestVersion = ++_searchRequestVersion;

    _currentPage = 1;
    _publications = [];
    _totalResults = 0;
    _hasMore = true;
    _isLoadingMore = false;
    _clearAnalyzedTopicIdForNewSearch();

    _showSuggestions = false;
    _isLoading = true;
    _errorMessage = null;

    await _historyService.addHistory(trimmedKeyword);
    _searchHistory = await _historyService.getHistory();

    notifyListeners();

    var hasCommittedResolution = false;

    try {
      final resolution = await resolveAndCommitAnalyzedTopic(
        trimmedKeyword,
        selectedTopic: topic,
        requestVersion: requestVersion,
      );

      if (requestVersion != _searchRequestVersion) return;
      hasCommittedResolution = true;

      final (total, result) = await _openAlexService.searchPublications(
        keyword: resolution.topicName,
        topicIds: resolution.topicIds,
      );

      if (requestVersion != _searchRequestVersion) return;

      _totalResults = total;
      _publications = result;
      _hasMore = result.length >= 50;

      // Page đầu tiên xong, lần loadMore tiếp theo phải load page 2.
      _currentPage = 2;

      await _logSearchTopic(
        trimmedKeyword,
        resultCount: total,
        searchSource: topic == null ? 'manual' : 'suggestion',
      );
    } catch (_) {
      if (requestVersion != _searchRequestVersion) return;
      if (!hasCommittedResolution) {
        _currentTopicId = null;
        _currentTopicIds = [];
        _selectedTopic = null;
      }
      _publications = [];
      _totalResults = 0;
      _errorMessage = 'Cannot load publications. Please try again.';
    } finally {
      if (requestVersion == _searchRequestVersion) {
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
      if (topic != null) {
        final result = _resolutionFrom(keyword, topic);
        _commitAnalyzedTopic(result);
      } else if (_currentTopic.trim().isEmpty) {
        final topicIds = await _openAlexService.getTopicIdsFromKeyword(keyword.trim());
        _commitAnalyzedTopic(
          TopicResolutionResult(
            topicName: keyword.trim(),
            topicIds: topicIds,
            suggestion: null,
          ),
        );
      }

      final params = _filter.toQueryParams(_currentTopic, _currentTopicIds);
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

      if (resetPage) {
        await _logSearchTopic(
          keyword,
          resultCount: total,
          searchSource: 'filter',
        );
      }
    } catch (_) {
      _currentTopicId = null;
      _currentTopicIds = [];
      _selectedTopic = null;
      _publications = [];
      _totalResults = 0;

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

  Future<void> _logSearchTopic(
    String keyword, {
    required int resultCount,
    required String searchSource,
  }) async {
    await _analyticsService.logSearchTopic(
      keyword,
      resultCount: resultCount,
      searchSource: searchSource,
      topicId: _currentTopicId,
      hasValidTopic: _currentTopicIds.isNotEmpty ? 1 : 0,
      filterYearFrom: _filter.yearFrom,
      filterYearTo: _filter.yearTo,
      openAccessOnly: _filter.isOpenAccess == true ? 1 : 0,
      sortOption: _filter.sortOption.name,
    );
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
