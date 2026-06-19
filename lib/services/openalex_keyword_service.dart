import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/keyword/keyword_analysis_paper.dart';
import '../models/keyword/keyword_analysis_result.dart';
import '../models/keyword/keyword_trend_point.dart';
import '../models/keyword/openalex_keyword.dart';

class KeywordNotFoundException implements Exception {
  final String message;
  KeywordNotFoundException(this.message);
  @override
  String toString() => message;
}

class OpenAlexKeywordService {
  static const String host = 'api.openalex.org';
  static const String mailto = 'truongtuan20042004@gmail.com';

  final http.Client _client;

  OpenAlexKeywordService({http.Client? client})
    : _client = client ?? http.Client();

  String _todayIsoDate() {
    final now = DateTime.now().toUtc();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _appendToPublicationDateFilter([String? existingFilter]) {
    final today = _todayIsoDate();
    if (existingFilter == null || existingFilter.trim().isEmpty) {
      return 'to_publication_date:$today';
    }
    return '$existingFilter,to_publication_date:$today';
  }

  Future<OpenAlexKeyword?> resolveKeyword(String keyword) async {
    final uri = Uri.https(host, '/keywords', {
      'search': keyword.trim(),
      'per-page': '1',
      'mailto': mailto,
    });

    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception(
        'OpenAlex request failed with status code ${response.statusCode}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final results = body['results'] as List<dynamic>? ?? [];

    if (results.isEmpty) {
      return null;
    }

    final firstResult = results.first as Map<String, dynamic>;
    return OpenAlexKeyword.fromJson(firstResult);
  }

  Future<List<KeywordTrendPoint>> fetchKeywordTrendByKeywordId(
    String keywordId,
  ) async {
    final body = await _getWorks({
      'filter': _appendToPublicationDateFilter('keywords.id:$keywordId'),
      'group_by': 'publication_year',
      'mailto': mailto,
    });

    final groupBy = body['group_by'] as List<dynamic>? ?? [];
    return KeywordTrendPoint.parseGroupBy(groupBy);
  }

  Future<List<KeywordAnalysisPaper>> fetchRelevantPapersByKeywordId(
    String keywordId, {
    int perPage = 25,
    int limit = 5,
  }) async {
    final papers = await _fetchPapers({
      'filter': _appendToPublicationDateFilter('keywords.id:$keywordId'),
      'per-page': perPage.toString(),
    }, matchedKeywordId: keywordId);

    final relevantPapers = papers
        .where((paper) => paper.keywordScore > 0)
        .toList();

    relevantPapers.sort((a, b) {
      final scoreCompare = b.keywordScore.compareTo(a.keywordScore);
      if (scoreCompare != 0) return scoreCompare;
      return b.citedByCount.compareTo(a.citedByCount);
    });

    return relevantPapers.take(limit).toList();
  }

  Future<List<KeywordAnalysisPaper>> fetchMostCitedPapersByKeywordId(
    String keywordId, {
    int perPage = 5,
  }) {
    return _fetchPapers({
      'filter': _appendToPublicationDateFilter('keywords.id:$keywordId'),
      'sort': 'cited_by_count:desc',
      'per-page': perPage.toString(),
    }, matchedKeywordId: keywordId);
  }

  Future<List<KeywordAnalysisPaper>> fetchLatestPapersByKeywordId(
    String keywordId, {
    int perPage = 5,
  }) {
    return _fetchPapers({
      'filter': _appendToPublicationDateFilter('keywords.id:$keywordId'),
      'sort': 'publication_date:desc',
      'per-page': perPage.toString(),
    }, matchedKeywordId: keywordId);
  }

  Future<List<KeywordAnalysisPaper>> fetchOpenAccessPapersByKeywordId(
    String keywordId, {
    int perPage = 5,
  }) {
    return _fetchPapers({
      'filter': _appendToPublicationDateFilter(
        'keywords.id:$keywordId,open_access.is_oa:true',
      ),
      'sort': 'cited_by_count:desc',
      'per-page': perPage.toString(),
    }, matchedKeywordId: keywordId);
  }

  Future<Map<String, int>> fetchTopAuthorsByKeywordId(
    String keywordId, {
    int perPage = 10,
  }) => _fetchGroupBy(
    filter: _appendToPublicationDateFilter('keywords.id:$keywordId'),
    groupBy: 'authorships.author.id',
    perPage: perPage,
  );

  Future<Map<String, int>> fetchTopJournalsByKeywordId(
    String keywordId, {
    int perPage = 10,
  }) => _fetchGroupBy(
    filter: _appendToPublicationDateFilter('keywords.id:$keywordId'),
    groupBy: 'primary_location.source.id',
    perPage: perPage,
  );

  Future<Map<String, int>> _fetchGroupBy({
    required String filter,
    required String groupBy,
    int perPage = 10,
  }) async {
    final body = await _getWorks({
      'filter': filter,
      'group_by': groupBy,
      'per-page': perPage.toString(),
      'mailto': mailto,
    });
    final groups = body['group_by'] as List<dynamic>? ?? [];
    final result = <String, int>{};
    for (final item in groups) {
      if (item is! Map<String, dynamic>) continue;
      final name = item['key_display_name']?.toString();
      final count = item['count'] as int? ?? 0;
      if (name != null && name.isNotEmpty) result[name] = count;
    }
    return result;
  }

  Future<KeywordAnalysisResult> analyzeKeyword(
    String keyword, {
    int fromYear = 2011,
    int? toYear,
  }) async {
    final trimmedKeyword = keyword.trim();

    final resolvedKeyword = await resolveKeyword(trimmedKeyword);

    if (resolvedKeyword == null || resolvedKeyword.id.isEmpty) {
      throw KeywordNotFoundException('No matching OpenAlex keyword found.');
    }

    final keywordId = resolvedKeyword.id;

    final results = await Future.wait([
      fetchKeywordTrend(
        keyword: trimmedKeyword,
        fromYear: fromYear,
        toYear: toYear,
      ),
      fetchRelevantPapersByKeywordId(keywordId),
      fetchMostCitedPapersByKeywordId(keywordId),
      fetchLatestPapersByKeywordId(keywordId),
      fetchOpenAccessPapersByKeywordId(keywordId),
      fetchTopAuthorsByKeywordId(keywordId, perPage: 20),
      fetchTopJournalsByKeywordId(keywordId, perPage: 20),
    ]);

    return KeywordAnalysisResult(
      keyword: trimmedKeyword,
      resolvedKeyword: resolvedKeyword,
      trend: results[0] as List<KeywordTrendPoint>,
      relevantPapers: results[1] as List<KeywordAnalysisPaper>,
      mostCitedPapers: results[2] as List<KeywordAnalysisPaper>,
      latestPapers: results[3] as List<KeywordAnalysisPaper>,
      openAccessPapers: results[4] as List<KeywordAnalysisPaper>,
      topAuthors: results[5] as Map<String, int>,
      topSources: results[6] as Map<String, int>,
    );
  }

  Future<List<KeywordAnalysisPaper>> _fetchPapers(
    Map<String, String> params, {
    String? matchedKeywordId,
  }) async {
    final body = await _getWorks({...params, 'mailto': mailto});

    final results = body['results'] as List<dynamic>? ?? [];
    return results
        .whereType<Map<String, dynamic>>()
        .map(
          (json) => KeywordAnalysisPaper.fromOpenAlexJson(
            json,
            matchedKeywordId: matchedKeywordId,
          ),
        )
        .where((paper) => !paper.isFutureDated)
        .toList();
  }

  Future<Map<String, dynamic>> _getWorks(Map<String, String> params) async {
    final uri = Uri.https(host, '/works', params);
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'OpenAlex request failed with status code ${response.statusCode}',
      );
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<KeywordTrendPoint>> fetchKeywordTrend({
    required String keyword,
    int fromYear = 2011,
    int? toYear,
  }) async {
    final trimmedKeyword = keyword.trim();

    if (trimmedKeyword.isEmpty) {
      return [];
    }

    final endYear = toYear ?? DateTime.now().year;

    final uri = Uri.https(host, '/works', {
      'search': trimmedKeyword,
      'filter': 'publication_year:$fromYear-$endYear',
      'group_by': 'publication_year',
      'mailto': mailto,
    });

    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'OpenAlex keyword trend request failed with status code ${response.statusCode}',
      );
    }

    final Map<String, dynamic> body =
        jsonDecode(response.body) as Map<String, dynamic>;

    final List<dynamic> groups = body['group_by'] as List<dynamic>? ?? [];

    final Map<int, int> trendMap = {};

    for (final item in groups) {
      final group = item as Map<String, dynamic>;

      final year = int.tryParse(group['key']?.toString() ?? '');
      final count = group['count'] as int? ?? 0;

      if (year != null) {
        trendMap[year] = count;
      }
    }

    final List<KeywordTrendPoint> completedTrend = [];

    for (int year = fromYear; year <= endYear; year++) {
      completedTrend.add(
        KeywordTrendPoint(
          year: year,
          count: trendMap[year] ?? 0,
        ),
      );
    }

    return completedTrend;
  }
}
