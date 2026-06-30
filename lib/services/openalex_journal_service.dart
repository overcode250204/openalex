import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/journal/journal_source.dart';
import '../models/publication/publication.dart';

class OpenAlexJournalService {
  static const String _mailto = 'trandinhbao222@gmail.com';

  final http.Client _client;

  OpenAlexJournalService({http.Client? client})
    : _client = client ?? http.Client();

  Future<List<JournalSource>> fetchTopJournals({int perPage = 20}) async {
    final uri = Uri.https('api.openalex.org', '/sources', {
      'filter': 'type:journal',
      'sort': 'cited_by_count:desc',
      'per-page': perPage.toString(),
      'mailto': _mailto,
    });
    return _fetch(uri);
  }

  Future<List<JournalSource>> searchJournals(
    String query, {
    int perPage = 20,
  }) async {
    final uri = Uri.https('api.openalex.org', '/sources', {
      'search': query.trim(),
      'filter': 'type:journal',
      'sort': 'cited_by_count:desc',
      'per-page': perPage.toString(),
      'mailto': _mailto,
    });
    return _fetch(uri);
  }

  Future<List<Publication>> fetchPublicationsForJournal(
    String journalId, {
    int perPage = 10,
    int page = 1,
  }) async {
    final id = journalId.replaceAll('https://openalex.org/', '');
    final uri = Uri.https('api.openalex.org', '/works', {
      'filter': 'primary_location.source.id:$id',
      'sort': 'cited_by_count:desc',
      'per-page': perPage.toString(),
      'page': page.toString(),
      'mailto': _mailto,
    });
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load publications for journal: ${response.statusCode}',
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final results = body['results'] as List<dynamic>? ?? [];
    return results
        .map((item) => Publication.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<JournalSource>> _fetch(Uri uri) async {
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception(
        'OpenAlex sources request failed with status ${response.statusCode}',
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final results = body['results'] as List<dynamic>? ?? [];
    return results
        .map((item) => JournalSource.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
