import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/keyword/keyword_analysis_paper.dart';
import '../models/keyword/keyword_analysis_result.dart';
import '../models/keyword/keyword_trend_point.dart';

class OpenAlexKeywordService {
  static const String host = 'api.openalex.org';
  static const String mailto = 'truongtuan20042004@gmail.com';

  final http.Client _client;

  OpenAlexKeywordService({http.Client? client})
    : _client = client ?? http.Client();

  Future<List<KeywordTrendPoint>> fetchKeywordTrend(String keyword) async {
    final body = await _getWorks({
      'search': keyword.trim(),
      'group_by': 'publication_year',
      'mailto': mailto,
    });

    final groupBy = body['group_by'] as List<dynamic>? ?? [];
    return KeywordTrendPoint.parseGroupBy(groupBy);
  }

  Future<List<KeywordAnalysisPaper>> fetchMostCitedPapers(
    String keyword, {
    int perPage = 5,
  }) {
    return _fetchPapers(keyword, {
      'sort': 'cited_by_count:desc',
      'per-page': perPage.toString(),
    });
  }

  Future<List<KeywordAnalysisPaper>> fetchLatestPapers(
    String keyword, {
    int perPage = 5,
  }) {
    return _fetchPapers(keyword, {
      'sort': 'publication_date:desc',
      'per-page': perPage.toString(),
    });
  }

  Future<List<KeywordAnalysisPaper>> fetchOpenAccessPapers(
    String keyword, {
    int perPage = 5,
  }) {
    return _fetchPapers(keyword, {
      'filter': 'open_access.is_oa:true',
      'sort': 'cited_by_count:desc',
      'per-page': perPage.toString(),
    });
  }

  Future<KeywordAnalysisResult> analyzeKeyword(String keyword) async {
    final trimmedKeyword = keyword.trim();

    final results = await Future.wait([
      fetchKeywordTrend(trimmedKeyword),
      fetchMostCitedPapers(trimmedKeyword),
      fetchLatestPapers(trimmedKeyword),
      fetchOpenAccessPapers(trimmedKeyword),
    ]);

    return KeywordAnalysisResult(
      keyword: trimmedKeyword,
      trend: results[0] as List<KeywordTrendPoint>,
      mostCitedPapers: results[1] as List<KeywordAnalysisPaper>,
      latestPapers: results[2] as List<KeywordAnalysisPaper>,
      openAccessPapers: results[3] as List<KeywordAnalysisPaper>,
    );
  }

  Future<List<KeywordAnalysisPaper>> _fetchPapers(
    String keyword,
    Map<String, String> params,
  ) async {
    final body = await _getWorks({
      'search': keyword.trim(),
      ...params,
      'mailto': mailto,
    });

    final results = body['results'] as List<dynamic>? ?? [];
    return results
        .whereType<Map<String, dynamic>>()
        .map(KeywordAnalysisPaper.fromJson)
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
}
