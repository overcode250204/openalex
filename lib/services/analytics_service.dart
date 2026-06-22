import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/analytics/topic_analytics.dart';
import '../models/search/search_filter.dart';

class _WorksSummary {
  final int total;
  final InfluentialPaperSummary? mostInfluentialPaper;

  const _WorksSummary({
    required this.total,
    required this.mostInfluentialPaper,
  });
}

class _CitationStats {
  final int analyzedWorks;
  final int totalCitations;

  const _CitationStats({
    required this.analyzedWorks,
    required this.totalCitations,
  });
}

class AnalyticsService {
  static const _mailto = 'trandinhbao222@gmail.com';

  final http.Client _client;
  final String? _apiKey;

  AnalyticsService({http.Client? client, String? apiKey})
    : _client = client ?? http.Client(),
      _apiKey = apiKey?.trim().isEmpty == true ? null : apiKey?.trim();

  Future<Map<String, dynamic>> _getJson(Map<String, String> params) async {
    final uri = Uri.https('api.openalex.org', '/works', {
      ...params,
      if (_apiKey != null) 'api_key': _apiKey!,
    });
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception(
        'OpenAlex analytics request failed with status '
        '${response.statusCode}',
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Map<String, String> _buildBaseParams(
    String keyword,
    SearchFilter filter,
    String? topicId,
  ) {
    final normalizedTopicId = topicId
        ?.replaceAll('https://openalex.org/', '')
        .trim();
    final filters = <String>[
      if (normalizedTopicId != null && normalizedTopicId.isNotEmpty)
        'topics.id:$normalizedTopicId',
      if (filter.yearFrom != null)
        'from_publication_date:${filter.yearFrom}-01-01',
      if (filter.yearTo != null) 'to_publication_date:${filter.yearTo}-12-31',
      if (filter.isOpenAccess != null) 'is_oa:${filter.isOpenAccess}',
      if (filter.language?.trim().isNotEmpty == true)
        'language:${filter.language}',
      if (filter.documentType != DocumentType.all)
        'type:${filter.documentType.name}',
    ];
    final params = <String, String>{
      if (normalizedTopicId == null || normalizedTopicId.isEmpty)
        'search': keyword.trim(),
      if (filters.isNotEmpty) 'filter': filters.join(','),
      'mailto': _mailto,
    };
    return params;
  }

  Future<Map<String, int>> _fetchGroupBy(
    Map<String, String> baseParams,
    String groupByField,
  ) async {
    final body = await _getJson({...baseParams, 'group_by': groupByField});
    final groups = body['group_by'] as List<dynamic>? ?? [];

    return Map.fromEntries(
      groups
          .map((item) {
            final group = item as Map<String, dynamic>;
            final displayName =
                group['key_display_name']?.toString() ??
                group['key']?.toString() ??
                '';
            return MapEntry(displayName, (group['count'] as num? ?? 0).toInt());
          })
          .where((entry) => entry.key.trim().isNotEmpty),
    );
  }

  Future<_WorksSummary> _fetchTopWork(Map<String, String> baseParams) async {
    final body = await _getJson({
      ...baseParams,
      'sort': 'cited_by_count:desc',
      'per_page': '1',
      'select': 'id,doi,display_name,publication_year,cited_by_count',
    });
    final meta = body['meta'] as Map<String, dynamic>? ?? const {};
    final results = body['results'] as List<dynamic>? ?? [];
    final total = (meta['count'] as num? ?? 0).toInt();
    InfluentialPaperSummary? mostInfluentialPaper;

    if (results.isNotEmpty) {
      final work = results.first as Map<String, dynamic>;
      mostInfluentialPaper = InfluentialPaperSummary(
        id: work['id']?.toString() ?? '',
        title: work['display_name']?.toString() ?? 'No title',
        citedByCount: (work['cited_by_count'] as num? ?? 0).toInt(),
        publicationYear: (work['publication_year'] as num?)?.toInt(),
        doi: work['doi']?.toString(),
      );
    }

    return _WorksSummary(
      total: total,
      mostInfluentialPaper: mostInfluentialPaper,
    );
  }

  Future<_CitationStats> _fetchCitationStats(
    Map<String, String> baseParams,
  ) async {
    var cursor = '*';
    var analyzedWorks = 0;
    var totalCitations = 0;
    final seenCursors = <String>{};

    while (cursor.isNotEmpty && seenCursors.add(cursor)) {
      final body = await _getJson({
        ...baseParams,
        'group_by': 'cited_by_count',
        'per_page': '100',
        'cursor': cursor,
      });
      final groups = body['group_by'] as List<dynamic>? ?? [];
      for (final item in groups) {
        final group = item as Map<String, dynamic>;
        final citationCount = int.tryParse(group['key']?.toString() ?? '') ?? 0;
        final workCount = (group['count'] as num? ?? 0).toInt();
        analyzedWorks += workCount;
        totalCitations += citationCount * workCount;
      }

      final meta = body['meta'] as Map<String, dynamic>? ?? const {};
      final nextCursor = meta['next_cursor']?.toString();
      if (groups.isEmpty || nextCursor == null || nextCursor.isEmpty) break;
      cursor = nextCursor;
    }

    return _CitationStats(
      analyzedWorks: analyzedWorks,
      totalCitations: totalCitations,
    );
  }

  Future<List<AuthorImpactSummary>> _fetchAuthorImpactSample(
    Map<String, String> baseParams,
  ) async {
    final body = await _getJson({
      ...baseParams,
      'sort': 'cited_by_count:desc',
      'per-page': '200',
      'select': 'authorships,cited_by_count',
    });
    final accumulators = <String, ({int papers, int citations})>{};
    for (final work in body['results'] as List<dynamic>? ?? const []) {
      final json = work as Map<String, dynamic>;
      final citations = (json['cited_by_count'] as num? ?? 0).toInt();
      for (final authorship
          in json['authorships'] as List<dynamic>? ?? const []) {
        final author =
            (authorship as Map<String, dynamic>)['author']
                as Map<String, dynamic>?;
        final name = author?['display_name']?.toString().trim() ?? '';
        if (name.isEmpty) continue;
        final current = accumulators[name] ?? (papers: 0, citations: 0);
        accumulators[name] = (
          papers: current.papers + 1,
          citations: current.citations + citations,
        );
      }
    }
    final result =
        accumulators.entries
            .map(
              (entry) => AuthorImpactSummary(
                name: entry.key,
                paperCount: entry.value.papers,
                totalCitations: entry.value.citations,
              ),
            )
            .toList()
          ..sort((a, b) => b.totalCitations.compareTo(a.totalCitations));
    return result.take(30).toList();
  }

  Future<T?> _tryFetch<T>(Future<T> request) async {
    try {
      return await request;
    } catch (_) {
      return null;
    }
  }

  Future<TopicAnalytics> fetchSummary(
    String keyword,
    SearchFilter filter, {
    String? topicId,
  }) async {
    final baseParams = _buildBaseParams(keyword, filter, topicId);
    final results = await Future.wait<Object?>([
      _tryFetch(_fetchGroupBy(baseParams, 'publication_year')),
      _tryFetch(_fetchGroupBy(baseParams, 'primary_location.source.id')),
      _tryFetch(_fetchGroupBy(baseParams, 'authorships.author.id')),
      _tryFetch(_fetchTopWork(baseParams)),
      _tryFetch(_fetchCitationStats(baseParams)),
    ]);

    if (results.every((result) => result == null)) {
      throw Exception('Unable to load OpenAlex topic analytics.');
    }

    final yearGroups = results[0] as Map<String, int>? ?? const {};
    final publicationTrend = <int, int>{};
    for (final entry in yearGroups.entries) {
      final year = int.tryParse(entry.key);
      if (year != null) {
        publicationTrend[year] = entry.value;
      }
    }
    final sortedTrend = Map.fromEntries(
      publicationTrend.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    final worksSummary = results[3] as _WorksSummary?;
    final citationStats = results[4] as _CitationStats?;
    final totalWorks =
        worksSummary?.total ??
        publicationTrend.values.fold<int>(0, (sum, count) => sum + count);

    return TopicAnalytics(
      publicationTrend: sortedTrend,
      topKeywords: const {},
      institutionRanking: const {},
      countryOutput: const {},
      topJournals: results[1] as Map<String, int>? ?? const {},
      topAuthors: results[2] as Map<String, int>? ?? const {},
      totalWorks: totalWorks,
      analyzedWorks: citationStats?.analyzedWorks ?? 0,
      totalCitations: citationStats?.totalCitations ?? 0,
      mostInfluentialPaper: worksSummary?.mostInfluentialPaper,
    );
  }

  Future<TopicAnalytics> fetchAll(
    String keyword,
    SearchFilter filter, {
    String? topicId,
  }) async {
    final baseParams = _buildBaseParams(keyword, filter, topicId);
    final results = await Future.wait<Object?>([
      fetchSummary(keyword, filter, topicId: topicId),
      _tryFetch(_fetchGroupBy(baseParams, 'concepts.id')),
      _tryFetch(_fetchGroupBy(baseParams, 'authorships.institutions.id')),
      _tryFetch(_fetchGroupBy(baseParams, 'authorships.countries')),
      _tryFetch(_fetchAuthorImpactSample(baseParams)),
    ]);
    final summary = results[0] as TopicAnalytics;

    return TopicAnalytics(
      publicationTrend: summary.publicationTrend,
      topKeywords: results[1] as Map<String, int>? ?? const {},
      institutionRanking: results[2] as Map<String, int>? ?? const {},
      countryOutput: results[3] as Map<String, int>? ?? const {},
      topJournals: summary.topJournals,
      topAuthors: summary.topAuthors,
      totalWorks: summary.totalWorks,
      analyzedWorks: summary.analyzedWorks,
      totalCitations: summary.totalCitations,
      mostInfluentialPaper: summary.mostInfluentialPaper,
      authorImpact: results[4] as List<AuthorImpactSummary>? ?? const [],
    );
  }
}
