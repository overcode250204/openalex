import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/journal/journal_topic_rank.dart';
import '../models/publication/publication.dart';

class OpenAlexService {
  static const String mailto = 'trandinhbao222@gmail.com';

  final http.Client _client;

  OpenAlexService({http.Client? client}) : _client = client ?? http.Client();

  Future<(int total, List<Publication> publications)> searchPublications({
    required String keyword,
    int perPage = 50,
    String sort = 'cited_by_count:desc',
    List<String>? topicIds,
  }) async {
    final trimmedKeyword = keyword.trim();

    if (trimmedKeyword.isEmpty && (topicIds == null || topicIds.isEmpty)) {
      return (0, <Publication>[]);
    }

    final Map<String, String> queryParameters = {
      'search': trimmedKeyword,
      'per-page': perPage.toString(),
      'sort': sort,
      'mailto': mailto,
    };

    final filters = <String>[];

    if (topicIds != null && topicIds.isNotEmpty) {
      filters.add('primary_topic.id:${topicIds.join('|')}');
    }

    queryParameters['filter'] = filters.join(',');

    final uri = Uri.https('api.openalex.org', '/works', queryParameters);

    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'OpenAlex request failed with status code ${response.statusCode}',
      );
    }

    final Map<String, dynamic> body = jsonDecode(response.body);
    final List<dynamic> results = body['results'] as List<dynamic>? ?? [];
    final int totalResult = body['meta']['count'] ?? 0;

    return (
      totalResult,
      results
          .map((item) => Publication.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<(int total, List<Publication> publications)> searchWithFilter(
    Map<String, String> params,
  ) async {
    final uri = Uri.https('api.openalex.org', '/works', {
      ...params,
      'mailto': mailto,
    });
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'OpenAlex request failed with status code ${response.statusCode}',
      );
    }

    final Map<String, dynamic> body = jsonDecode(response.body);
    final results = body['results'] as List<dynamic>? ?? [];
    final int totalResult = body['meta']['count'] ?? 0;

    return (
      totalResult,
      results
          .map((item) => Publication.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<List<String>> getTopicIdsFromKeyword(String keyword) async {
    final uri = Uri.https('api.openalex.org', '/topics', {
      'search': keyword,
      'per-page': '3',
      'mailto': mailto,
    });

    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      return [];
    }

    final body = jsonDecode(response.body);
    final topics = body['results'] as List? ?? [];

    if (topics.isEmpty) {
      return [];
    }

    final exactMatch = topics.cast<Map<String, dynamic>?>().firstWhere(
      (topic) =>
          topic?['display_name']?.toString().toLowerCase() ==
          keyword.toLowerCase(),
      orElse: () => null,
    );

    if (exactMatch != null) {
      return [exactMatch['id'].toString().split('/').last];
    }

    return topics
        .take(3)
        .map<String>((topic) => topic['id'].toString().split('/').last)
        .toList();
  }

  //Get detail by Work Id
  Future<Publication?> fetchDetail(String workId) async {
    try {
      final id = _normalizeId(workId);
      final uri = Uri.https('api.openalex.org', '/works/$id', {
        'mailto': mailto,
      });
      final res = await _client.get(uri);
      if (res.statusCode != 200) {
        throw Exception(
          'OpenAlex request failed with status code ${res.statusCode}',
        );
      }
      return Publication.fromJson(jsonDecode(res.body));
    } catch (_) {
      return null;
    }
  }

  static const _briefSelect =
      'id,doi,display_name,publication_year,cited_by_count,'
      'primary_location,best_oa_location,open_access,'
      'authorships,related_works,referenced_works';
  // Get Work by Mutiple Id
  Future<List<Publication>> fetchByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    try {
      final batch = ids.take(10).map(_normalizeId).join('|');
      final uri = Uri.https('api.openalex.org', '/works', {
        'filter': 'ids.openalex:$batch',
        'select': _briefSelect,
        'per-page': '20',
        'mailto': mailto,
      });
      final res = await _client.get(uri);
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body);
      return (data['results'] as List)
          .map((j) => Publication.fromJsonBrief(j))
          .toList();
    } catch (_) {
      return [];
    }
  }

  //Get Work cited Current work
  Future<List<Publication>> fetchCitedBy(String workId, {int page = 1}) async {
    try {
      final id = _normalizeId(workId);
      final uri = Uri.https('api.openalex.org', '/works', {
        'filter': 'cites:$id',
        'select': _briefSelect,
        'sort': 'cited_by_count:desc',
        'per-page': '20',
        'page': '$page',
        'mailto': mailto,
      });
      final res = await _client.get(uri);
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body);
      return (data['results'] as List)
          .map((j) => Publication.fromJsonBrief(j))
          .toList();
    } catch (_) {
      return [];
    }
  }

  String _normalizeId(String id) {
    return id.replaceAll('https://openalex.org/', '');
  }

  Future<List<Publication>> fetchInfluentialPapers({
    required String keyword,
    int? limit,
    String? topicId,
    int? fromYear,
    int? toYear,
  }) async {
    final queryParams = {
      if (topicId == null || topicId.trim().isEmpty) 'search': keyword,
      if (topicId != null && topicId.trim().isNotEmpty)
        'filter': _topicAnalyticsFilter(topicId, fromYear, toYear),
      'sort': 'cited_by_count:desc',
      'per-page': limit == null ? '200' : limit.toString(),
      'mailto': mailto,
    };

    final uri = Uri.https('api.openalex.org', '/works', queryParams);
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load influential papers');
    }

    final Map<String, dynamic> body = jsonDecode(response.body);
    final List<dynamic> results = body['results'] as List<dynamic>? ?? [];

    return results
        .map((item) => Publication.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, int>> fetchTopResearchJournals({
    required String keyword,
    int? limit,
    String? topicId,
    int? fromYear,
    int? toYear,
  }) async {
    final queryParams = {
      if (topicId == null || topicId.trim().isEmpty) 'search': keyword,
      if (topicId != null && topicId.trim().isNotEmpty)
        'filter': _topicAnalyticsFilter(topicId, fromYear, toYear),
      'group_by': 'primary_location.source.id',
      'per-page': (limit ?? 20).clamp(1, 20).toString(),
      'mailto': mailto,
    };

    final uri = Uri.https('api.openalex.org', '/works', queryParams);
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load top research journals');
    }

    final Map<String, dynamic> body = jsonDecode(response.body);
    return _parseGroupBy(
      body,
    ).ifEmpty(() => _parseJournalResults(body, limit: limit));
  }

  /// Like [fetchTopResearchJournals], but also keeps each journal's OpenAlex
  /// source id so callers can look up full journal metadata afterwards.
  Future<List<JournalTopicRank>> fetchTopResearchJournalRanks({
    required String keyword,
    int? limit,
    String? topicId,
    int? fromYear,
    int? toYear,
  }) async {
    final queryParams = {
      if (topicId == null || topicId.trim().isEmpty) 'search': keyword,
      if (topicId != null && topicId.trim().isNotEmpty)
        'filter': _topicAnalyticsFilter(topicId, fromYear, toYear),
      'group_by': 'primary_location.source.id',
      'per-page': (limit ?? 20).clamp(1, 20).toString(),
      'mailto': mailto,
    };

    final uri = Uri.https('api.openalex.org', '/works', queryParams);
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load top research journals');
    }

    final Map<String, dynamic> body = jsonDecode(response.body);
    final ranks = _parseGroupByJournalRanks(body);
    return ranks.isNotEmpty
        ? ranks
        : _parseJournalResultRanks(body, limit: limit);
  }

  Future<Map<String, int>> fetchTopContributingAuthors({
    required String keyword,
    int? limit,
    String? topicId,
    int? fromYear,
    int? toYear,
  }) async {
    final queryParams = {
      if (topicId == null || topicId.trim().isEmpty) 'search': keyword,
      if (topicId != null && topicId.trim().isNotEmpty)
        'filter': _topicAnalyticsFilter(topicId, fromYear, toYear),
      'group_by': 'authorships.author.id',
      'per-page': (limit ?? 20).clamp(1, 20).toString(),
      'mailto': mailto,
    };

    final uri = Uri.https('api.openalex.org', '/works', queryParams);
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load top contributing authors');
    }

    final Map<String, dynamic> body = jsonDecode(response.body);
    return _parseGroupBy(
      body,
    ).ifEmpty(() => _parseAuthorResults(body, limit: limit));
  }

  Future<Map<int, int>> fetchPublicationTrend({
    required String keyword,
    int fromYear = 2014,
    int? toYear,
    String? topicId,
  }) async {
    final trimmedKeyword = keyword.trim();

    if (trimmedKeyword.isEmpty) {
      return {};
    }

    final endYear = toYear ?? DateTime.now().year;

    final queryParams = {
      if (topicId == null || topicId.trim().isEmpty) 'search': trimmedKeyword,
      'filter': topicId == null || topicId.trim().isEmpty
          ? 'from_publication_date:$fromYear-01-01,to_publication_date:$endYear-12-31'
          : _topicAnalyticsFilter(topicId, fromYear, endYear),
      'group_by': 'publication_year',
      'mailto': mailto,
    };

    final uri = Uri.https('api.openalex.org', '/works', queryParams);
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'OpenAlex trend request failed with status code ${response.statusCode}',
      );
    }

    final Map<String, dynamic> body = jsonDecode(response.body);
    final List<dynamic> groups = body['group_by'] as List<dynamic>? ?? [];

    final Map<int, int> trend = {};

    for (final item in groups) {
      final group = item as Map<String, dynamic>;

      final year = int.tryParse(group['key']?.toString() ?? '');
      final count = group['count'] as int? ?? 0;

      if (year != null) {
        trend[year] = count;
      }
    }

    // Fill missing years with 0 so chart x-axis is continuous.
    final Map<int, int> completedTrend = {};
    for (int year = fromYear; year <= endYear; year++) {
      completedTrend[year] = trend[year] ?? 0;
    }

    return completedTrend;
  }

  String _topicAnalyticsFilter(String topicId, int? fromYear, int? toYear) {
    final filters = <String>[
      'primary_topic.id:${_normalizeId(topicId)}',
      if (fromYear != null) 'from_publication_date:$fromYear-01-01',
      if (toYear != null) 'to_publication_date:$toYear-12-31',
    ];
    return filters.join(',');
  }

  Map<String, int> _parseGroupBy(Map<String, dynamic> body) {
    final groups = body['group_by'] as List<dynamic>? ?? const [];
    return Map.fromEntries(
      groups.whereType<Map<String, dynamic>>().map(
        (group) => MapEntry(
          group['key_display_name']?.toString() ??
              group['key']?.toString() ??
              'Unknown',
          (group['count'] as num? ?? 0).toInt(),
        ),
      ),
    );
  }

  Map<String, int> _parseJournalResults(
    Map<String, dynamic> body, {
    int? limit,
  }) {
    final counts = <String, int>{};
    for (final item in body['results'] as List<dynamic>? ?? const []) {
      final work = item as Map<String, dynamic>;
      final location = work['primary_location'] as Map<String, dynamic>?;
      final source = location?['source'] as Map<String, dynamic>?;
      final name = source?['display_name']?.toString().trim();
      final journal = name == null || name.isEmpty ? 'Unknown Journal' : name;
      counts[journal] = (counts[journal] ?? 0) + 1;
    }
    return _sortAndLimit(counts, limit);
  }

  List<JournalTopicRank> _parseGroupByJournalRanks(Map<String, dynamic> body) {
    final groups = body['group_by'] as List<dynamic>? ?? const [];
    return groups.whereType<Map<String, dynamic>>().map((group) {
      final key = group['key']?.toString() ?? '';
      final name = group['key_display_name']?.toString().trim();
      return JournalTopicRank(
        sourceId: _normalizeId(key),
        displayName: (name == null || name.isEmpty) ? 'Unknown Journal' : name,
        count: (group['count'] as num? ?? 0).toInt(),
      );
    }).toList();
  }

  List<JournalTopicRank> _parseJournalResultRanks(
    Map<String, dynamic> body, {
    int? limit,
  }) {
    final counts = <String, ({String sourceId, String name, int count})>{};

    for (final item in body['results'] as List<dynamic>? ?? const []) {
      final work = item as Map<String, dynamic>;
      final location = work['primary_location'] as Map<String, dynamic>?;
      final source = location?['source'] as Map<String, dynamic>?;
      final rawId = source?['id']?.toString();
      final sourceId = (rawId == null || rawId.isEmpty)
          ? ''
          : _normalizeId(rawId);
      final name = source?['display_name']?.toString().trim();
      final journalName = (name == null || name.isEmpty)
          ? 'Unknown Journal'
          : name;
      final key = sourceId.isNotEmpty ? sourceId : journalName;

      final existing = counts[key];
      counts[key] = (
        sourceId: sourceId,
        name: journalName,
        count: (existing?.count ?? 0) + 1,
      );
    }

    final ranks = counts.values
        .map(
          (r) => JournalTopicRank(
            sourceId: r.sourceId,
            displayName: r.name,
            count: r.count,
          ),
        )
        .toList()
      ..sort((a, b) {
        final byCount = b.count.compareTo(a.count);
        return byCount != 0 ? byCount : a.displayName.compareTo(b.displayName);
      });

    return ranks.take(limit ?? ranks.length).toList();
  }

  Map<String, int> _parseAuthorResults(
    Map<String, dynamic> body, {
    int? limit,
  }) {
    final counts = <String, int>{};
    for (final item in body['results'] as List<dynamic>? ?? const []) {
      final work = item as Map<String, dynamic>;
      for (final authorship
          in work['authorships'] as List<dynamic>? ?? const []) {
        final author =
            (authorship as Map<String, dynamic>)['author']
                as Map<String, dynamic>?;
        final name = author?['display_name']?.toString().trim();
        if (name == null || name.isEmpty) continue;
        counts[name] = (counts[name] ?? 0) + 1;
      }
    }
    return _sortAndLimit(counts, limit);
  }

  Map<String, int> _sortAndLimit(Map<String, int> counts, int? limit) {
    final entries = counts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount != 0 ? byCount : a.key.compareTo(b.key);
      });
    return Map.fromEntries(entries.take(limit ?? entries.length));
  }
}

extension _MapIfEmpty<K, V> on Map<K, V> {
  Map<K, V> ifEmpty(Map<K, V> Function() fallback) {
    return isEmpty ? fallback() : this;
  }
}
