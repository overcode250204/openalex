import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/journal/journal_publication.dart';
import '../models/journal/journal_source.dart';

class OpenAlexJournalService {
  static const String host = 'api.openalex.org';
  static const String mailto = 'truongtuan20042004@gmail.com';

  final http.Client _client;

  OpenAlexJournalService({http.Client? client})
    : _client = client ?? http.Client();

  Future<List<JournalSource>> searchJournals(String query) async {
    final trimmedQuery = query.trim();

    if (trimmedQuery.isEmpty) {
      return [];
    }

    final body = await _get('/sources', {
      'search': trimmedQuery,
      'filter': 'type:journal',
      'sort': 'works_count:desc',
      'per-page': '10',
      'mailto': mailto,
    });

    final results = body['results'] as List<dynamic>? ?? [];

    return results
        .whereType<Map<String, dynamic>>()
        .map(JournalSource.fromJson)
        .where((source) => source.type.toLowerCase() == 'journal')
        .toList();
  }

  Future<List<JournalPublication>> getJournalPublications(
    String sourceId, {
    int page = 1,
    int perPage = 20,
  }) async {
    final normalizedSourceId = _normalizeId(sourceId);

    if (normalizedSourceId.isEmpty) {
      return [];
    }

    final body = await _get('/works', {
      'filter': 'primary_location.source.id:$normalizedSourceId',
      'sort': 'publication_date:desc',
      'per-page': perPage.toString(),
      'page': page.toString(),
      'mailto': mailto,
    });

    final results = body['results'] as List<dynamic>? ?? [];

    return results
        .whereType<Map<String, dynamic>>()
        .map(JournalPublication.fromJson)
        .toList();
  }

  Future<JournalPublication?> getHighestCitedPublication(
    String sourceId,
  ) async {
    final normalizedSourceId = _normalizeId(sourceId);

    if (normalizedSourceId.isEmpty) {
      return null;
    }

    final body = await _get('/works', {
      'filter': 'primary_location.source.id:$normalizedSourceId',
      'sort': 'cited_by_count:desc',
      'per-page': '1',
      'mailto': mailto,
    });

    final results = body['results'] as List<dynamic>? ?? [];

    if (results.isEmpty || results.first is! Map<String, dynamic>) {
      return null;
    }

    return JournalPublication.fromJson(results.first as Map<String, dynamic>);
  }

  Future<JournalPublication?> getPublicationDetail(String workId) async {
    final normalizedWorkId = _normalizeId(workId);

    if (normalizedWorkId.isEmpty) {
      return null;
    }

    final body = await _get('/works/$normalizedWorkId', {'mailto': mailto});

    return JournalPublication.fromJson(body);
  }

  Future<Map<String, dynamic>> _get(
    String path,
    Map<String, String> queryParameters,
  ) async {
    final uri = Uri.https(host, path, queryParameters);
    final response = await _client.get(uri);
    print(uri);
    if (response.statusCode != 200) {
      throw Exception(
        'OpenAlex request failed with status code ${response.statusCode}',
      );
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  String _normalizeId(String id) {
    return id.trim().split('/').last;
  }
}
