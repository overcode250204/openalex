import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/publication.dart';

class OpenAlexService {
  static const String _baseUrl = 'https://api.openalex.org';
  final http.Client _client;

  OpenAlexService({http.Client? client}) : _client = client ?? http.Client();

  Future<(int total, List<Publication> publications)> searchPublications({
    required String keyword,
    int perPage = 50,
    int page = 1,
    String sort = 'cited_by_count:desc',
    int? fromYear,
    int? toYear,
  }) async {
    final trimmedKeyword = keyword.trim();

    if (trimmedKeyword.isEmpty) {
      return (0, <Publication>[]);
    }

    final Map<String, String> queryParameters = {
      'search': trimmedKeyword,
      'per-page': perPage.toString(),
      'page': page.toString(),
      'sort': sort,
    };

    if (fromYear != null || toYear != null) {
      final filters = <String>[];

      if (fromYear != null) {
        filters.add('from_publication_date:$fromYear-01-01');
      }

      if (toYear != null) {
        filters.add('to_publication_date:$toYear-12-31');
      }

      queryParameters['filter'] = filters.join(',');
    }

    final uri = Uri.parse(
      '$_baseUrl/works',
    ).replace(queryParameters: queryParameters);

    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'OpenAlex request failed with status code ${response.statusCode}',
      );
    }

    final Map<String, dynamic> body = jsonDecode(response.body);
    final int total = (body['meta']?['count'] as num? ?? 0).toInt();
    final List<dynamic> results = body['results'] as List<dynamic>? ?? [];

    return (total, results
        .map((item) => Publication.fromJson(item as Map<String, dynamic>))
        .toList());
  }

  Future<(int total, List<Publication> publications)> searchWithFilter(Map<String,String> params) async {
 
    final uri = Uri.https('api.openalex.org', '/works', params);
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'OpenAlex request failed with status code ${response.statusCode}',
      );
    }

    final Map<String, dynamic> body = jsonDecode(response.body);
    final results = body['results'] as List<dynamic>? ?? [];
    final int totalResult = body['meta']['count'] ?? 0;
    
    return (totalResult, results
        .map((item) => Publication.fromJson(item as Map<String, dynamic>))
        .toList());
  }
}
