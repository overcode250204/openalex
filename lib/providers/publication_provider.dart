import 'package:flutter/material.dart';
import 'package:openalex/models/search_filter.dart';
import 'package:openalex/services/history_service.dart';
import 'package:openalex/services/suggestion_service.dart';

import '../models/publication.dart';
import '../models/trend_report_snapshot.dart';
import '../services/openalex_service.dart';

class PublicationProvider extends ChangeNotifier {
  final OpenAlexService _openAlexService;

  PublicationProvider(this._openAlexService);

  List<Publication> _publications = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _currentTopic = '';
  SearchFilter _filter = const SearchFilter();
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  int _totalResults = 0;
  final _historyService = SearchHistoryService();
  final _suggestionService = SuggestionService();

  List<String> _searchHistory = [];
  List<Map<String, String>> _conceptSuggestions = [];
  List<String> _relatedKeywords = [];
  bool _showSuggestions = false;

  List<Publication> get publications => _publications;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  String get currentTopic => _currentTopic;

  SearchFilter get filter => _filter;
  bool get hasMore => _hasMore;
  int get totalResults => _totalResults;
  bool get isLoadingMore => _isLoadingMore;
  List<String> get searchHistory => _searchHistory;
  List<Map<String, String>> get conceptSuggestions => _conceptSuggestions;
  List<String> get relatedKeywords => _relatedKeywords;
  bool get showSuggestions => _showSuggestions;


// Search By Topic
  Future<void> searchPublications({
    required String keyword,
    int? fromYear,
    int? toYear,
  }) async {
    if (keyword.trim().isEmpty) {
      _errorMessage = 'Please enter a research topic.';
      notifyListeners();
      return;
    }
    //Save search history
    _showSuggestions = false;
    await _historyService.addHistory(keyword);
    _searchHistory = await _historyService.getHistory();

    _isLoading = true;
    _errorMessage = null;
    _currentTopic = keyword.trim();
    notifyListeners();

    try {
      _publications = await _openAlexService.searchPublications(
        keyword: keyword,
        fromYear: fromYear,
        toYear: toYear,
      );
    } catch (error) {
      _publications = [];
      _errorMessage = 'Cannot load publications. Please try again.';
    } finally {
      _isLoading = false;
      // fetch related keyword
       _relatedKeywords = await _suggestionService.fetchRelatedKeywords(keyword);
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
  Future<void> updateFilter(SearchFilter newFilter) async{
    _filter = newFilter;
    if(_currentTopic.isNotEmpty){
      searchWithFilter(_currentTopic, resetPage: true);
    }
    notifyListeners();
  }

  Future<void> searchWithFilter(String keyword, {bool resetPage = true}) async {
    if(resetPage){
      _currentPage = 1;
      _publications = [];
      _isLoading = true;
    }
    if(!resetPage){
      _isLoadingMore = true;
    }

    _currentTopic = keyword;
    _errorMessage = null;
    notifyListeners();

    try{
      final params = _filter.toQueryParams(keyword);
      params['page'] = _currentPage.toString();
      int total;
      List<Publication> result;
      
      ( total, result ) = await _openAlexService.searchWithFilter(params);
        _totalResults = total;
        if(resetPage){
          _publications = result;
        }else{
          _publications.addAll(result);
        }

        _hasMore = result.length >= 50;
        _currentPage++;
      
    } catch (_){
       _publications = [];
      _errorMessage = 'Cannot load publications. Please try again.';
    }
    finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if(!_hasMore || _isLoading) return;
    await searchWithFilter(_currentTopic, resetPage: false);
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
    _conceptSuggestions = await _suggestionService.fetchConceptSuggestions(query);
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
