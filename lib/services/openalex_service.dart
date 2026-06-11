import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/publication.dart';

class OpenAlexService {
  static const String _baseUrl = 'https://api.openalex.org';
  final http.Client _client;

  OpenAlexService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<Publication>> searchPublications({
    required String keyword,
    int perPage = 50,
    String sort = 'cited_by_count:desc',
    int? fromYear,
    int? toYear,
  }) async {
    final trimmedKeyword = keyword.trim();

    if (trimmedKeyword.isEmpty) {
      return [];
    }

    final Map<String, String> queryParameters = {
      'search': trimmedKeyword,
      'per-page': perPage.toString(),
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
    final List<dynamic> results = body['results'] as List<dynamic>? ?? [];

    return results
        .map((item) => Publication.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
