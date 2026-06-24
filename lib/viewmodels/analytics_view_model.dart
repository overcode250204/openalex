import 'package:flutter/material.dart';

import '../models/analytics/topic_analytics.dart';
import '../models/publication/publication.dart';
import '../models/search/search_filter.dart';
import '../services/analytics_service.dart';

class AuthorImpact {
  final String name;
  final int paperCount;
  final int totalCitations;

  const AuthorImpact({
    required this.name,
    required this.paperCount,
    required this.totalCitations,
  });
}

class AnalyticsViewModel extends ChangeNotifier {
  final AnalyticsService _analyticsService;

  AnalyticsViewModel({AnalyticsService? analyticsService})
    : _analyticsService = analyticsService ?? AnalyticsService();

  TopicAnalytics _result = TopicAnalytics.empty();
  bool _isLoading = false;
  String? _error;
  String? _loadedSignature;
  String? _inFlightSignature;
  int _requestVersion = 0;

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasLoaded => _loadedSignature != null;
  bool get hasData =>
      _result.totalWorks > 0 ||
      _result.publicationTrend.isNotEmpty ||
      _result.topKeywords.isNotEmpty ||
      _result.mostInfluentialPaper != null;

  // --- API-backed charts (all papers in search) ---

  // Chart 2: Publications per year across ALL matching papers
  Map<int, int> get publicationTrend => _result.publicationTrend;

  // Year-over-year growth: most recent complete year vs the one before it
  double get publicationGrowthRate {
    final trend = _result.publicationTrend;
    if (trend.length < 2) return 0;

    final currentYear = DateTime.now().year;
    final completeYears =
        trend.entries.where((e) => e.key < currentYear).toList()
          ..sort((a, b) => a.key.compareTo(b.key));

    if (completeYears.length < 2) return 0;

    final prev = completeYears[completeYears.length - 2].value.toDouble();
    final last = completeYears[completeYears.length - 1].value.toDouble();
    if (prev == 0) return 0;
    return ((last - prev) / prev) * 100;
  }

  // The most recent complete year used for growth rate
  int? get latestCompleteYear {
    final currentYear = DateTime.now().year;
    final years =
        _result.publicationTrend.keys.where((y) => y < currentYear).toList()
          ..sort();
    return years.isNotEmpty ? years.last : null;
  }

  // Chart 3: Top keywords (concepts) across ALL matching papers
  Map<String, int> get topKeywords => _result.topKeywords;

  // Chart 10: Institution ranking across ALL matching papers
  Map<String, int> get institutionRanking => _result.institutionRanking;

  // Chart 12: Country output across ALL matching papers
  Map<String, int> get countryOutput => _result.countryOutput;

  // --- Full-dataset summary stats (group_by / meta-backed) ---

  // Total number of works matching the search across the whole dataset.
  int get totalWorks => _result.totalWorks;

  // Null citation counts returned by OpenAlex are consistently treated as 0.
  double? get averageCitations => _result.averageCitations;
  String get averageCitationsLabel =>
      'Average Citations (OpenAlex grouped sample)';

  // Year with the most publications across the full dataset.
  int? get mostActiveYear {
    if (_result.publicationTrend.isEmpty) return null;
    return _result.publicationTrend.entries
        .reduce(
          (a, b) => a.value > b.value || (a.value == b.value && a.key > b.key)
              ? a
              : b,
        )
        .key;
  }

  // Journal (source) with the most publications across the full dataset.
  String? get topJournalName =>
      _result.topJournals.isEmpty ? null : _result.topJournals.keys.first;

  // Most common research keyword (concept) across the full dataset.
  String? get topKeywordName =>
      _result.topKeywords.isEmpty ? null : _result.topKeywords.keys.first;

  // Author with the most publications across the full dataset.
  // Skips junk OpenAlex author entities whose display name is a bare URL.
  String? get topAuthorName {
    for (final name in _result.topAuthors.keys) {
      if (!_looksLikeUrl(name)) return name;
    }
    return null;
  }

  static bool _looksLikeUrl(String value) {
    final v = value.trim().toLowerCase();
    return v.startsWith('http') ||
        v.startsWith('www.') ||
        v.contains('://') ||
        RegExp(r'\.(com|org|net|io|edu|gov)\b').hasMatch(v);
  }

  // Title of the most-cited paper across the full dataset.
  InfluentialPaperSummary? get mostInfluentialPaper =>
      _result.mostInfluentialPaper;

  String? get mostCitedTitle => mostInfluentialPaper?.title;

  // Citation count of the most-cited paper across the full dataset.
  int get mostCitedCount => mostInfluentialPaper?.citedByCount ?? 0;

  // API-backed bounded sample; never derived from HomeViewModel pagination.
  List<AuthorImpact> get authorImpact => _result.authorImpact
      .map(
        (author) => AuthorImpact(
          name: author.name,
          paperCount: author.paperCount,
          totalCitations: author.totalCitations,
        ),
      )
      .toList();

  /// Called by HomeViewModel after each search/loadMore.
  /// Fetches group_by analytics for the full dataset and updates author impact.
  Future<void> fetchAnalytics(
    String keyword,
    SearchFilter filter,
    List<Publication> ignoredPaginatedPublications, {
    String? topicId,
    Map<int, int> fallbackTrend = const {},
    bool includeCharts = true,
    bool forceRefresh = false,
  }) async {
    final signature = [
      topicId ?? '',
      keyword.trim(),
      filter.yearFrom ?? '',
      filter.yearTo ?? '',
      filter.isOpenAccess ?? '',
      filter.language ?? '',
      filter.documentType.name,
      filter.sortOption.name,
      includeCharts,
    ].join('|');

    if (!forceRefresh &&
        (signature == _loadedSignature || signature == _inFlightSignature)) {
      return;
    }

    _inFlightSignature = signature;
    _loadedSignature = null;
    final requestVersion = ++_requestVersion;
    _isLoading = true;
    _error = null;
    _result = TopicAnalytics.empty();
    notifyListeners();

    try {
      final result = includeCharts
          ? await _analyticsService.fetchAll(keyword, filter, topicId: topicId)
          : await _analyticsService.fetchSummary(
              keyword,
              filter,
              topicId: topicId,
            );
      if (requestVersion != _requestVersion) return;
      final effectiveTrend = result.publicationTrend.isEmpty
          ? fallbackTrend
          : result.publicationTrend;
      _result = TopicAnalytics(
        publicationTrend: effectiveTrend,
        topKeywords: result.topKeywords,
        institutionRanking: result.institutionRanking,
        countryOutput: result.countryOutput,
        topJournals: result.topJournals,
        topAuthors: result.topAuthors,
        totalWorks: result.totalWorks > 0
            ? result.totalWorks
            : effectiveTrend.values.fold<int>(0, (sum, count) => sum + count),
        analyzedWorks: result.analyzedWorks,
        totalCitations: result.totalCitations,
        mostInfluentialPaper: result.mostInfluentialPaper,
        authorImpact: result.authorImpact,
      );
      _loadedSignature = signature;
    } catch (e) {
      if (requestVersion != _requestVersion) return;
      _error = e.toString();
      _result = TopicAnalytics(
        publicationTrend: fallbackTrend,
        topKeywords: const {},
        institutionRanking: const {},
        countryOutput: const {},
        totalWorks: fallbackTrend.values.fold<int>(
          0,
          (sum, count) => sum + count,
        ),
      );
    } finally {
      if (requestVersion == _requestVersion) {
        _inFlightSignature = null;
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void clear() {
    _requestVersion++;
    _result = TopicAnalytics.empty();
    _isLoading = false;
    _error = null;
    _loadedSignature = null;
    _inFlightSignature = null;
    notifyListeners();
  }
}
