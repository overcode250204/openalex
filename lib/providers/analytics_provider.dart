import 'package:flutter/material.dart';
import '../models/publication.dart';
import '../models/search_filter.dart';
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

class AnalyticsProvider extends ChangeNotifier {
  final AnalyticsService _analyticsService;

  AnalyticsProvider({AnalyticsService? analyticsService})
      : _analyticsService = analyticsService ?? AnalyticsService();

  AnalyticsResult _result = AnalyticsResult.empty();
  List<Publication> _publications = [];
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasData => _result.publicationTrend.isNotEmpty ||
      _result.topKeywords.isNotEmpty ||
      _publications.isNotEmpty;

  // --- API-backed charts (all papers in search) ---

  // Chart 2: Publications per year across ALL matching papers
  Map<int, int> get publicationTrend => _result.publicationTrend;

  // Year-over-year growth: most recent complete year vs the one before it
  double get publicationGrowthRate {
    final trend = _result.publicationTrend;
    if (trend.length < 2) return 0;

    final currentYear = DateTime.now().year;
    final completeYears = trend.entries
        .where((e) => e.key < currentYear)
        .toList()
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
    final years = _result.publicationTrend.keys
        .where((y) => y < currentYear)
        .toList()
      ..sort();
    return years.isNotEmpty ? years.last : null;
  }

  // Chart 3: Top keywords (concepts) across ALL matching papers
  Map<String, int> get topKeywords => _result.topKeywords;

  // Chart 10: Institution ranking across ALL matching papers
  Map<String, int> get institutionRanking => _result.institutionRanking;

  // Chart 12: Country output across ALL matching papers
  Map<String, int> get countryOutput => _result.countryOutput;

  // --- Computed from loaded papers (no group_by equivalent) ---

  // Chart 8: Author impact (scatter) — from 50 loaded papers
  List<AuthorImpact> get authorImpact {
    final Map<String, _AuthorAccumulator> accum = {};
    for (final pub in _publications) {
      for (final author in pub.authors) {
        final entry = accum.putIfAbsent(author, () => _AuthorAccumulator(author));
        entry.paperCount++;
        entry.totalCitations += pub.citedByCount;
      }
    }
    final list = accum.values
        .map((a) => AuthorImpact(
              name: a.name,
              paperCount: a.paperCount,
              totalCitations: a.totalCitations,
            ))
        .toList()
      ..sort((a, b) => b.totalCitations.compareTo(a.totalCitations));
    return list.take(30).toList();
  }

  /// Called by PublicationProvider after each search/loadMore.
  /// Fetches group_by analytics for the full dataset and updates author impact.
  Future<void> fetchAnalytics(
    String keyword,
    SearchFilter filter,
    List<Publication> publications,
  ) async {
    _publications = publications;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _result = await _analyticsService.fetchAll(keyword, filter);
    } catch (e) {
      _error = e.toString();
      _result = AnalyticsResult.empty();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _result = AnalyticsResult.empty();
    _publications = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}

class _AuthorAccumulator {
  final String name;
  int paperCount = 0;
  int totalCitations = 0;

  _AuthorAccumulator(this.name);
}
