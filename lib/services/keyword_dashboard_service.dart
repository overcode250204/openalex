import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/keyword/keyword_dashboard_result.dart';
import '../models/keyword/keyword_frequency_stat.dart';
import '../models/keyword/keyword_overview.dart';
import '../models/keyword/keyword_trend_point.dart';
import 'openalex_keyword_service.dart';

class KeywordDashboardService {
  final http.Client _client;
  final DateTime Function() _clock;
  final int candidateLimit;
  final int minimumCurrentCount;
  final int maxConcurrentRequests;

  KeywordDashboardResult? _cachedResult;
  int? _cachedTrendStartYear;
  int? _cachedTrendEndYear;

  KeywordDashboardService({
    http.Client? client,
    DateTime Function()? clock,
    this.candidateLimit = 30,
    this.minimumCurrentCount = 20,
    this.maxConcurrentRequests = 5,
  }) : _client = client ?? http.Client(),
       _clock = clock ?? DateTime.now;

  KeywordDashboardResult? get cachedResult => _cachedResult;

  Future<KeywordDashboardResult> fetchKeywordDashboard({
    DateTime? asOf,
    int? trendStartYear,
    int? trendEndYear,
    bool forceRefresh = false,
  }) async {
    final end = _dateOnly(asOf ?? _clock());
    final currentStart = _oneYearAfter(end, -1);
    final previousEnd = currentStart.subtract(const Duration(days: 1));
    final previousStart = _oneYearAfter(previousEnd, -1);
    final endYear = trendEndYear ?? end.year;
    final startYear = trendStartYear ?? 2011;

    if (!forceRefresh &&
        _cachedResult != null &&
        _cachedTrendStartYear == startYear &&
        _cachedTrendEndYear == endYear) {
      return _cachedResult!;
    }

    var candidates = await _fetchRecentCandidates(currentStart, end);
    if (candidates.isEmpty) {
      candidates = await _fetchFallbackCandidates();
      await _populateCurrentCounts(candidates, currentStart, end);
    }

    await _populatePreviousCounts(candidates, previousStart, previousEnd);

    final eligible = candidates
        .where(
          (candidate) => candidate.currentPeriodCount >= minimumCurrentCount,
        )
        .toList();

    final maxCount = eligible.fold<int>(
      0,
      (current, item) => math.max(current, item.currentPeriodCount),
    );
    final scored =
        eligible
            .map(
              (item) => item.copyWith(
                hotScore: calculateHotScore(
                  currentPeriodCount: item.currentPeriodCount,
                  maxCurrentPeriodCount: maxCount,
                  growthRate: item.growthRate,
                ),
              ),
            )
            .toList()
          ..sort((a, b) => b.hotScore.compareTo(a.hotScore));

    final hottest = scored.isEmpty ? null : scored.first;
    final frequent = [...scored]
      ..sort((a, b) => b.currentPeriodCount.compareTo(a.currentPeriodCount));
    final trending = [...scored]
      ..sort((a, b) => b.growthRate.compareTo(a.growthRate));

    final topForTrends = scored.take(3).toList();
    final trendSeries = <String, List<KeywordTrendPoint>>{};
    await _runBounded(topForTrends, (keyword) async {
      trendSeries[keyword.name] = await fetchKeywordTrend(
        keywordId: keyword.id,
        keywordName: keyword.name,
        startYear: startYear,
        endYear: endYear,
      );
    });

    final fastestGrowth = eligible.isEmpty
        ? 0.0
        : eligible.map((item) => item.growthRate).reduce(math.max);
    final result = KeywordDashboardResult(
      hottestKeyword: hottest,
      mostFrequentKeywords: frequent.take(20).toList(),
      trendingKeywords: trending.take(20).toList(),
      statistics: KeywordFrequencyStat(
        totalKeywordsAnalyzed: candidates.length,
        totalRecentPublications: eligible.fold(
          0,
          (sum, item) => sum + item.currentPeriodCount,
        ),
        hottestKeyword: hottest?.name ?? 'N/A',
        fastestGrowthRate: fastestGrowth,
      ),
      trendSeries: trendSeries,
      currentPeriodStart: currentStart,
      currentPeriodEnd: end,
      previousPeriodStart: previousStart,
      previousPeriodEnd: previousEnd,
      fetchedAt: _clock(),
    );

    _cachedResult = result;
    _cachedTrendStartYear = startYear;
    _cachedTrendEndYear = endYear;
    return result;
  }

  static double calculateGrowthRate(int current, int previous) {
    return ((current - previous) / math.max(previous, 1)) * 100;
  }

  static double calculateHotScore({
    required int currentPeriodCount,
    required int maxCurrentPeriodCount,
    required double growthRate,
  }) {
    if (maxCurrentPeriodCount <= 0) return 0;
    final normalizedVolume = currentPeriodCount / maxCurrentPeriodCount;
    final normalizedGrowth = growthRate.clamp(0, 500) / 500;
    return (normalizedVolume * 0.70) + (normalizedGrowth * 0.30);
  }

  static KeywordStatus classifyStatus(double growthRate) {
    if (growthRate >= 100) return KeywordStatus.hot;
    if (growthRate >= 30) return KeywordStatus.emerging;
    if (growthRate <= -10) return KeywordStatus.declining;
    return KeywordStatus.stable;
  }

  Future<List<_MutableCandidate>> _fetchRecentCandidates(
    DateTime start,
    DateTime end,
  ) async {
    final uri = Uri.https(OpenAlexKeywordService.host, '/works', {
      'filter': _dateFilter(start, end),
      'group_by': 'keywords.id',
      'per-page': candidateLimit.toString(),
      'mailto': OpenAlexKeywordService.mailto,
    });
    final body = await _getJson(uri);
    final groups = body['group_by'] as List<dynamic>? ?? [];
    return groups
        .whereType<Map<String, dynamic>>()
        .map((group) {
          final count = (group['count'] as num? ?? 0).toInt();
          return _MutableCandidate(
            id: _shortId(group['key']?.toString() ?? ''),
            name: group['key_display_name']?.toString() ?? 'Unknown keyword',
            currentPeriodCount: count,
          );
        })
        .where((item) => item.id.isNotEmpty && item.name.trim().isNotEmpty)
        .toList();
  }

  Future<List<_MutableCandidate>> _fetchFallbackCandidates() async {
    // TODO: replace this client-side fallback with backend aggregation at scale.
    final limit = math.min(candidateLimit, 20);
    final uri = Uri.https(OpenAlexKeywordService.host, '/keywords', {
      'sort': 'works_count:desc',
      'per-page': limit.toString(),
      'select': 'id,display_name',
      'mailto': OpenAlexKeywordService.mailto,
    });
    final body = await _getJson(uri);
    final results = body['results'] as List<dynamic>? ?? [];
    return results
        .whereType<Map<String, dynamic>>()
        .map((item) {
          return _MutableCandidate(
            id: _shortId(item['id']?.toString() ?? ''),
            name: item['display_name']?.toString() ?? 'Unknown keyword',
          );
        })
        .where((item) => item.id.isNotEmpty)
        .toList();
  }

  Future<void> _populateCurrentCounts(
    List<_MutableCandidate> candidates,
    DateTime start,
    DateTime end,
  ) {
    return _runBounded(candidates, (candidate) async {
      candidate.currentPeriodCount = await _fetchCount(
        candidate.id,
        start,
        end,
      );
    });
  }

  Future<void> _populatePreviousCounts(
    List<_MutableCandidate> candidates,
    DateTime start,
    DateTime end,
  ) {
    return _runBounded(candidates, (candidate) async {
      candidate.previousPeriodCount = await _fetchCount(
        candidate.id,
        start,
        end,
      );
    });
  }

  Future<int> _fetchCount(
    String keywordId,
    DateTime start,
    DateTime end,
  ) async {
    final uri = Uri.https(OpenAlexKeywordService.host, '/works', {
      'filter': 'keywords.id:$keywordId,${_dateFilter(start, end)}',
      'per-page': '1',
      'select': 'id',
      'mailto': OpenAlexKeywordService.mailto,
    });
    final body = await _getJson(uri);
    final meta = body['meta'] as Map<String, dynamic>?;
    return (meta?['count'] as num? ?? 0).toInt();
  }

  Future<List<KeywordTrendPoint>> fetchKeywordTrend({
    required String keywordId,
    required int startYear,
    required int endYear,
    String? keywordName,
  }) async {
    final uri = Uri.https(OpenAlexKeywordService.host, '/works', {
      'filter':
          'keywords.id:$keywordId,'
          'from_publication_date:$startYear-01-01,'
          'to_publication_date:$endYear-12-31',
      'group_by': 'publication_year',
      'mailto': OpenAlexKeywordService.mailto,
    });
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('OpenAlex request failed (${response.statusCode}).');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final groups = body['group_by'] as List<dynamic>? ?? [];
    final parsed = KeywordTrendPoint.parseGroupBy(groups);
    final normalized = normalizeTrend(parsed, startYear, endYear);

    if (kDebugMode) {
      final label = keywordName ?? keywordId;
      debugPrint('[Keyword trend] keyword=$label');
      debugPrint('[Keyword trend] selected years=$startYear-$endYear');
      debugPrint('[Keyword trend] request=${_maskedUri(uri)}');
      debugPrint('[Keyword trend] raw response=${response.body}');
      debugPrint(
        '[Keyword trend] returned buckets='
        '${parsed.map((point) => '${point.year}:${point.count}').join(', ')}',
      );
      debugPrint(
        '[Keyword trend] chart points='
        '${normalized.map((point) => '${point.year}:${point.count}').join(', ')}',
      );
    }

    return normalized;
  }

  static List<KeywordTrendPoint> normalizeTrend(
    Iterable<KeywordTrendPoint> points,
    int startYear,
    int endYear,
  ) {
    final firstYear = math.min(startYear, endYear);
    final lastYear = math.max(startYear, endYear);
    final byYear = {for (final point in points) point.year: point.count};
    return [
      for (var year = firstYear; year <= lastYear; year++)
        KeywordTrendPoint(year: year, count: byYear[year] ?? 0),
    ];
  }

  static Uri _maskedUri(Uri uri) {
    final params = Map<String, String>.from(uri.queryParameters);
    if (params.containsKey('api_key')) params['api_key'] = '***';
    return uri.replace(queryParameters: params);
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('OpenAlex request failed (${response.statusCode}).');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> _runBounded<T>(
    List<T> items,
    Future<void> Function(T item) action,
  ) async {
    var next = 0;
    Future<void> worker() async {
      while (next < items.length) {
        final index = next++;
        await action(items[index]);
      }
    }

    await Future.wait(
      List.generate(
        math.min(maxConcurrentRequests, items.length),
        (_) => worker(),
      ),
    );
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime.utc(value.year, value.month, value.day);

  static DateTime _oneYearAfter(DateTime value, int years) =>
      DateTime.utc(value.year + years, value.month, value.day);

  static String _dateFilter(DateTime start, DateTime end) =>
      'from_publication_date:${_iso(start)},to_publication_date:${_iso(end)}';

  static String _iso(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static String _shortId(String id) =>
      id.replaceAll('https://openalex.org/', '');
}

class _MutableCandidate {
  final String id;
  final String name;
  int currentPeriodCount;
  int previousPeriodCount = 0;

  _MutableCandidate({
    required this.id,
    required this.name,
    this.currentPeriodCount = 0,
  });

  double get growthRate => KeywordDashboardService.calculateGrowthRate(
    currentPeriodCount,
    previousPeriodCount,
  );

  KeywordOverview copyWith({required double hotScore}) => KeywordOverview(
    id: id,
    name: name,
    currentPeriodCount: currentPeriodCount,
    previousPeriodCount: previousPeriodCount,
    growthRate: growthRate,
    hotScore: hotScore,
    status: KeywordDashboardService.classifyStatus(growthRate),
  );
}
