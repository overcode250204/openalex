import 'dart:convert';

import 'package:http/http.dart' as http;

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
    return _parseGroupBy(body);
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
    return _parseGroupBy(body);
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
      'topics.id:${_normalizeId(topicId)}',
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
}
