import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/analytics/topic_analytics.dart';
import '../models/search/search_filter.dart';

class _WorksSummary {
  final int total;
  final int analyzedWorks;
  final int totalCitations;
  final InfluentialPaperSummary? mostInfluentialPaper;

  const _WorksSummary({
    required this.total,
    required this.analyzedWorks,
    required this.totalCitations,
    required this.mostInfluentialPaper,
  });
}

class AnalyticsService {
  static const _mailto = 'trandinhbao222@gmail.com';

  final http.Client _client;

  AnalyticsService({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> _getJson(Map<String, String> params) async {
    final uri = Uri.https('api.openalex.org', '/works', params);
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
    final params = filter.toQueryParams(
      normalizedTopicId == null || normalizedTopicId.isEmpty ? keyword : '',
      normalizedTopicId == null || normalizedTopicId.isEmpty
          ? const []
          : [normalizedTopicId],
    );

    params
      ..remove('per-page')
      ..remove('sort')
      ..['mailto'] = _mailto;

    if (params['search']?.trim().isEmpty ?? false) {
      params.remove('search');
    }
    return params;
  }

  Future<Map<String, int>> _fetchGroupBy(
    Map<String, String> baseParams,
    String groupByField,
  ) async {
    final body = await _getJson({
      ...baseParams,
      'group_by': groupByField,
    });
    final groups = body['group_by'] as List<dynamic>? ?? [];

    return Map.fromEntries(
      groups
          .map((item) {
            final group = item as Map<String, dynamic>;
            final displayName =
                group['key_display_name']?.toString() ??
                group['key']?.toString() ??
                '';
            return MapEntry(
              displayName,
              (group['count'] as num? ?? 0).toInt(),
            );
          })
          .where((entry) => entry.key.trim().isNotEmpty),
    );
  }

  Future<_WorksSummary> _fetchWorksSummary(
    Map<String, String> baseParams,
  ) async {
    var cursor = '*';
    var total = 0;
    var analyzedWorks = 0;
    var totalCitations = 0;
    InfluentialPaperSummary? mostInfluentialPaper;
    final seenCursors = <String>{};

    while (cursor.isNotEmpty && seenCursors.add(cursor)) {
      final body = await _getJson({
        ...baseParams,
        'sort': 'cited_by_count:desc',
        'per-page': '200',
        'cursor': cursor,
        'select': 'id,doi,display_name,publication_year,cited_by_count',
      });
      final meta = body['meta'] as Map<String, dynamic>? ?? const {};
      final results = body['results'] as List<dynamic>? ?? [];

      if (total == 0) {
        total = (meta['count'] as num? ?? 0).toInt();
      }

      for (final item in results) {
        final work = item as Map<String, dynamic>;
        final citedByCount = (work['cited_by_count'] as num? ?? 0).toInt();
        totalCitations += citedByCount;
        analyzedWorks++;

        if (mostInfluentialPaper == null) {
          mostInfluentialPaper = InfluentialPaperSummary(
            id: work['id']?.toString() ?? '',
            title: work['display_name']?.toString() ?? 'No title',
            citedByCount: citedByCount,
            publicationYear: (work['publication_year'] as num?)?.toInt(),
            doi: work['doi']?.toString(),
          );
        }
      }

      final nextCursor = meta['next_cursor']?.toString();
      if (results.isEmpty || nextCursor == null || nextCursor.isEmpty) {
        break;
      }
      cursor = nextCursor;
    }

    return _WorksSummary(
      total: total,
      analyzedWorks: analyzedWorks,
      totalCitations: totalCitations,
      mostInfluentialPaper: mostInfluentialPaper,
    );
  }

  Future<TopicAnalytics> fetchAll(
    String keyword,
    SearchFilter filter, {
    String? topicId,
  }) async {
    final baseParams = _buildBaseParams(keyword, filter, topicId);
    final results = await Future.wait<Object>([
      _fetchGroupBy(baseParams, 'publication_year'),
      _fetchGroupBy(baseParams, 'concepts.id'),
      _fetchGroupBy(baseParams, 'authorships.institutions.id'),
      _fetchGroupBy(baseParams, 'authorships.countries'),
      _fetchGroupBy(baseParams, 'primary_location.source.id'),
      _fetchGroupBy(baseParams, 'authorships.author.id'),
      _fetchWorksSummary(baseParams),
    ]);

    final yearGroups = results[0] as Map<String, int>;
    final publicationTrend = <int, int>{};
    for (final entry in yearGroups.entries) {
      final year = int.tryParse(entry.key);
      if (year != null) {
        publicationTrend[year] = entry.value;
      }
    }
    final sortedTrend = Map.fromEntries(
      publicationTrend.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key)),
    );
    final worksSummary = results[6] as _WorksSummary;

    return TopicAnalytics(
      publicationTrend: sortedTrend,
      topKeywords: results[1] as Map<String, int>,
      institutionRanking: results[2] as Map<String, int>,
      countryOutput: results[3] as Map<String, int>,
      topJournals: results[4] as Map<String, int>,
      topAuthors: results[5] as Map<String, int>,
      totalWorks: worksSummary.total,
      analyzedWorks: worksSummary.analyzedWorks,
      totalCitations: worksSummary.totalCitations,
      mostInfluentialPaper: worksSummary.mostInfluentialPaper,
    );
  }
}
